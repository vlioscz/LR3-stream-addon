# LR3 Stream

Stabilní lokální rozhlasový stream (Icecast + Liquidsoap), který **nikdy nevypadne**. Zvuk posílá **Spotify Connect** (librespot); když nic nehraje, drží se živý a po prodlevě naskočí záloha (např. Evropa 2). Jakýkoli přehrávač (VLC, rádio, prohlížeč) se připojí a nic ho neodpojí.

> **⚠️ Tento addon už dost zaostává za [LR3-AudioZone](https://github.com/vlioscz/LR3-AudioZone)** — souběžným
> projektem stavěným přímo pro rádia ELKO EP „LARA". LR3 Stream je starší větev „jen stabilní stream +
> Spotify Connect", nedrží krok, takže **není jisté, jestli bude fungovat správně**. Většina oprav od
> rozdělení ale řešila **komunikaci s LARA, ne samotné streamování** — streamovací část by tady měla pořád
> fungovat. Máš LARA rádia? Použij raději **LR3-AudioZone**.

## Rychlý start

1. **Configuration** → nastav `port` a `zones` (streamy) → **Start**.
2. V Spotify appce (stejná síť, **Premium**) vyber zařízení pojmenované podle streamu → hraje do něj.
3. **Log** → addon vypíše přesné adresy streamů. Zkopíruj do rádia / VLC.

## Volby

| Volba | Výchozí | Popis |
|---|---|---|
| `port` | `8121` | Port lokálního streamu. |
| `source_password` | `changeme` | Interní heslo Icecastu (zdroj/admin). Posluchači ho nepotřebují. |
| `bitrate` | `192` | Bitrate výstupního MP3 (kbps). |
| `spotify_bitrate` | `320` | Kvalita Spotify (96/160/320). |
| `fallback_enabled` | `true` | Zapnout záložní rádio. Vypnuto → po prodlevě ticho. |
| `fallback_url` | `…fm-evropa2-128` | Záložní online rádio. |
| `fallback_delay` | `15` | Prodleva (s) ticha, než naskočí záloha. |
| `zones` | 1× `Default` | **Streamy**, které si vytvoříš (přidávej i mazej). Každý = 1 Spotify Connect zařízení + 1 mount. |

## Streamy

Streamy vznikají **jen** z `zones` — nic automatického. Každý má **název** (= jméno Spotify zařízení) a **mount** (poslední část URL). Je potřeba aspoň jeden. Pro „hrát všude" nalaď všechny přehrávače na stejný mount a pusť Spotify do toho jednoho zařízení.

## Adresa streamu

```
http://<IP_HA>:<port>/<mount>      např.  http://192.168.88.10:8121/default
```

## Stav

- ✅ Stabilní stream + fallback
- ✅ Spotify Connect
- 🎯 **v1.0 — finální.** Ovládání LARA rádií řeší samostatný projekt **LR3-AudioZone**.
