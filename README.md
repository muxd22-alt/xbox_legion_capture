# Xbox Series S -> Legion Go S -> 1080p120 monitor

Using a capture card and **lsfg-vk** to play a 30 fps console game at 120 fps on
a 1080p120 monitor.

```
Xbox Series S (1080p60 out, SDR)
  -> Joyzzz capture card (capture 1080p30)
  -> JSAUX dock -> Legion Go S (Bazzite)
  -> mpv (Vulkan) + lsfg-vk 4x
  -> 1920x1080 @ 120 Hz monitor (SDR, 1:1)
```

No TV, no Xiaomi box, no Moonlight, no Sunshine, no network, no 4K.

## The one number

**30 x 4 = 120.**

GTA VI is a 30 fps game. The Xbox sends 60 Hz with every frame duplicated.
lsfg-vk has no duplicate-frame removal, so:

- capture **30 fps** -> lsfg **4x** -> **120**. Correct.
- capture 60 -> lsfg 2x -> 120 images, but only 30 Hz of real motion. Wrong.
- capture 60 -> lsfg 4x -> 240, vsync drops frames. Wrong.

Capture at 30. Multiply by 4. Keep the monitor at 120 Hz.

## Quick start

1. **Xbox:** 1080p, 60 Hz, HDR off, VRR off, 8-bit, stereo audio.
2. **Monitor:** 1920x1080 @ 120 Hz, SDR, 100% scaling.
3. **Card:** verify `1920x1080 @ 30` with
   `v4l2-ctl -d /dev/video0 --list-formats-ext`.
4. **lsfg-vk:** Lossless Scaling on Steam (beta `lsfg-vk`), then
   `ujust get-lsfg install`; profile `mpv`, multiplier **4**, flow **0.5**,
   performance **on**, pacing **vsync**.
5. **mpv:** run `docs/02-bazzite-setup.md` step 6, confirm ~120 with MangoHud.

Full steps: `docs/02-bazzite-setup.md`.
Checklist: `docs/03-checklist.md`.

## Why this works (and what it is not)

- The game still **simulates at 30 Hz**. You get 120 images, not 120 updates.
- Input latency gets **worse**: 30 fps base + 4x adds roughly one to two base
  frames (33-66 ms), plus capture latency. Expect **80-140 ms** end to end.
- The controller stays paired to the **Xbox**. The Legion only receives video.
- 4x ghosts more than 2x, especially HUD text, foliage and fast pans.
- The Z2 Go is stronger than it looks for this job: the base is only 30 fps, so
  lsfg has ~33 ms per input frame. Measure with
  `lsfg-vk-cli benchmark -w 1920 -h 1080 -m 4 -f 0.5 -p` before assuming it
  cannot. If it falls short: 3x/90 with VRR, or 2x/60.
- Plug in and use a performance TDP. At 15 W the 680M clocks down and 4x can
  collapse; at 28-40 W it has room.

## Review of the answer you pasted

Verdict: **the tool identification is correct, the setup advice is incomplete.**
It names the right projects but does not tell you the one thing that decides
whether this works: the input must be **30 fps** and the display must actually
be **120 Hz**.

What it got right:

- `lsfg-vk` is the correct tool. It is a Vulkan implicit layer, so it hooks any
  Vulkan app, including `mpv` with `--gpu-api=vulkan`.
- Lossless Scaling must be owned on Steam and switched to the **`lsfg-vk`**
  branch; lsfg-vk loads `Lossless.dll` from it.
- `ujust get-lsfg` is the correct Bazzite install path (it installs V2 into
  `~/.local`).
- `decky-lsfg-vk` is optional and Game Mode oriented, so it is not needed here.
- `Decky-Framegen` / OptiScaler are for injecting FSR/XeSS into PC games. They
  do not touch a UVC capture stream, so they are irrelevant.
- Veyra is Windows 11 + DX12 only. Not usable on Bazzite.

What it got wrong or left out:

| Gap | Why it matters here |
|---|---|
| It does not mention the 30 -> 4x -> 120 math | `lsfg-vk` does not deduplicate. Capturing 60 and using 2x gives 120 images with 30 Hz of motion. |
| It says lsfg-vk is on `github.com/PancakeTAS/lsfg-vk` | That repo is archived and only points to **lsfg-vk.dev**. The docs, CLI and builds moved. |
| It does not mention `active_in` | The profile only activates for a matching binary. You need `active_in = "mpv"` (or `LSFGVK_PROFILE=...`). |
| It does not mention Flatpak | A Flatpak `mpv` cannot see a layer installed in `~/.local`. Use native mpv or install the layer into the runtime. |
| It does not mention the CLI checks | `lsfg-vk-cli validate`, `validate -p` and `healthcheck` are how you prove the config and install are sane. |
| It does not mention Wayland/fullscreen quirks | With `pacing_mode = "vsync"`, some Wayland fullscreen apps need a windowed test first. |
| It calls frame gen a free win | 4x adds ghosting and roughly one to two 30 fps frames of latency. It is not 120 Hz simulation. |

The corrected, step-by-step version is `docs/02-bazzite-setup.md`.

## Hardware

