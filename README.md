# LR3 Stream — Home Assistant Add-on

[![Přidat repozitář do Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fvlioscz%2FLR3-stream-addon)

Stabilní **lokální rozhlasový stream** pro Home Assistant. Postaveno na **Icecast + Liquidsoap**, takže stream **nikdy nevypadne**. Do streamu posílá zvuk **Spotify Connect** (přes librespot); když nic nehraje, drží se živý a po nastavené prodlevě naskočí záložní online rádio (např. Evropa 2). Rádia LARA i libovolný jiný přehrávač se připojí a nic je neodpojí.

To je hlavní rozdíl proti MPD „HTTPd output", který se při nečinnosti zastaví — a rádia to nepochopí a odpojí se.

---

## Instalace

1. Klikni na tlačítko nahoře (nebo v HA: **Settings → Add-ons → Add-on Store → ⋮ → Repositories** a vlož `https://github.com/vlioscz/LR3-stream-addon`).
2. Najdi **LR3 Stream** → **Install** (první build chvíli trvá — stahuje se Debian base, Liquidsoap a librespot).
3. **Configuration** → nastav port/zóny → **Start**.

## Spotify Connect

Po startu se v Spotify appce (stejná síť, **Premium účet**) objeví zařízení pojmenované podle zóny (např. „Obývák"). Vyber ho jako reproduktor — hudba poteče do streamu té zóny. Když přehrávání zastavíš, po `fallback_delay` sekundách naskočí záložní online rádio. **Žádné Spotify heslo se do addonu nezadává** — používá se Spotify Connect discovery (zeroconf).

## Konfigurace

| Volba | Výchozí | Popis |
|---|---|---|
| `port` | `8121` | Port lokálního streamu (Icecast). |
| `source_password` | `changeme` | Interní heslo Icecastu (zdroj/admin). Posluchači ho nepotřebují. |
| `bitrate` | `192` | Bitrate výstupního MP3 streamu (kbps). |
| `spotify_bitrate` | `320` | Kvalita Spotify (96 / 160 / 320). |
| `fallback_enabled` | `true` | Zapnout záložní rádio. Vypnuto → po prodlevě ticho (a rádia OFF). |
| `fallback_url` | `…fm-evropa2-128` | Online rádio jako záloha, když Spotify nehraje. |
| `fallback_delay` | `15` | Prodleva (s) ticha, než naskočí záloha. |
| `zones` | `Všude / vsude` | Zóny: každá má `name` (= i jméno Spotify zařízení) a `mount`. |

### Multi-room

Spotify hraje vždy jen do **jednoho** Connect zařízení. Víc reproduktorů se proto řeší
**sdíleným streamem**: zóna „Všude" je výchozí stream, na který jsou naladěná všechna
rádia — když do ní pustíš Spotify, hraje všude. Zóny pro jednotlivé místnosti slouží
k tomu pustit hudbu jen do jedné z nich.

## Kde stream běží

```
http://<IP_HA>:<port>/<mount>      např.  http://192.168.88.10:8121/vsude
```

Přesné adresy addon vypíše po startu do **logu** — stačí zkopírovat do VLC / rádia / prohlížeče.

## Jak to funguje

```
Spotify Connect (librespot) ─┐
online rádio (záloha) ───────┼─► Liquidsoap ──► Icecast ──► rádia / VLC / …
ticho ───────────────────────┘   (nikdy nespadne)   (:port)
```

Icecast je server, na který se rádia připojují. Liquidsoap je „studio", které do něj posílá **jeden nepřetržitý stream** a přepíná obsah (Spotify → záloha → ticho) **bez shození spojení**, takže posluchači nikdy nevypadnou.

## Roadmapa

- ✅ **Fáze 1:** stabilní stream + fallback na online rádio, nikdy nespadne.
- 🧪 **Fáze 1b (v testu):** vstup ze **Spotify Connect** na každou zónu.
- ⏳ **Fáze 2:** automatické přepínání **LARA rádií** (ELKO EP) na náš stream při startu Spotify + „zdvořilý" režim (nehijackuje rádio hrající něco jiného).
- ⏳ **Fáze 3:** ověření na reálném zařízení, případně DLNA push.
