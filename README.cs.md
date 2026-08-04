# LR3 Stream — Home Assistant Add-on

[English](README.md) · **Čeština**

[![Přidat repozitář do Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fvlioscz%2FLR3-stream-addon)

Stabilní **lokální rozhlasový stream** pro Home Assistant. Postaveno na **Icecast + Liquidsoap**, takže stream **nikdy nevypadne**. Do streamu posílá zvuk **Spotify Connect** (přes librespot); když nic nehraje, drží se živý a po nastavené prodlevě naskočí záložní online rádio (např. Evropa 2). Připojí se libovolný přehrávač (VLC, rádia, prohlížeč…) a nic ho neodpojí.

To je hlavní rozdíl proti MPD „HTTPd output", který se při nečinnosti zastaví — a přehrávače to nepochopí a odpojí se.

> **Ovládáš rádia ELKO EP „LARA"?** Automatické přepínání LARA rádií na tento stream přes
> **Slim server (SlimProto)** řeší samostatný projekt **[LR3-AudioZone](https://github.com/vlioscz/LR3-AudioZone)**.
> LR3 Stream je čistý „stabilní stream + Spotify Connect"; nic aktivně nepřepíná.

---

## Instalace

1. Klikni na tlačítko nahoře (nebo v HA: **Settings → Add-ons → Add-on Store → ⋮ → Repositories** a vlož `https://github.com/vlioscz/LR3-stream-addon`).
2. Najdi **LR3 Stream** → **Install** (první build chvíli trvá — stahuje se Debian base, Liquidsoap a librespot).
3. **Configuration** → nastav port a streamy → **Start**.

## Spotify Connect

Po startu se v Spotify appce (stejná síť, **Premium účet**) objeví zařízení pojmenované podle streamu (např. „Obývák"). Vyber ho jako reproduktor — hudba poteče do toho streamu. Když přehrávání zastavíš, po `fallback_delay` sekundách naskočí záložní online rádio. **Žádné Spotify heslo se do addonu nezadává** — používá se Spotify Connect discovery (zeroconf).

## Konfigurace

| Volba | Výchozí | Popis |
|---|---|---|
| `port` | `8121` | Port lokálního streamu (Icecast). |
| `source_password` | `changeme` | Interní heslo Icecastu (zdroj/admin). Posluchači ho nepotřebují. |
| `bitrate` | `192` | Bitrate výstupního MP3 streamu (kbps). |
| `spotify_bitrate` | `320` | Kvalita Spotify (96 / 160 / 320). |
| `fallback_enabled` | `true` | Zapnout záložní rádio. Vypnuto → po prodlevě ticho. |
| `fallback_url` | `…fm-evropa2-128` | Online rádio jako záloha, když Spotify nehraje. |
| `fallback_delay` | `15` | Prodleva (s) ticha, než naskočí záloha. |
| `zones` | 1× `Default` | **Streamy**, které si vytvoříš (přidávej i mazej). Každý = jeden Spotify Connect zařízení + jeden Icecast mount. |

### Streamy

Streamy vznikají **jen** z volby `zones` — nic se nevytváří automaticky. Každý stream má:

- **název** = jméno Spotify Connect zařízení, které se objeví v appce Spotify,
- **mount** = poslední část URL: `http://<IP-HA>:<port>/<mount>`.

Výchozí konfigurace obsahuje jeden stream „Default" (mount `/default`); klidně ho přejmenuj, přidej další nebo smaž. Je potřeba **aspoň jeden** stream.

### Multi-room

Spotify hraje vždy jen do **jednoho** Connect zařízení. „Hrát všude" vyřešíš jedním **sdíleným** streamem: všechny přehrávače nalaď na stejný mount (např. `/default`) a ve Spotify pusť to jedno zařízení. Pro samostatné místnosti vytvoř zvlášť pojmenované streamy a přehrávače nalaď každý na svůj mount.

## Kde stream běží

```
http://<IP_HA>:<port>/<mount>      např.  http://192.168.88.10:8121/default
```

Přesné adresy addon vypíše po startu do **logu** — stačí zkopírovat do VLC / rádia / prohlížeče.

## Jak to funguje

```
Spotify Connect (librespot) ─┐
online rádio (záloha) ───────┼─► Liquidsoap ──► Icecast ──► přehrávače / VLC / …
ticho ───────────────────────┘   (nikdy nespadne)   (:port)
```

Icecast je server, na který se přehrávače připojují. Liquidsoap je „studio", které do něj posílá **jeden nepřetržitý stream** a přepíná obsah (Spotify → záloha → ticho) **bez shození spojení**, takže posluchači nikdy nevypadnou.

## Stav

- ✅ **Stabilní stream** + fallback na online rádio, nikdy nespadne.
- ✅ **Spotify Connect** vstup na každý stream.
- 🎯 **v1.0** — finální „stabilní stream + Spotify Connect + ruční streamy". Ovládání LARA
  rádií se přesunulo do samostatného projektu **[LR3-AudioZone](https://github.com/vlioscz/LR3-AudioZone)**.
