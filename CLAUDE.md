# LR3 Stream — project context

Hand-off / working context for this repo. (Claude Code loads this automatically.)
Human-facing usage docs are in `README.md`; this file is the technical state + decisions.

## What this is

A **Home Assistant add-on** that serves a **stable local Icecast radio stream** on the LAN.
**Spotify Connect** goes in (per stream, via librespot); the mount **never drops** out, with an
online-radio fallback when nothing plays. Any player (VLC, a browser, in-wall radios…) can tune in.

This is the **finalized "stream only"** add-on: stable stream + Spotify Connect + **manually
defined** streams. It does **not** discover or control any radios.

- Repo: https://github.com/vlioscz/LR3-stream-addon (public). Add-on folder: `lr3_stream/`.
- Target HW: **HA Green / arm64** (also amd64). Default stream port **8121**.
- Owner communicates in **Czech**; keep replies in Czech.

> **LARA / audio-zone control moved out.** Automatically switching ELKO EP "LARA" radios onto a
> stream via a **Slim server (SlimProto)** is now a separate project: **LR3-AudioZone**
> (https://github.com/vlioscz/LR3-AudioZone). Do not re-add discovery/SlimProto/`control_mode`
> here — this add-on is intentionally just the stable stream + Spotify Connect.

## Current status

- ✅ **v1.0.0 — final.** Stable Icecast+Liquidsoap stream, Spotify Connect per stream (librespot),
  online-radio fallback, mount never drops. Streams are **manual only** (the `zones` option).

## Repo layout

```
lr3_stream/
  config.yaml        add-on manifest + options schema
  build.yaml         arm64/amd64 Debian base images
  Dockerfile         apt: icecast2 liquidsoap ffmpeg jq dbus avahi-daemon
                     + librespot from the raspotify .deb
  run.sh             PID 1: dbus+avahi, Icecast, one Liquidsoap per (manual) stream
  icecast.xml.tpl    Icecast config template (port/pass/hostname substituted at start)
  radio.liq.tpl      per-stream Liquidsoap: librespot (Spotify) -> fallback radio -> silence
  translations/      config UI field labels (cs, en)
  icon.png / logo.png  brand assets (red "LR3" on shutter slats, matching vlios.cz)
brands/              logo source (icon.svg + make_icons.py)
```

## How the streaming works

Icecast is the server players connect to. **Liquidsoap** feeds one never-dropping source per stream:
`fallback(track_sensitive=false, [spotify, radio, silence])` with `output.icecast(fallible=false)`,
so the mount is always fed and never closes. Per-stream pieces:
- **librespot** = a Spotify Connect device named after the stream; audio → Liquidsoap via
  `input.external.rawaudio` (`buffer=1.0, max=1.5` — small; librespot's own buffer absorbs jitter).
- Wrapped so a pause = silence held for `fallback_delay`, then the online radio; resume = instant.
- Liquidsoap runs as root → `settings.init.allow_root.set(true)`.
- Container runs its own **dbus + avahi-daemon** because the raspotify librespot has only the avahi
  zeroconf backend.

Streams come **only** from the `zones` option — nothing is auto-created. Each `zone` = one Spotify
Connect device (its `name`) + one Icecast mount (its `mount`). At least one is required. There is
**no special/undeletable "default"** stream anymore (config ships one editable `Default` example).

## Build / dev conventions

- HA keeps a user's saved options across updates → new config.yaml defaults don't auto-apply; tell the user
  to adjust in the Configuration tab.
- Line endings: `.gitattributes` forces **LF** (scripts run in a Linux container). `*.png` marked binary.
- Commit only when the user asks; end commit messages with the `Co-Authored-By: Claude Opus 4.8` trailer.
  main is the release branch the add-on installs from; we push there directly.
- Bump `version:` in `config.yaml` on each shippable change (now **1.0.0**).
- Sibling folder `D:\Claude\Homeassistant\is3 exp integration` is a SEPARATE project — do not touch.
