#!/usr/bin/env bash
# LR3 Stream — orchestruje Icecast + jeden Liquidsoap zdroj (Spotify + fallback)
# na každou zónu. Tento skript je PID 1 kontejneru addonu.
set -uo pipefail

OPTIONS=/data/options.json
TPL_DIR=/etc/lr3

log() { echo "[LR3] $*"; }

PORT=$(jq -r '.port // 8000' "$OPTIONS")
SRCPASS=$(jq -r '.source_password // "changeme"' "$OPTIONS")
FALLBACK_URL=$(jq -r '.fallback_url // "http://ice.actve.net/fm-evropa2-128"' "$OPTIONS")
FALLBACK_DELAY=$(jq -r '.fallback_delay // 15' "$OPTIONS")
FALLBACK_ENABLED=$(jq -r '.fallback_enabled // true' "$OPTIONS")
BITRATE=$(jq -r '.bitrate // 192' "$OPTIONS")
SPOTIFY_BITRATE=$(jq -r '.spotify_bitrate // 320' "$OPTIONS")

# Zjisti LAN IP hostitele (host_network: true → kontejner ji sdílí).
HA_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
[ -z "$HA_IP" ] && HA_IP="<HA_IP>"

# Hostname pro Icecast (potlačí warning o "localhost"); fallback když IP neznáme.
ICE_HOSTNAME="$HA_IP"
[ "$ICE_HOSTNAME" = "<HA_IP>" ] && ICE_HOSTNAME="localhost"

log "Startuji LR3 Stream (port=${PORT}, bitrate=${BITRATE}k, spotify=${SPOTIFY_BITRATE}k)"
if [ "${FALLBACK_ENABLED}" = "true" ]; then
  log "Fallback rádio: ${FALLBACK_URL} (prodleva ${FALLBACK_DELAY}s)"
else
  log "Fallback rádio: VYPNUTO — po ${FALLBACK_DELAY}s nečinnosti zůstane ticho"
fi

# --- D-Bus + Avahi (librespot z raspotify používá avahi zeroconf backend) ---
log "Spouštím D-Bus + Avahi (pro Spotify Connect discovery)..."
mkdir -p /run/dbus /run/avahi-daemon
rm -f /run/dbus/pid
dbus-uuidgen --ensure 2>/dev/null || true
if dbus-daemon --system --fork; then log "D-Bus běží"; else log "VAROVÁNÍ: D-Bus se nespustil"; fi
sleep 1
if avahi-daemon --no-chroot --no-drop-root --no-rlimits --daemonize; then
  log "Avahi běží"
else
  log "VAROVÁNÍ: Avahi se nespustil — Spotify discovery nemusí fungovat"
fi

# --- Vygeneruj Icecast konfiguraci ze šablony ---
sed -e "s|%%PORT%%|${PORT}|g" \
    -e "s|%%SOURCE_PASSWORD%%|${SRCPASS}|g" \
    -e "s|%%HOSTNAME%%|${ICE_HOSTNAME}|g" \
    "${TPL_DIR}/icecast.xml.tpl" > /etc/icecast.xml

mkdir -p /var/log/icecast2
chown -R icecast2:icecast /var/log/icecast2 2>/dev/null || true

# --- Spusť Icecast ---
log "Spouštím Icecast..."
icecast2 -c /etc/icecast.xml &
ICECAST_PID=$!

# Počkej, až Icecast začne přijímat spojení
for _ in $(seq 1 30); do
  nc -z localhost "${PORT}" 2>/dev/null && break
  sleep 0.5
done
if nc -z localhost "${PORT}" 2>/dev/null; then
  log "Icecast běží na :${PORT}"
else
  log "VAROVÁNÍ: Icecast zatím není dostupný na :${PORT} — pokračuji"
fi

# --- Spotify play/stop události → stavové soubory per mount (pro LARA controller) ---
mkdir -p /etc/lr3
cat > /etc/lr3/spotify_event.sh <<'EOF'
#!/usr/bin/env sh
printf '%s' "${PLAYER_EVENT:-}" > "/tmp/spotify_state_${LR3_MOUNT:-unknown}"
EOF
chmod +x /etc/lr3/spotify_event.sh

# --- Spusť jeden Liquidsoap na každý stream ---
declare -a LIQ_PIDS=()
declare -a ZONE_URLS=()

