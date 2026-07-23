# LR3 Stream — zóna "%%ZONE_NAME%%"  ->  mount /%%MOUNT%%
# Fáze 1: online-rádio fallback + ticho. Mount NIKDY nespadne.

settings.log.stdout.set(true)
settings.log.level.set(3)
# Kontejner addonu běží jako root; Liquidsoap by se jinak z bezpečnosti ukončil.
settings.init.allow_root.set(true)

# Záložní online rádio (např. Evropa 2). Reconnectuje se samo.
radio = input.http(id="fallback_%%MOUNT%%", "%%FALLBACK_URL%%")

# Poslední záchrana: nekonečné ticho, aby byl Icecast mount vždy krmený
# a spojení se nikdy nezavřelo (= rádia se neodpojí).
silent = blank(id="silence_%%MOUNT%%", duration=-1.)

# Priorita. track_sensitive=false → přepne v okamžiku, kdy zdroj (ne)naskočí,
# bez čekání na konec skladby.
# Fáze 1b sem předřadí Spotify (librespot) jako nejvyšší prioritu.
main = fallback(id="main_%%MOUNT%%", track_sensitive=false, [radio, silent])

# Jeden trvalý enkodér + výstup do Icecastu. Protože je `main` infallible
# (ticho je vždy k dispozici), tenhle výstup zůstane připojený napořád.
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