| Part | Role | Limit |
|---|---|---|
| Xbox Series S | GTA VI at ~1080p30 | 30 fps target |
| Joyzzz capture card | HDMI -> USB UVC, 4K30 passthrough | Capture 1080p30 for 4x |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1 4K120, 3x USB-A 3.0, 100 W PD | Use the Legion's USB4 port |
| Legion Go S | Z2 Go / 680M-class, Bazzite | 4x/120 likely; verify with the lsfg benchmark |
| Monitor | 1080p120 HDR | Run SDR, 120 Hz, 100% scaling |

Cabling:

1. Xbox HDMI -> card HDMI IN.
2. Card USB -> dock USB-A 3.0.
3. Dock USB-C -> Legion USB4.
4. Charger -> dock PD 100 W.
5. Dock HDMI -> monitor.
6. Optional: card HDMI OUT -> monitor, for the passthrough baseline.

## Settings summary

### Xbox

1080p, 60 Hz, HDR off, VRR off, 8-bit, Standard colour, stereo uncompressed.

### Capture

1920x1080 @ 30, MJPG (or YUYV if available at 30).

### lsfg-vk

Profile `mpv`, multiplier 4, flow 0.5, performance mode on, pacing vsync,
FP16 on. Config: `configs/lsfg-vk-120.toml`.

### mpv

`vo=gpu-next`, `gpu-api=vulkan`, `video-sync=desync`, `untimed`,
`framerate=30`, `--no-audio`. Config: `configs/mpv-lsfg.conf`.

### Monitor

1920x1080 @ 120 Hz, SDR, 100% scaling. Verify with `kscreen-doctor -o`.

### Optional post-processing

Not the OptiScaler/ReShade stack from PC-game guides: those hook a game's
renderer, and there is no game here. Use mpv's own shader chain instead, after
120 is stable. CAS 1.2 for sharpening, `deband=yes` for MJPEG banding. Details:
`docs/07-post-processing.md`.

## Verify

```bash
# 120 Hz display
kscreen-doctor -o

# 1080p30 capture
v4l2-ctl -d /dev/video0 --list-formats-ext

# lsfg installed and valid
ujust get-lsfg status
~/.local/bin/lsfg-vk-cli validate
ls ~/.local/share/vulkan/implicit_layer.d/ | grep -i lsfg

# 120 fps output
MANGOHUD=1 mpv av://v4l2:/dev/video0 --fs \
  --profile=low-latency --untimed --video-sync=desync \
  --demuxer-lavf-o=video_size=1920x1080,framerate=30,input_format=mjpeg \
  --vo=gpu-next --gpu-api=vulkan --hwdec=vaapi \
  --no-audio --no-osc --osd-level=0
```

## Repo map

| File | What it is |
|---|---|
| `docs/01-signal-chain.md` | Hardware, cabling, why 30 x 4, passthrough fallback, latency. |
| `docs/02-bazzite-setup.md` | Install lsfg-vk, configure it, run mpv, verify, tune, troubleshoot. |
| `docs/03-checklist.md` | Home-day checklist with pass/fail steps. |
| `docs/04-audio-controller.md` | Audio loopback and controller facts. |
| `docs/05-settings.md` | Xbox / capture / monitor / lsfg / mpv settings and test matrix. |
| `docs/06-alternatives.md` | Veyra, desktop GPU, Decky, OBS, capture card upgrades. |
| `docs/07-post-processing.md` | Safe mpv shader chain (CAS/FSR1/deband); why OptiScaler/ReShade do not apply. |
| `configs/lsfg-vk-120.toml` | lsfg-vk profile: multiplier 4, 1080p120. |
| `configs/mpv-lsfg.conf` | mpv config for 1080p30 -> 4x -> 120. |
| `scripts/check-capture.sh` | Lists V4L2 devices, formats and audio sources. |
| `scripts/check-lsfg.sh` | Checks display mode, lsfg install, config validity and the Vulkan layer. |
| `AGENT-PROMPT.md` | Copy-paste briefing for the agent at the machine. |

## Sources

- lsfg-vk docs: https://lsfg-vk.dev/docs/
- lsfg-vk installation: https://lsfg-vk.dev/docs/installation/
- lsfg-vk configuration: https://lsfg-vk.dev/docs/configuration/
- lsfg-vk configuration options: https://lsfg-vk.dev/docs/configuration/configuration-options/
- lsfg-vk pacing modes: https://lsfg-vk.dev/docs/configuration/pacing-modes/
- lsfg-vk CLI (validate/healthcheck): https://lsfg-vk.dev/docs/cli/validation/
- lsfg-vk troubleshooting: https://lsfg-vk.dev/docs/troubleshooting/basic-troubleshooting-steps/
- lsfg-vk 2.0 release notes: https://www.gamingonlinux.com/2026/09/lossless-scalings-frame-generation-for-linux-lsfg-vk-2-0-is-out-now
- Bazzite framegen recipe: https://github.com/ublue-os/bazzite/blob/main/system_files/desktop/shared/usr/share/ublue-os/just/87-bazzite-framegen.just
- decky-lsfg-vk: https://github.com/xXJSONDeruloXx/decky-lsfg-vk
- Veyra (Windows only): https://github.com/Likely7/Veyra-NRVideo
- GTA VI 30 fps target: https://www.glitched.online/gta-vi-targets-30fps-on-consoles-with-ps5-pro-ray-tracing-enhancements
