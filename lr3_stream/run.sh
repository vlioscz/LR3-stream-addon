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

# --- Spusť jeden Liquidsoap na každou nakonfigurovanou zónu ---
declare -a LIQ_PIDS=()
declare -a ZONE_URLS=()
ZONE_COUNT=$(jq '.zones | length' "$OPTIONS")
log "Nakonfigurované zóny: ${ZONE_COUNT}"

if [ "${ZONE_COUNT}" -gt 0 ]; then
  for i in $(seq 0 $((ZONE_COUNT - 1))); do
    ZNAME=$(jq -r ".zones[$i].name // \"Zone $i\"" "$OPTIONS")
    ZMOUNT=$(jq -r ".zones[$i].mount // \"zone$i\"" "$OPTIONS")
    LIQ="/tmp/zone_${ZMOUNT}.liq"
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

    log "Zóna '${ZNAME}'  ->  Spotify zařízení '${ZNAME}'  |  http://${HA_IP}:${PORT}/${ZMOUNT}"
    liquidsoap "${LIQ}" &
    LIQ_PIDS+=("$!")
    ZONE_URLS+=("${ZNAME}|http://${HA_IP}:${PORT}/${ZMOUNT}")
  done
else
  log "CHYBA: žádná zóna není nakonfigurovaná — není co streamovat."
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

# --- Čisté ukončení ---
terminate() {
  log "Zastavuji..."
  [ "${#LIQ_PIDS[@]}" -gt 0 ] && kill "${LIQ_PIDS[@]}" 2>/dev/null
  kill "${ICECAST_PID}" 2>/dev/null
  wait 2>/dev/null
  exit 0
}
trap terminate SIGTERM SIGINT

# Drž PID 1 naživu, dokud běží potomci.
wait
