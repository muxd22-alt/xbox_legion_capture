# Xbox Series S -> Legion Go S -> 90 fps with VeyAmux

Play GTA VI from an Xbox Series S at a smooth **90 fps on a 1080p monitor**,
using a capture card, a Legion Go S running Bazzite, and **VeyAmux** for
picture cleanup and frame generation.

```
Xbox Series S (1080p60 out, SDR)
  | HDMI
  v
Joyzzz capture card (capture 1920x1080 @ 60; VeyAmux removes the repeats)
  | USB 3.0
  v
JSAUX dock -> Legion Go S (Bazzite)
  | VeyAmux: cleanup + 3x via lsfg-vk
  v
1920x1080 monitor at a fixed 90 Hz
```

No TV, no Xiaomi box, no Moonlight, no Sunshine, no network, no 4K.

## The number

**30 unique frames x 3 = 90.**

GTA VI is a 30 fps game. The Xbox sends a 60 Hz signal with every picture
twice. VeyAmux compares whole frames, drops the repeats, then triples the 30
unique frames through Lossless Scaling / `lsfg-vk`.

Two consequences decide the whole setup:

1. **Capture at 60, not 30.** The 60 Hz signal carries the 30 fps game with
   uneven 17/50 ms spacing. VeyAmux is built to remove those repeats. A 30 Hz
   capture throws away every other frame blindly and can alias real frames
   against the 17/50 ms pattern.
2. **VRR must be off, and the display must be a fixed 90 Hz.** lsfg-vk 2 needs
   a fixed refresh to space generated frames evenly; VeyAmux explicitly warns
   when Adaptive Sync is on. 90 on a fixed 120 Hz panel is 3:2 and judders.

If the monitor has no real 90 Hz mode, use **Fixed 2x at a fixed 60 Hz**
(30 -> 60). Do not run 3x on 120 Hz.

| Display mode | Frame gen | Output | Even? |
|---|---|---|---|
| **90 Hz fixed, VRR off** | **3x** | **90** | **Yes - target** |
| 120 Hz fixed, VRR off | 3x | 90 | No, 3:2 judder |
| 120 Hz + VRR | 3x | 90 | Not with lsfg; VRR must be off |
| 60 Hz fixed, VRR off | 2x | 60 | Yes - fallback |
| 120 Hz fixed, VRR off | 2x | 60 | Yes, exact 2:1 |

## Why VeyAmux

| | |
|---|---|
| One AppImage | No mpv config, no shader folder, no hand-written lsfg profile. |
| Built for this | Developed and tested on Bazzite KDE with AMD graphics. |
| Capture + audio | V4L2 video and the card's audio in one window. |
| Picture cleanup | Noise reduction, anti-flicker, sharpening, AA, colour, dehaze. |
| Duplicate removal | Compares whole pictures, so a 60 Hz capture becomes 30 unique frames. |
| Guard rails | Warns about MJPEG, VRR, over-asking frame gen, and refresh mismatch. |
| Diagnostics | Built-in demo, F3 frame-time overlay, "Check my setup". |

The trade-off is the multiplier: **2x or 3x**. 3x gives 90 from 30; 4x is not
exposed.

## Quick start

1. **Xbox:** 1080p, 60 Hz, HDR off, VRR off, 8-bit, stereo uncompressed.
2. **Monitor:** 1920x1080 at a **fixed 90 Hz**, **VRR/Adaptive Sync: Never**,
   HDR off, scaling 100%. Check `kscreen-doctor -o` for a 90 Hz mode first.
3. **Capture:** 1080p**60** on the stable `/dev/v4l/by-id/...` node. Prefer
   YUYV/NV12 if listed at 60, otherwise MJPEG. Use 30 only if 60 overloads USB
   or decode.
4. **Lossless Scaling:** own it on Steam, switch to the **`lsfg-vk`** beta
   branch.
5. **lsfg-vk 2:** `ujust get-lsfg install`, or VeyAmux's "Install lsfg-vk 2"
   button.
6. **VeyAmux:** capture card, 1080p60, frame generation **Fixed 3x**, **Even
   out frame pacing on**, cleanup light. Confirm **"Active through lsfg-vk"**.
7. **Play.** The info line should say `signal ... @ 60 fps` and
   `30 fps -> 90 fps (Lossless Scaling 3x)`.

If there is no 90 Hz mode: set the monitor to **60 Hz fixed**, frame generation
**Fixed 2x**, and target a clean 60.

Full steps: `docs/02-veyamux-setup.md`.
Checklist: `docs/03-checklist.md`.

## Hardware

