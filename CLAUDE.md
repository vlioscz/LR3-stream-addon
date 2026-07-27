# LR3 Stream — project context

Hand-off / working context for this repo. (Claude Code loads this automatically.)
Human-facing usage docs are in `README.md`; this file is the technical state + decisions so
work can continue on any machine straight after `git clone`.

## What this is

A **Home Assistant add-on** that serves a **stable local Icecast radio stream** on the LAN that
in-wall **ELKO EP "LARA"** radios (and any player) tune into. It replaces the old ELKO
"Connection Server": Spotify Connect in, a stream that **never drops** out, with an online-radio
fallback when nothing plays. Later it also **discovers LARA radios and switches them** to our
stream automatically.

- Repo: https://github.com/vlioscz/LR3-stream-addon (public). Add-on folder: `lr3_stream/`.
- Target HW: **HA Green / arm64** (also amd64). Default stream port **8121**.
- Owner communicates in **Czech**; keep replies in Czech.

## Current status

- ✅ **Phase 1** — stable stream: Icecast + Liquidsoap, online-radio fallback, mount never drops.
- ✅ **Phase 1b** — Spotify Connect per zone via librespot. Latency ~0 (server side); stop-tail ~2 s.
- ✅ **Phase 2 (built + bench-tested, NOT yet validated on a real LARA)** — LARA discovery +
  control (`lr3_stream/lr3ctl/`), behind `control_mode` (default `off`).
- ⏳ **Phase 3** — validate the LARA controller on a real device (see checklist below).

## Repo layout

```
lr3_stream/
  config.yaml        add-on manifest + options schema
  build.yaml         arm64/amd64 Debian base images
  Dockerfile         apt: icecast2 liquidsoap ffmpeg jq dbus avahi-daemon python3
                     + librespot from the raspotify .deb; COPY lr3ctl -> /opt/lr3ctl
  run.sh             PID 1: dbus+avahi, Icecast, one Liquidsoap per zone, the LARA controller;
                     writes the librespot --onevent hook (/etc/lr3/spotify_event.sh)
  icecast.xml.tpl    Icecast config template (port/pass/hostname substituted at start)
  radio.liq.tpl      per-zone Liquidsoap: librespot (Spotify) -> fallback radio -> silence
  translations/      config UI field labels (cs, en)
  icon.png / logo.png  brand assets (red "LR3" on shutter slats, matching vlios.cz)
  lr3ctl/            Phase-2 LARA controller (Python, stdlib only)
brands/              logo source (icon.svg + make_icons.py)
```

## How the streaming works

