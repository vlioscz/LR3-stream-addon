# LR3 Stream — zóna "%%ZONE_NAME%%"  ->  mount /%%MOUNT%%
# Priorita: Spotify Connect > (po prodlevě) online rádio > ticho. Mount NIKDY nespadne.

settings.log.stdout.set(true)
settings.log.level.set(3)
# Kontejner addonu běží jako root; Liquidsoap by se jinak z bezpečnosti ukončil.
settings.init.allow_root.set(true)

# --- Spotify Connect přes librespot ---
# librespot se přes zeroconf objeví na LAN jako Spotify zařízení "%%ZONE_NAME%%"
# a posílá raw S16 PCM na stdout. Liquidsoap ho čte a při pádu restartuje.
spotify_raw = input.external.rawaudio(
  id="spotify_%%MOUNT%%",
  restart=true, restart_on_error=true,
  'librespot --name "%%ZONE_NAME%%" --device-type speaker --backend pipe --format S16 --bitrate %%SPOTIFY_BITRATE%% --initial-volume 100 --disable-audio-cache --enable-volume-normalisation'
)
# Když Spotify nehraje (ticho déle než prodleva), zdroj se stane nedostupným
# a převezme fallback. Jakmile zvuk naskočí, Spotify má zase přednost.
spotify = blank.strip(id="spotify_live_%%MOUNT%%", max_blank=%%FALLBACK_DELAY%%., threshold=-40., spotify_raw)

# --- Záložní online rádio (např. Evropa 2), reconnectuje se samo ---
radio = input.http(id="fallback_%%MOUNT%%", "%%FALLBACK_URL%%")

# --- Poslední záchrana: nekonečné ticho, aby byl mount vždy krmený ---
silent = blank(id="silence_%%MOUNT%%", duration=-1.)

# Priorita. track_sensitive=false → přepne v okamžiku, kdy zdroj (ne)naskočí.
main = fallback(id="main_%%MOUNT%%", track_sensitive=false, [spotify, radio, silent])

# Jeden trvalý enkodér + výstup do Icecastu. `main` je infallible (ticho vždy),
# takže výstup zůstane připojený napořád.
output.icecast(
  %mp3(bitrate=%%BITRATE%%),
  id="out_%%MOUNT%%",
  host="localhost",
  port=%%PORT%%,
  password="%%SOURCE_PASSWORD%%",
  mount="/%%MOUNT%%",
  name="%%ZONE_NAME%%",
  description="LR3 Stream",
  genre="Various",
  fallible=false,
  main
)
