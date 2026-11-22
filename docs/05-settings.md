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
| GTA VI mode | 30 fps / quality (no 60 fps mode on Series S) |

Why 60 Hz and not 120: the card captures 60 max, and a 30 fps game in a 60 Hz
container is exactly what VeyAmux's duplicate removal expects. A 120 Hz Xbox
output would just be downsampled by the card.

## Capture card

| Setting | Value |
|---|---|
| Resolution | 1920x1080 |
| Frame rate | **30** |
| Format | YUYV/NV12 if offered at 1080p30, else MJPEG |
| Device path | `/dev/v4l/by-id/...`, not `/dev/videoN` |
| Audio | Card USB audio, stereo |

## Monitor

| Setting | Value |
|---|---|
| Resolution | 1920x1080 |
| Refresh | **120 Hz** |
| VRR / Adaptive Sync | **On** |
| Scaling | 100% |
| HDR | Off |
| Picture mode | Game / Overdrive |

90 fps is presented evenly because VRR lets the panel follow it. Without VRR,
90 on a fixed 120 Hz panel judders 3:2.

Verify with `kscreen-doctor -o`.

## VeyAmux

### Source

| Setting | Value |
|---|---|
| Source | Capture card |
| Resolution | 1920x1080 |
| Frame rate | 30 (60 if that is all the card offers) |
| Format | YUYV/NV12 preferred, MJPEG fallback |
| Audio input | Card USB audio |
| Audio output | Speakers / headphones |

### Picture

| Setting | Value |
|---|---|
| Upscaling | Off/1:1 if offered, else 1.5x max |
| Noise reduction | Spatial or Both, low/medium |
| Anti-flicker | On |
| Sharpness | Light |
| Anti-aliasing | Off or SMAA light |
| FSR 3.1.6 | Off; Native AA only as an experiment |
| Texture / clarity / dehaze | 0 first, then small amounts |
| HDR | Off |

At 1080p -> 1080p there is no enlargement to do. Cleanup is the point.

### Frame generation

| Setting | Value |
|---|---|
| Method | Lossless Scaling |
| Multiplier | **Fixed 3x** |
| Status | "Active through lsfg-vk" |
| Even out frame pacing | On if offered (costs ~one refresh) |

Do not use the free FSR 3.1.6 2x option for this goal; it is 2x, not 3x.

### Display

| Setting | Value |
|---|---|
| Fullscreen | Yes |
| Resolution | 1920x1080 |
| Refresh | 120 Hz |
| VRR | On (KDE + monitor OSD) |

## Expected numbers

| Stage | Value |
|---|---|
| Game simulation | 30 Hz |
| VeyAmux input | 30 fps |
| Multiplier | 3x |
| Output | **90 fps** |
| Monitor | 120 Hz + VRR |
| End-to-end latency | roughly 80-140 ms |

## Test matrix

Run in order, one change at a time.

| # | Test | Pass looks like |
|---|---|---|
| 1 | Xbox -> card passthrough -> monitor | 1080p60, no software, no lag |
| 2 | VeyAmux, frame gen off | Stable 30 fps, correct colours, audio works |
| 3 | VeyAmux, 3x, cleanup light | 90 fps, even motion, status "Active through lsfg-vk" |
| 4 | Uncompressed capture if available | Cleaner image, less CPU, same 90 |
| 5 | Noise reduction low -> medium | Less MJPEG blocking, still 90 |
| 6 | Anti-flicker on | Calmer fences/foliage, still 90 |
| 7 | 2x instead of 3x | 60 fps, lower latency, cleaner image |
| 8 | 1.5x upscale | Slightly different sharpness; note the GPU cost |

Record the result of each. Do not tune two things at once.

## What 90 means

- The game still **simulates at 30 Hz**. You see 90 images, not 90 updates.
- Input latency gets **worse**, not better: 3x adds roughly one to two base
  frames (33-66 ms) plus capture latency.
- 3x has more artefacts than 2x, especially HUD text, foliage and fast pans.
- VRR hides the uneven cadence that 90 would otherwise show on a 120 Hz panel.
  It does not remove frame-generation artefacts.

## Sanity checks

```bash
# display: 120 Hz + VRR
kscreen-doctor -o

# capture on the stable node
ls -l /dev/v4l/by-id/
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext

# lsfg-vk
ujust get-lsfg status
~/.local/bin/lsfg-vk-cli healthcheck
~/.local/bin/lsfg-vk-cli validate

# VeyAmux log
tail -n 50 ~/.config/VeyAmux/lsfg-vk.log
```

VeyAmux's info line is the primary check:

```
≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×) · signal 1920×1080 ...
```

If you use MangoHud, remember it can load above lsfg-vk and report 30 while
frame generation is working. Trust VeyAmux's info line, the F3 overlay and the
monitor OSD first.