Icecast is the server radios connect to. **Liquidsoap** feeds one never-dropping source per zone:
`fallback(track_sensitive=false, [spotify, radio, silence])` with `output.icecast(fallible=false)`,
so the mount is always fed and never closes. Per-zone pieces:
- **librespot** = a Spotify Connect device named after the zone; audio → Liquidsoap via
  `input.external.rawaudio` (`buffer=1.0, max=1.5` — small, because librespot writes ahead and the
  FIFO is the main latency / stop-tail; librespot's own buffer absorbs jitter).
- Wrapped so a pause = silence held for `fallback_delay`, then the online radio; resume = instant.
- **Multi-room**: Spotify only plays to ONE Connect device, so multi-room = a shared **`default`**
  stream (mount `/default`) that all radios sit on. Play to the "Default" device → all radios hear
  it. Per-room zones are for playing to a single room.

Auto streams (`default` + one per discovered radio) are created by the add-on and are **not** in
the user's options → cannot be deleted. The `zones` option = **manual** extra streams only.
Container runs its own **dbus + avahi-daemon** because the raspotify librespot has only the avahi
zeroconf backend. Liquidsoap runs as root → `settings.init.allow_root.set(true)`.

## LARA control (Phase 2) — `control_mode`

- **`off`** (default, safe) — discover + log radios only; never switches.
- **`preset`** (path A, primary) — LARA plays our Icecast mount as a stored **radio preset**
  (`select_source(RADIO)` + `select_station` by name). User adds the preset ONCE via ELKO's
  Configurator (Icecast MP3 is officially supported). Field-proven protocol.
- **`slimproto`** (path B2, conditional upgrade) — the add-on is a minimal **SlimProto/Squeezebox
  server** on TCP 3483 and pushes the Icecast URL to LARA (`strm` command). Verified byte layouts
  vs squeezelite/aioslimproto; reuses the whole Icecast stack. Enable only once a device confirms it.

Routing: driven by the per-mount Spotify-active flag that `librespot --onevent` writes to
`/tmp/spotify_state_<mount>`. Zone active → target radios play that mount. Default → all radios.
On stop: radio stays on its mount (plays fallback) or is stopped if `fallback_enabled=false`
(NOT auto-returned to default). **No "polite" mode** — sending to a Connect device is the intent
to switch.

**DLNA is OUT** — LARA advertises it but it is broken in practice (user-tested: never
discovered/played). Do not build on DLNA.

## LARA protocol (reverse-engineered; verified)

Fully decoded from the `elkoep_lara` lib + decompiling ELKO's Finder/Configurator (.NET) and
inspecting the firmware. All of it is implemented in **`lr3_stream/lr3ctl/elkoproto.py`**
(self-tested against captured packets — key recovery, name decode). Highlights:

- **Obfuscation**: whole packet XORed with a fixed 1024-byte mask (embedded in elkoproto.py),
  keyed by a random 0–699 int in the last 2 bytes. Magic header `FF FA FA FF`. `admin`/`elkoep`.
- **Discovery = UDP broadcast** to `255.255.255.255:61695`. Probe (11 B, then obfuscate):
  `FF FA FA FF <rand> <seq> 09 80 02`. Reply → `DeviceID (data[9..10]) == 3` = LARA;
  `IP=data[15:19]`, `Name=data[19:36]` (17 B, **windows-1250**), `MAC=data[36:42]`, `FW=data[11:14]`.
  One broadcast returns ip+name+mac+fw for every LARA. Key radios by **MAC** (not DHCP IP).
- **Control = TCP 61695** (connect-per-command): `select_source` (RADIO=1, AUX=3, DLNA=4),
  `select_station(index)` (presets only — NO arbitrary-URL command), play/stop/volume, read
  status/stations. Firmware gate in the lib: 35000 ≤ FW < 38000.
- **LARA is a Logitech Media Server (Squeezebox) client** — config has `IP_slim_server` +
  `LMSUsername`/`LMSPassword`. That's how the old Connection Server pushed audio. SlimProto is the
  open LMS protocol (player→server TCP 3483, HELO, server pushes `strm` = arbitrary URL + control).
- ⚠️ The TCP config-read response leaks **plaintext** admin+user passwords → never log raw packets.
- ⚠️ Do **not** blind-write presets over 61695 — unknown opcode/CRC; a write is a whole-list Save
  that can wipe all 40 presets. Add presets via the Configurator; the mount in a preset is
  effectively immutable (baked into the radio), so never rename an auto-assigned mount.

## Phase 3 — on-device validation (the only thing left, needs a real LARA)

1. **Discovery**: start add-on, watch `[lr3ctl]` log — does UDP broadcast find the LARA(s)? name/ip/mac/fw correct?
2. **Path A** (`control_mode=preset`): add one Icecast preset in the Configurator (IP=HA **numeric/static**,
   Port=8121, File name=`default`). Confirm Spotify on the "Default" device switches the LARA to `/default`;
   confirm 61695 control works on their firmware.
3. **Path B2** (`control_mode=slimproto`): set `slim_server_active` + `IP_slim_server`=this HA in the LARA.
   `tcpdump :3483` for an inbound HELO (pass/fail for all of B2). Does HELO advertise `mp3`? if not, add a
   FLAC/PCM Icecast mount. Does `strm-s` make LARA appear in the Icecast log and play? Does it auto-route to
   the speaker or also need a 61695 SOURCE-select? mount-switch latency; volume; keepalive.

## Build / dev conventions

- HA keeps a user's saved options across updates → new config.yaml defaults don't auto-apply; tell the user
  to adjust in the Configuration tab.
- Line endings: `.gitattributes` forces **LF** (scripts run in a Linux container). `*.png` marked binary.
- Commit only when the user asks; end commit messages with the `Co-Authored-By: Claude Opus 4.8` trailer.
  main is the release branch the add-on installs from; we push there directly.
- Bump `version:` in `config.yaml` on each shippable change (currently 0.5.0, scheme 0.x while in dev).
- Sibling folder `D:\Claude\Homeassistant\is3 exp integration` is a SEPARATE project — do not touch.