| Part | Role | Limit that matters |
|---|---|---|
| Xbox Series S | GTA VI at ~1080p30 | 30 fps target; 60 Hz output |
| Joyzzz capture card | HDMI -> USB UVC, 4K30 passthrough | Capture 1080p60 |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1, 3x USB-A 3.0, 100W PD | Plug into the Legion USB4 port |
| Legion Go S | AMD Z2 Go, Radeon 680M (12 CU), Bazzite | 3x/90 is the target; performance TDP |
| Monitor | 1080p with a 90 Hz mode | Fixed 90 Hz, VRR off |

Cabling:

1. Xbox HDMI -> card HDMI IN.
2. Card USB -> dock USB-A 3.0.
3. Dock USB-C -> Legion USB4.
4. Charger -> dock PD 100 W.
5. Dock HDMI -> monitor.
6. Optional: card HDMI OUT -> monitor, for the passthrough comparison.

## Settings summary

### Xbox

1080p, 60 Hz, HDR off, VRR off, 8-bit, Standard colour, stereo uncompressed.

Xbox VRR off is deliberate: the capture card needs a steady signal.

### Capture

1920x1080 @ **60**, YUYV/NV12 if offered, otherwise MJPEG. 30 is a fallback,
not the starting point.

### Monitor

1920x1080 @ **90 Hz fixed**, **VRR off**, SDR, 100% scaling. If there is no
90 Hz mode, 1920x1080 @ 60 Hz fixed and 2x.

### VeyAmux

| Setting | Value |
|---|---|
| Source | capture card, 1920x1080 @ 60 |
| Upscaling | Off/1:1 if offered; otherwise 1.5x at most |
| Noise reduction | Spatial or Both, low/medium |
| Anti-flicker | On |
| Sharpness | light |
| Frame generation | **Fixed 3x** (Lossless Scaling) |
| Even out frame pacing | **On** (~17 ms extra) |
| Display | fullscreen, fixed 90 Hz, VRR off |
| HDR | off |

## What VeyAmux is not

- **Not a detail-recovery upscaler.** At 1080p -> 1080p it cleans and sharpens;
  the Xbox already did the internal upscale.
- **Not 120 from 30.** 3x max. 90 is the goal here.
- **Not an Xbox Remote Play client.** VeyAmux's Remote Play option is
  PlayStation-only; the Xbox path is the capture card. The 720p/1080p demo
  buttons are not a capture mode.
- **Not a VRR tool.** With lsfg frame generation, VRR stays off.

## Verify

```bash
# display: fixed 90 Hz, VRR off
kscreen-doctor -o

# capture formats on the stable node (60 preferred)
ls -l /dev/v4l/by-id/
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext

# lsfg-vk install and config
ujust get-lsfg status
~/.local/bin/lsfg-vk-cli healthcheck
~/.local/bin/lsfg-vk-cli validate

# VeyAmux's own log
tail -n 50 ~/.config/VeyAmux/lsfg-vk.log
```

VeyAmux's info line should read like:

```
≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×) · signal 1920×1080 @ 60 fps
```

Pass: display fixed at 90 Hz, VRR off, 3x active, motion even while driving.

## Repo map

| File | What it is |
|---|---|
| `docs/01-signal-chain.md` | Hardware, cabling, capture formats, why 60 capture and 90 Hz. |
| `docs/02-veyamux-setup.md` | Install and configure VeyAmux end to end. |
| `docs/03-checklist.md` | Home-day checklist with pass/fail steps. |
| `docs/04-audio-controller.md` | Audio through VeyAmux, controller facts. |
| `docs/05-settings.md` | All settings and the test matrix. |
| `docs/06-troubleshooting.md` | VeyAmux/lsfg errors, VRR, audio, rollback. |
| `AGENT-PROMPT.md` | Copy-paste briefing for the agent at the machine. |
| `scripts/check-capture.sh` | Lists V4L2 by-id nodes, formats and audio sources. |
| `scripts/check-veyamux.sh` | Checks VeyAmux, lsfg-vk, display mode and logs. |

## Safety

- VeyAmux is an **AppImage**: unsigned and unsandboxed. Download it from the
  project's releases, run it as your user, never with `sudo`. If you want to be
  strict, `--appimage-extract` and read the source first.
- Do not install random "FSR 4 / DLSS on a capture feed" DLLs. There is no game
  engine to hook.
- Keep the controller paired to the Xbox; video capture is one-way.

## Sources

- VeyAmux: https://github.com/8BiTw0LF/VeyAmux
- VeyAmux releases: https://github.com/8BiTw0LF/VeyAmux/releases
- lsfg-vk docs: https://lsfg-vk.dev/docs/
- lsfg-vk pacing modes: https://lsfg-vk.dev/docs/configuration/pacing-modes/
- Bazzite framegen recipe: https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/share/ublue-os/just/87-bazzite-framegen.just
- GTA VI 30 fps target: https://www.glitched.online/gta-vi-targets-30fps-on-consoles-with-ps5-pro-ray-tracing-enhancements
