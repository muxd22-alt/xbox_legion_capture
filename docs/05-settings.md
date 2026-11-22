# Settings reference

## Xbox Series S

| Setting | Value |
|---|---|
| Resolution | 1080p |
| Refresh rate | 60 Hz |
| Allow 4K | Off |
| HDR10 | Off |
| Dolby Vision | Off |
| VRR | Off |
| Colour depth | 8-bit |
| Colour space | Standard (test PC RGB if blacks crush) |
| HDMI audio | Stereo uncompressed |
| GTA VI mode | 30 fps / quality (there is no 60 fps mode on Series S) |

Why 60 Hz and not 120: the card captures 60 max, and a 30 fps game in a 60 Hz
container is exactly what 30 -> 4x wants. A 120 Hz Xbox output would just be
downsampled by the card.

## Capture card

| Setting | Value |
|---|---|
| Resolution | 1920x1080 |
| Frame rate | **30** (for 4x) |
| Format | YUYV/NV12 if offered at 1080p30, else MJPEG |
| Audio | Card USB audio, stereo |

If only 60 fps is available at 1080p, use `--vf=fps=30:round=near` in mpv.

## Monitor

| Setting | Value |
|---|---|
| Resolution | 1920x1080 |
| Refresh | **120 Hz** |
| Scaling | 100% |
| HDR | Off |
| Adaptive sync | Off first; on if you fall back to 3x/90 |
| Picture mode | Game / Overdrive |

Verify with `kscreen-doctor -o`.

## lsfg-vk

| Setting | Value |
|---|---|
| Profile name | `mpv 4x 1080p120` |
| Active in | `mpv` |
| Multiplier | **4** |
| Flow scale | **0.50** start; up to 0.75 if stable |
| Performance mode | **On** |
| Pacing mode | **Vsync** |
| Allow FP16 | **On** |

`4x` means: for every real frame, generate 3 more. At 30 fps base, output is
120.

## mpv

| Option | Value |
|---|---|
| `vo` | `gpu-next` |
| `gpu-api` | `vulkan` |
| `hwdec` | `vaapi` (try `no` if black screen) |
| `profile` | `low-latency` |
| `untimed` | yes |
| `video-sync` | `desync` |
| `audio` | no (route separately) |
| `framerate` | 30 |
| `input_format` | `mjpeg` or `yuyv422` |
| `fs` | yes |

Full file: `../configs/mpv-lsfg.conf`.

## Test matrix

Run in order, one change at a time.

| # | Test | Pass looks like |
|---|---|---|
| 0 | `lsfg-vk-cli benchmark -w 1920 -h 1080 -m 4 -f 0.5 -p` | Base FPS well above 30 (ideally 50+) |
| 1 | Xbox -> card passthrough -> monitor | 1080p60, no software, no lag |
| 2 | Card USB -> Legion, mpv no lsfg | Stable 30 fps, correct colours |
| 3 | mpv + lsfg 4x, flow 0.5, perf on | ~120 fps, playable |
| 4 | Flow 0.65 / 0.75 | ~120 fps, less ghosting |
| 5 | lsfg 3x | ~90 fps, fewer artifacts |
| 6 | lsfg 2x + monitor 60 Hz | ~60 fps, cleanest image |
| 7 | 1600x900 capture + 4x | ~120 fps if 1080p was too heavy |

Test 0 takes 10 seconds and tells you whether 4x is viable before you spend an
evening tuning. Run it plugged in, on the performance TDP profile.

Record the result of each. Do not tune two things at once.

## What 120 means

- The game still **simulates at 30 Hz**. You see 120 images, not 120 updates.
- Input latency gets **worse**, not better: 30 fps base + 4x adds roughly one to
  two base frames (33-66 ms) plus capture latency.
- Expect **80-140 ms** end to end. Fine for GTA VI, not for shooters.
- 4x ghosts more than 2x, especially HUD text, foliage and fast pans.

## Sanity checks

```bash
# display mode
kscreen-doctor -o | grep -E '1920x1080|120'

# capture formats
v4l2-ctl -d /dev/video0 --list-formats-ext

# lsfg config
~/.local/bin/lsfg-vk-cli validate
~/.local/bin/lsfg-vk-cli validate -p
~/.local/bin/lsfg-vk-cli healthcheck

# can this GPU do 1080p 4x? (Base FPS should be well above 30)
~/.local/bin/lsfg-vk-cli benchmark -w 1920 -h 1080 -m 4 -f 0.5 -p -t 10

# Vulkan layer
ls ~/.local/share/vulkan/implicit_layer.d/ | grep -i lsfg

# fps
MANGOHUD=1 mpv av://v4l2:/dev/video0 --fs ...
```
