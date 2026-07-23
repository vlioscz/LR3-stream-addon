# LR3 Stream

Stabilní lokální rozhlasový stream (Icecast + Liquidsoap), který **nikdy nevypadne**. Zvuk posílá **Spotify Connect** (librespot); když nic nehraje, drží se živý a po prodlevě naskočí záloha (např. Evropa 2). Rádia LARA i jakýkoli jiný přehrávač se připojí a nic je neodpojí.

## Rychlý start

1. **Configuration** → nastav `port` a `zones` → **Start**.
2. V Spotify appce (stejná síť, **Premium**) vyber zařízení pojmenované podle zóny → hraje do streamu.
3. **Log** → addon vypíše přesné adresy streamů. Zkopíruj do rádia / VLC.

## Volby

| Volba | Výchozí | Popis |
|---|---|---|
| `port` | `8000` | Port lokálního streamu. |
| `source_password` | `changeme` | Interní heslo Icecastu (zdroj/admin). Posluchači ho nepotřebují. |
| `bitrate` | `192` | Bitrate výstupního MP3 (kbps). |
| `spotify_bitrate` | `320` | Kvalita Spotify (96/160/320). |
| `fallback_url` | `…fm-evropa2-128` | Záložní online rádio. |
| `fallback_delay` | `15` | Prodleva (s) ticha, než naskočí záloha. |
| `zones` | `Obývák / obyvak` | Zóny: `name` (= jméno Spotify zařízení) + `mount`. |

## Adresa streamu

```
http://<IP_HA>:<port>/<mount>      např.  http://192.168.88.10:8000/obyvak
```

## Stav

- ✅ Fáze 1: stabilní stream + fallback
- 🧪 Fáze 1b: Spotify Connect (tato verze — v testu)
- ⏳ Fáze 2: automatické přepínání LARA rádií (ELKO EP)