# Vytvoří a spustí jeden stream (zónu).
start_zone() {
  local ZNAME="$1" ZMOUNT="$2" KIND="$3"
  local LIQ="/tmp/zone_${ZMOUNT}.liq"
  : > "/tmp/librespot_${ZMOUNT}.log"
  mkdir -p "/data/librespot_${ZMOUNT}"

  sed -e "s|%%PORT%%|${PORT}|g" \
      -e "s|%%SOURCE_PASSWORD%%|${SRCPASS}|g" \
      -e "s|%%BITRATE%%|${BITRATE}|g" \
      -e "s|%%SPOTIFY_BITRATE%%|${SPOTIFY_BITRATE}|g" \
      -e "s|%%FALLBACK_URL%%|${FALLBACK_URL}|g" \
      -e "s|%%FALLBACK_DELAY%%|${FALLBACK_DELAY}|g" \
      -e "s|%%FALLBACK_ENABLED%%|${FALLBACK_ENABLED}|g" \
      -e "s|%%MOUNT%%|${ZMOUNT}|g" \
      -e "s|%%ZONE_NAME%%|${ZNAME}|g" \
      "${TPL_DIR}/radio.liq.tpl" > "${LIQ}"

  log "[${KIND}] '${ZNAME}'  ->  Spotify zařízení '${ZNAME}'  |  http://${HA_IP}:${PORT}/${ZMOUNT}"
  liquidsoap "${LIQ}" &
  LIQ_PIDS+=("$!")
  ZONE_URLS+=("${ZNAME}|http://${HA_IP}:${PORT}/${ZMOUNT}")
}

# Výchozí sdílený stream — vytváří se VŽDY automaticky a nejde smazat.
# Je to ten, na který jsou naladěná všechna rádia (multi-room).
start_zone "Default" "default" "auto"

# TODO Fáze 2: po auto-discovery zde přibude jeden automatický stream na každé
# nalezené LARA rádio, pojmenovaný podle názvu toho rádia.

# Ručně přidané streamy z konfigurace (jen ty smí uživatel spravovat/mazat).
ZONE_COUNT=$(jq '.zones | length' "$OPTIONS")
log "Ručně přidané streamy: ${ZONE_COUNT}"
if [ "${ZONE_COUNT}" -gt 0 ]; then
  for i in $(seq 0 $((ZONE_COUNT - 1))); do
    ZNAME=$(jq -r ".zones[$i].name // \"Zone $i\"" "$OPTIONS")
    ZMOUNT=$(jq -r ".zones[$i].mount // \"zone$i\"" "$OPTIONS")
    if [ "${ZMOUNT}" = "default" ]; then
      log "VAROVÁNÍ: ruční stream s mountem 'default' přeskočen — je rezervovaný."
      continue
    fi
    start_zone "${ZNAME}" "${ZMOUNT}" "ruční"
  done
fi

# Vypisuj librespot stderr do logu addonu (kvůli diagnostice).
tail -qF /tmp/librespot_*.log 2>/dev/null | sed -u 's/^/[librespot] /' &

# --- Přehledný, copy-paste banner s adresami streamů ---
echo "=================================================================="
echo "  LR3 Stream — streamy jsou dostupné na těchto adresách:"
echo "------------------------------------------------------------------"
for entry in "${ZONE_URLS[@]}"; do
  printf "  %-16s %s\n" "${entry%%|*}" "${entry#*|}"
done
echo "------------------------------------------------------------------"
echo "  Spotify: vyber v appce zařízení podle názvu zóny (Premium, stejná síť)."
echo "=================================================================="

# --- LARA controller (discovery + přepínání rádií). Bezpečný i bez LARA. ---
CTRL_PID=""
if command -v python3 >/dev/null 2>&1; then
  CMODE=$(jq -r '.control_mode // "off"' "$OPTIONS")
  log "Spouštím LARA controller (režim: ${CMODE})..."
  python3 /opt/lr3ctl/controller.py &
  CTRL_PID=$!
else
  log "python3 chybí — LARA controller přeskočen."
fi

# --- Čisté ukončení ---
terminate() {
  log "Zastavuji..."
  [ -n "${CTRL_PID}" ] && kill "${CTRL_PID}" 2>/dev/null
  [ "${#LIQ_PIDS[@]}" -gt 0 ] && kill "${LIQ_PIDS[@]}" 2>/dev/null
  kill "${ICECAST_PID}" 2>/dev/null
  wait 2>/dev/null
  exit 0
}
trap terminate SIGTERM SIGINT

# Drž PID 1 naživu, dokud běží potomci.
wait
