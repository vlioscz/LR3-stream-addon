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
| `zones` | `[]` | **Ruční** streamy navíc (jdou přidávat i mazat). Stream `Default` a streamy pro nalezená rádia vznikají automaticky a v tomto seznamu nejsou. |

### Streamy: automatické vs. ruční

- **`Default`** (mount `/default`) — vzniká **vždy automaticky** a **nejde smazat**. Je to
  sdílený stream, na který jsou normálně naladěná všechna rádia.
- **Streamy pro rádia** — vzniknou automaticky pro každé nalezené LARA rádio, pojmenované
  podle něj. Taky nejdou smazat. *(připravuje se)*
- **Ruční streamy** (`zones`) — volitelné, spravuješ je sám, klidně i pro jiné využití.

### Multi-room

Spotify hraje vždy jen do **jednoho** Connect zařízení — víc reproduktorů najednou přes
Spotify nejde. Řeší se to sdíleným streamem:

- Pustíš Spotify do zařízení **„Default"** → slyší to **všechna** rádia (jsou na `/default`) = multi-room.
- Pustíš Spotify do zařízení **konkrétní místnosti** → hraje **jen ta místnost**; ostatní zůstanou na `Default`.

> ⚠️ Multi-room **nefunguje** tak, že pustíš hudbu do jedné místnosti a ostatní se přidají —
> každý stream je samostatný, takže ten druhý správně přejde na fallback. Pro „hrát všude"
> musí rádia poslouchat `/default` a Spotify musí hrát do zařízení **„Default"**.

## Kde stream běží

```
http://<IP_HA>:<port>/<mount>      např.  http://192.168.88.10:8121/default
```

Přesné adresy addon vypíše po startu do **logu** — stačí zkopírovat do VLC / rádia / prohlížeče.

## Jak to funguje

```
Spotify Connect (librespot) ─┐
online rádio (záloha) ───────┼─► Liquidsoap ──► Icecast ──► rádia / VLC / …
ticho ───────────────────────┘   (nikdy nespadne)   (:port)
```

Icecast je server, na který se rádia připojují. Liquidsoap je „studio", které do něj posílá **jeden nepřetržitý stream** a přepíná obsah (Spotify → záloha → ticho) **bez shození spojení**, takže posluchači nikdy nevypadnou.

## Ovládání LARA rádií (ELKO EP)

Addon umí **najít LARA rádia** v síti (UDP broadcast) a **přepínat je** na náš stream, když
se spustí Spotify. Řídí to volba **`control_mode`**:

- **`off`** (výchozí) — jen najde rádia a vypíše je do logu, nic nepřepíná.
- **`preset`** — LARA naladí náš stream jako svůj uložený **rádio preset** (preset přidáš
  jednou v ELKO konfiguračce; addon ho pak vybírá podle jména = názvu mountu).
- **`slimproto`** — addon je **SlimProto (Squeezebox) server** a pushuje stream do LARA
  (nastav v LAŘE `slim server` + IP tohoto HA).

> `preset`/`slimproto` zapni až **s reálnou LARA** — logika je hotová a otestovaná nasucho,
> ale finální chování je nutné ověřit na zařízení.

## Roadmapa

- ✅ **Fáze 1:** stabilní stream + fallback na online rádio, nikdy nespadne.
- ✅ **Fáze 1b:** vstup ze **Spotify Connect** na každou zónu.
- 🧪 **Fáze 2 (logika hotová, čeká na zařízení):** hledání a ovládání **LARA rádií** —
  discovery (UDP broadcast), přepínání přes preset i SlimProto.
- ⏳ **Fáze 3:** ověření celého toku na reálné LAŘE.
