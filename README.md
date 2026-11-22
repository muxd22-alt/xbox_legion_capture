# Xbox Series S -> Legion Go S -> 90 fps with VeyAmux

Play GTA VI from an Xbox Series S at a smooth **90 fps on a 1080p monitor**,
using a capture card, a Legion Go S running Bazzite, and **VeyAmux** for
picture cleanup and frame generation.

```
Xbox Series S (1080p60 out, SDR)
  | HDMI
  v
Joyzzz capture card (capture 1920x1080 @ 30 fps)
  | USB 3.0
  v
JSAUX dock -> Legion Go S (Bazzite)
  | VeyAmux: noise reduction + sharpening + 3x via lsfg-vk
  v
1920x1080 monitor @ 120 Hz + VRR, showing 90 fps
```

No TV, no Xiaomi box, no Moonlight, no Sunshine, no network, no 4K.

## The number

**30 x 3 = 90.**

GTA VI is a 30 fps game. The Xbox sends a 60 Hz signal with every frame twice.
VeyAmux drops the repeated frames, then triples what is left through Lossless
Scaling / `lsfg-vk`. 90 is an exact multiple of 30, so the cadence is even.

Your monitor runs **120 Hz with VRR**, so 90 fps is presented evenly instead of
juddering 3:2. That is why VRR is part of the setup, not an optional extra.

**120 fps is not this path.** VeyAmux exposes 2x and 3x, not 4x. From a 30 fps
game that is 60 or 90. This repo is built around VeyAmux and 90.

## Why VeyAmux

| | |
|---|---|
| One AppImage | No mpv config, no shader folder, no hand-written lsfg profile. |
| Built for this | Developed and tested on Bazzite KDE with AMD graphics. |
| Capture + audio | V4L2 video and the card's audio in one window. |
| Picture cleanup | Noise reduction, anti-flicker, sharpening, AA, colour, dehaze. |
| Duplicate removal | Finds repeated frames by comparing whole pictures, like Veyra. |
| Guard rails | Warns about MJPEG, over-asking frame gen, and refresh mismatch. |
| Diagnostics | Built-in demo, F3 frame-time overlay, "Check my setup". |

The trade-off is the multiplier: **2x or 3x**. That is the 90 fps ceiling.

## Quick start

1. **Xbox:** 1080p, 60 Hz, HDR off, VRR off, 8-bit, stereo uncompressed.
2. **Monitor:** 1920x1080, **120 Hz, VRR/Adaptive Sync on**, HDR off, scaling
   100%.
3. **Capture:** 1080p30 on the stable `/dev/v4l/by-id/...` node. Prefer
   YUYV/NV12 over MJPEG if both exist at 30.
4. **Lossless Scaling:** own it on Steam, switch to the **`lsfg-vk`** beta
   branch.
5. **lsfg-vk 2:** `ujust get-lsfg install`, or use VeyAmux's "Install lsfg-vk 2"
   button.
6. **VeyAmux:** run the AppImage, pick the card, set 1080p30, frame generation
   **Fixed 3x**, picture cleanup on. Confirm **"Active through lsfg-vk"**.
7. **Play.** The info line should say `30 fps -> 90 fps (Lossless Scaling 3x)`.

Full steps: `docs/02-veyamux-setup.md`.
Checklist: `docs/03-checklist.md`.

## Hardware

| Part | Role | Limit that matters |
|---|---|---|
| Xbox Series S | GTA VI at ~1080p30 | 30 fps target; HDMI 2.1 out |
| Joyzzz capture card | HDMI -> USB UVC, 4K30 passthrough | Capture 1080p30 |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1, 3x USB-A 3.0, 100W PD | Plug into the Legion USB4 port |
| Legion Go S | AMD Z2 Go, Radeon 680M (12 CU), Bazzite | 3x/90 is the target; plugged in, performance TDP |
| Monitor | 1080p120 with VRR | 120 Hz + VRR, showing 90 fps |

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

Xbox VRR off is deliberate: the capture card needs a steady signal. The monitor's
VRR is on the Legion's output, not the Xbox's.

### Capture

1920x1080 @ 30, YUYV/NV12 if offered, otherwise MJPEG.

### Monitor

1920x1080 @ 120 Hz, **VRR on**, SDR, 100% scaling. Verify with
`kscreen-doctor -o`.

### VeyAmux

| Setting | Value |
|---|---|
| Source | capture card, 1920x1080 @ 30 |
| Upscaling | Off/1:1 if offered; otherwise 1.5x at most |
| Noise reduction | Spatial or Both, low/medium |
| Anti-flicker | On |
| Sharpness | light |
| Frame generation | **Fixed 3x** (Lossless Scaling) |
| Display | fullscreen, 120 Hz + VRR |
| HDR | off |

## What VeyAmux is not

- **Not a detail-recovery upscaler.** At 1080p -> 1080p it cleans and sharpens;
  the Xbox already did the internal upscale. 1.5x/2x/3x above 1080p is
  supersampling, which costs GPU and gets scaled back down.
- **Not 120 from 30.** 3x max. 90 is the goal here.
- **Not an Xbox Remote Play client.** VeyAmux's Remote Play option is
  PlayStation-only; the Xbox path is the capture card. The 720p/1080p demo
  buttons are not a capture mode.
- **Not a game mod.** It processes captured video, so there is no anti-cheat
  surface.
- **Not HDR.** Keep HDR off end to end.

## Verify

```bash
# display: 1920x1080 @ 120, VRR-capable
kscreen-doctor -o

# capture formats on the stable node
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
≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×) · signal 1920×1080 ...
```

Pass: the display is 120 Hz with VRR, the info line says 3x, and motion is even
while driving.

## Repo map

| File | What it is |
|---|---|
| `docs/01-signal-chain.md` | Hardware, cabling, capture formats, latency, why 3x/90. |
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
- lsfg-vk installation: https://lsfg-vk.dev/docs/installation/
- Bazzite framegen recipe: https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/share/ublue-os/just/87-bazzite-framegen.just
- GTA VI 30 fps target: https://www.glitched.online/gta-vi-targets-30fps-on-consoles-with-ps5-pro-ray-tracing-enhancements
