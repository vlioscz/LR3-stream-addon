# LR3 Stream — Home Assistant Add-on

[![Přidat repozitář do Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fvlioscz%2FLR3-stream-addon)

Stabilní **lokální rozhlasový stream** pro Home Assistant. Postaveno na **Icecast + Liquidsoap**, takže stream **nikdy nevypadne** — i když nic nehraje, drží se živý (ticho) a jako záloha běží online rádio (např. Evropa 2). Rádia LARA i libovolný jiný přehrávač (VLC, telefon, prohlížeč) se na něj připojí a nic je neodpojí.

To je hlavní rozdíl proti MPD „HTTPd output", který se při nečinnosti zastaví — a rádia to nepochopí a odpojí se.

---

## Instalace

1. Klikni na tlačítko nahoře **„Přidat repozitář do Home Assistant"** (nebo v HA: **Settings → Add-ons → Add-on Store → ⋮ → Repositories** a vlož `https://github.com/vlioscz/LR3-stream-addon`).
2. V Add-on Store najdi **LR3 Stream** a dej **Install**.
3. Na kartě **Configuration** nastav port a zóny (viz níže), pak **Start**.

## Konfigurace

| Volba | Výchozí | Popis |
|---|---|---|
| `port` | `8000` | Port lokálního streamu (na tomto portu Icecast poslouchá). |
| `source_password` | `changeme` | Heslo Icecastu pro zdroj/admin. Klidně změň. |
| `bitrate` | `192` | Bitrate MP3 streamu v kbps. |
| `fallback_url` | `http://ice.actve.net/fm-evropa2-128` | Online rádio, které hraje jako záloha. |
| `fallback_delay` | `15` | Prodleva (s) před naskočením zálohy. *(využije se ve Fázi 1b se Spotify)* |
| `zones` | `Obývák / obyvak` | Seznam zón. Každá má `name` (název) a `mount` (část URL). |

Příklad více zón:

```yaml
port: 8000
zones:
  - name: "Obývák"
    mount: obyvak
  - name: "Koupelna"
    mount: koupelna
```

## Kde stream běží (adresa k připojení)

Adresa má tvar:

```
http://<IP_tvého_HA>:<port>/<mount>
```

Například pro výchozí nastavení: **`http://192.168.88.10:8000/obyvak`**

> 💡 **Nemusíš IP hádat.** Po startu addon vypíše do svého **logu** přesné adresy všech zón — stačí je zkopírovat a vložit do rádia / VLC / prohlížeče:
>
> ```
> ==================================================================
>   LR3 Stream — streamy jsou dostupné na těchto adresách:
> ------------------------------------------------------------------
>   Obývák           http://192.168.88.10:8000/obyvak
> ==================================================================
> ```

## Jak to funguje

```
librespot (Spotify)  ─┐                     (Fáze 1b)
                      ├─► Liquidsoap ──► Icecast ──► rádia / VLC / …
online rádio (záloha)─┘   (nikdy nespadne)  (:port)
ticho ───────────────┘
```

Icecast je server, na který se rádia připojují (stejně jako u „velkých" stanic). Liquidsoap je „studio", které do něj posílá **jeden nepřetržitý stream** a přepíná obsah **bez shození spojení**, takže posluchači nikdy nevypadnou.

## Roadmapa

- ✅ **Fáze 1 (teď):** stabilní stream + fallback na online rádio, nikdy nespadne.
- ⏳ **Fáze 1b:** vstup ze **Spotify Connect** (librespot) na každou zónu; při nečinnosti po `fallback_delay` naskočí online rádio.
- ⏳ **Fáze 2:** automatické přepínání **LARA rádií** (ELKO EP) na náš stream, když se spustí Spotify — a „zdvořilý" režim, který nehijackuje rádio hrající něco jiného.
- ⏳ **Fáze 3:** ověření na reálném zařízení, případně DLNA push.

## Poznámka

Spotify Connect a automatické přepínání LARA **zatím nejsou** součástí Fáze 1 — přidávají se v dalších krocích. Tahle verze cílí na jedno: **neprůstřelně stabilní lokální stream**, který si ověříš dřív, než na něj nabalíme zdroje.
