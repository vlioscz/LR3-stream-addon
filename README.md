# LR3 Stream — Home Assistant Add-on

**English** · [Čeština](README.cs.md)

[![Add repository to Home Assistant](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Fvlioscz%2FLR3-stream-addon)

> **⚠️ LR3 Stream is no longer maintained.** Development continues in
> **[LR3-AudioZone](https://github.com/vlioscz/LR3-AudioZone)**, which grew out of this add-on: the same Icecast
> stream with Spotify Connect, and it also finds ELKO EP "LARA" radios and switches them onto the
> stream by itself. **If you have LARA radios, use LR3-AudioZone.**
>
> This add-on still installs and runs as it is, but it will get no more fixes — including ones
> already made in LR3-AudioZone:
>
> - **It stores the Spotify login**, so whoever last picked a stream keeps it in their Spotify app
>   away from home and can play to it from anywhere (fixed in AudioZone 0.3.5).
> - **Up to 1 GB of audio cache per stream** is written to disk — on an HA Green that is soldered
>   storage (AudioZone 0.3.7 cut it to 200 MB and made it configurable).
> - **The stream goes out at 44.1 kHz.** LARA radios playing a 44.1 kHz stream from AudioZone
>   consumed it slightly faster than it arrived and dropped out roughly every 26 minutes; moving
>   to 48 kHz cured that there (AudioZone 0.4.0). It has not been measured with this add-on.

A rock-solid **local radio stream** for Home Assistant. Built on **Icecast + Liquidsoap**, so the stream **never drops**. **Spotify Connect** feeds the audio in (via librespot); when nothing is playing it stays alive and, after a configurable delay, an online-radio fallback kicks in (e.g. Evropa 2). Any player (VLC, in-wall radios, a browser…) can tune in and nothing kicks it off.

That's the key difference from MPD's "HTTPd output", which stops when idle — players don't understand that and disconnect.

---

## Installation

1. Click the button above (or in HA: **Settings → Add-ons → Add-on Store → ⋮ → Repositories** and paste `https://github.com/vlioscz/LR3-stream-addon`).
2. Find **LR3 Stream** → **Install** (the first build takes a while — it downloads the Debian base, Liquidsoap and librespot).
3. **Configuration** → set the port and streams → **Start**.

## Spotify Connect

After start, a device named after the stream (e.g. "Living room") appears in the Spotify app (same network, **Premium account**). Pick it as the speaker — the music flows into that stream. When you stop playback, the online-radio fallback kicks in after `fallback_delay` seconds. **No Spotify password is entered into the add-on** — it uses Spotify Connect discovery (zeroconf).

## Configuration

| Option | Default | Description |
|---|---|---|
| `port` | `8121` | Port of the local stream (Icecast). |
| `source_password` | `changeme` | Internal Icecast password (source/admin). Listeners don't need it. |
| `bitrate` | `192` | Output MP3 stream bitrate (kbps). |
| `spotify_bitrate` | `320` | Spotify quality (96 / 160 / 320). |
| `fallback_enabled` | `true` | Enable the fallback radio. Off → silence after the delay. |
| `fallback_url` | `…fm-evropa2-128` | Online radio used as fallback when Spotify isn't playing. |
| `fallback_delay` | `15` | Seconds of silence before the fallback kicks in. |
| `zones` | 1× `Default` | **Streams** you create (add or delete freely). Each = one Spotify Connect device + one Icecast mount. |

### Streams

Streams come **only** from the `zones` option — nothing is created automatically. Each stream has:

- a **name** = the Spotify Connect device name shown in the Spotify app,
- a **mount** = the last part of the URL: `http://<HA-IP>:<port>/<mount>`.

The default config ships one stream "Default" (mount `/default`); rename it, add more, or delete it as you like. **At least one** stream is required.

### Multi-room

Spotify only ever plays to **one** Connect device. To "play everywhere", use a single **shared** stream: tune all players to the same mount (e.g. `/default`) and play to that one device in Spotify. For separate rooms, create distinctly named streams and tune each player to its own mount.

## Where the stream lives

```
http://<HA_IP>:<port>/<mount>      e.g.  http://192.168.88.10:8121/default
```

The exact addresses are printed to the add-on **log** at start — just copy them into VLC / a radio / a browser.

## How it works

```
Spotify Connect (librespot) ─┐
online radio (fallback) ─────┼─► Liquidsoap ──► Icecast ──► players / VLC / …
silence ─────────────────────┘   (never drops)     (:port)
```

Icecast is the server players connect to. Liquidsoap is the "studio" that feeds it **one continuous stream** and switches the content (Spotify → fallback → silence) **without dropping the connection**, so listeners never get kicked off.

## Status

- ✅ **Stable stream** + online-radio fallback, never drops.
- ✅ **Spotify Connect** input per stream.
- ⛔ **No longer maintained** (last release 1.0.1). Development continues in **[LR3-AudioZone](https://github.com/vlioscz/LR3-AudioZone)** — see the notice at the top.
