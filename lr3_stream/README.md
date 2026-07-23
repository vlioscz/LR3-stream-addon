# LR3 Stream

Stabilní lokální rozhlasový stream (Icecast + Liquidsoap), který **nikdy nevypadne**. Když nic nehraje, drží se živý a jako záloha běží online rádio (např. Evropa 2). Rádia LARA i jakýkoli jiný přehrávač se připojí a nic je neodpojí.

## Rychlý start

1. Na kartě **Configuration** nastav `port` a `zones`.
2. **Start**.
3. Otevři **Log** — addon vypíše přesné adresy streamů. Zkopíruj a vlož do rádia / VLC.

## Volby

| Volba | Výchozí | Popis |
|---|---|---|
| `port` | `8000` | Port lokálního streamu. |
| `source_password` | `changeme` | Heslo Icecastu (zdroj/admin). |
| `bitrate` | `192` | Bitrate MP3 (kbps). |
| `fallback_url` | `http://ice.actve.net/fm-evropa2-128` | Záložní online rádio. |
| `fallback_delay` | `15` | Prodleva (s) před zálohou. *(Fáze 1b)* |
| `zones` | `Obývák / obyvak` | Zóny: `name` + `mount`. |

## Adresa streamu

```
http://<IP_HA>:<port>/<mount>      např.  http://192.168.88.10:8000/obyvak
```

Přesné adresy vypíše addon po startu do **logu** — není třeba nic hádat.

## Stav

- ✅ Fáze 1: stabilní stream + fallback (tato verze)
- ⏳ Fáze 1b: Spotify Connect (librespot) na zónu
- ⏳ Fáze 2: automatické přepínání LARA rádií (ELKO EP)

Spotify a přepínání LARA zatím **nejsou** aktivní — přidávají se v dalších krocích.
