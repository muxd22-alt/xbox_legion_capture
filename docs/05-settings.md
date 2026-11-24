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
container is exactly what VeyAmux's duplicate removal expects. The Xbox cannot
output 30 Hz at all.

## Capture card

| Setting | Value |
|---|---|
| Resolution | 1920x1080 |
| Frame rate | **60** (30 is a fallback) |
| Format | YUYV/NV12 if offered at 1080p60, else MJPEG |
| Device path | `/dev/v4l/by-id/...`, not `/dev/videoN` |
| Audio | Card USB audio, stereo |

Capture **60**, not 30. VeyAmux removes the duplicate frames itself; a 30 Hz
capture decimates blindly and can alias the game's 17/50 ms pacing. Use 30 only
if 60 overloads USB or decode.

Keep the **Xbox at 1080p**. Do not set the console to 720p to help VeyAmux;
that throws away detail before capture. 720p is a fallback for the Legion's GPU,
not a default (see `01-signal-chain.md`).

## Monitor

| Setting | Value |
|---|---|
| Resolution | 1920x1080 |
| Refresh | **90 Hz fixed** |
| VRR / Adaptive Sync | **Off** |
| Scaling | 100% |
| HDR | Off |
| Picture mode | Game / Overdrive |

`lsfg-vk` 2 needs a fixed refresh. VeyAmux warns when Adaptive Sync is on. 90
fps on a fixed 120 Hz panel is 3:2 and judders.

**No 90 Hz mode?** Use **60 Hz fixed** and frame generation **2x**. A 120 Hz
fixed mode with 2x (60 fps) is also exact 2:1, but 60 Hz is simpler and usually
lower latency.

Verify with `kscreen-doctor -o`.

## TV path (Sunshine -> Fold 4)

This mode does **not** use the 90 Hz monitor profile. The panel is 1080p60 and
the Fold does the 4K.

| Setting | Value |
|---|---|
| Sunshine install | Bazzite Portal -> Sunshine -> Enable (Brew); flatpak cannot KMS |
| Capture | KMS |
| Encoder | VAAPI |
| Codec | **HEVC** (no AV1: the 680M cannot encode it) |
| Resolution / fps | 1920x1080 @ 60 |
| Bitrate | 50 Mbps (40-60 band) |
| HDR | Off |
| Network | Wired preferred, else 5 GHz on the 5G router |
| Moonlight V+ | arm64, 1080p60, HEVC, 50 Mbps, SGSR upscale to 3840x2160 |
| V+ frame generation | **Off** (VeyAmux already did 2x) |

## Native games

| Setting | Value |
|---|---|
| Decky | Installed in Desktop Mode, Developer mode on |
| Plugin | DeckyMultiFrameGen (GPL-3.0) |
| Backend | HelixSR **or** OptiScaler, never both |
| Model | AMD FSR **4.1.2 Lite** (OptiScaler path) or HLX DLSS/FSR 4 (HelixSR) |
| Proton | **Experimental** |
| Game option | the game's own DLSS / FSR 2+ / XeSS switch |
| Anti-cheat | never; single-player only |
| Output | 1080p60; 90 Hz only if the game holds it |

## Video playback (separate path)

| Setting | Value |
|---|---|
| Bazzite player | mpv + MPV Anime Build v5.6 |
| Tier | **Fast** (HQ/`*_CMP.glsl` is too heavy for 12 CU) |
| Power Guard | On (Eco on battery) |
| HDR | Off |
| Android | MpvRx v1.3.2 arm64, Anime4K, thermal auto-downgrade on |
| Alternative | mpvEx + Anime Build Android branch (not both) |
| Jellyfin | external player where the client allows it |

## VeyAmux

### Source

| Setting | Value |
|---|---|
| Source | Capture card |
| Resolution | 1920x1080 |
| Frame rate | **60** (30 fallback) |
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

| Setting | Monitor mode | TV mode |
|---|---|---|
| Method | Lossless Scaling | Lossless Scaling |
| Multiplier | **Fixed 3x** | **Fixed 2x** |
| Even out frame pacing | **On** (~+17 ms) | **On** |
| Status | "Active through lsfg-vk" | "Active through lsfg-vk" |
| Client frame gen | n/a | **Off in Moonlight V+** |

Do not use the free FSR 3.1.6 2x option for this goal; it is 2x, not 3x.

### Display

| Setting | Value |
|---|---|
| Fullscreen | Yes |
| Resolution | 1920x1080 |
| Refresh | 90 Hz fixed |
| VRR | Off (KDE and monitor OSD) |

## Expected numbers

| Stage | Value |
|---|---|
| Game simulation | 30 Hz |
| Xbox output / capture | 60 Hz, 60 fps |
| VeyAmux unique frames | 30 fps |
| Multiplier | 3x |
| Output | **90 fps** |
| Monitor | 90 Hz fixed, VRR off |
| End-to-end latency | roughly 90-150 ms |

TV path: 30 unique x 2 = 60, streamed as 1080p60 HEVC, upscaled by the Fold to
4K60. Native games: the game's own rate at 1080p60; no LSFG.

## Test matrix

Run in order, one change at a time.

| # | Test | Pass looks like |
|---|---|---|
| 1 | Xbox -> card passthrough -> monitor | 1080p60, no software, no lag |
| 2 | VeyAmux, frame gen off | Stable 30 unique fps, correct colours, audio works |
| 3 | VeyAmux, 3x, even pacing, cleanup light | 90 fps, even motion, status "Active through lsfg-vk" |
| 4 | Uncompressed 1080p60 capture if available | Cleaner image, less CPU, same 90 |
| 5 | 30 fps capture fallback | 90 fps, but watch for dropped real frames |
| 6 | Noise reduction low -> medium | Less MJPEG blocking, still 90 |
| 7 | Anti-flicker on | Calmer fences/foliage, still 90 |
| 8 | 2x instead of 3x at 60 Hz | 60 fps, lower latency, cleaner image |
| 9 | 1.5x upscale | Slightly different sharpness; note the GPU cost |
| 10 | 720p capture + 1.5x upscale | 90 if 1080p was too heavy; softer image |
| 11 | Sunshine KMS + VAAPI HEVC, 1080p60 50 Mbps | V+ shows 1080p60 HEVC near 50 Mbps, 4K panel |
| 12 | Xbox capture, TV mode, VeyAmux **2x** | Info line `30 -> 60`, no 90 in this mode |
| 13 | 10 min driving on the TV | No dropped frames, no audio drift, TV game mode on |
| 14 | Decky + DeckyMultiFrameGen + backends | Plugin lists OptiScaler and HelixSR; one per game |
| 15 | FSR 4.1.2 Lite in one DX12 game | Overlay + log + watermark agree; Proton Experimental |
| 16 | 10 min native game with FSR 4.1.2 Lite | Upscaler ms recorded; compare with game's FSR 2/3 |
| 17 | Native game streamed to the TV | 1080p60 HEVC, V+ SGSR, V+ frame gen off |
| 18 | mpv Anime Build, Fast, 1080p -> 4K | No dropped frames at the chosen tier |
| 19 | MpvRx on the Fold 4, 1080p -> 4K | Thermal downgrade behaves; no throttle crash |
| 20 | Rollback: Use -> Off | Game starts stock; launch options restored |

Record the result of each. Do not tune two things at once.

## Measurement log

Fill this in on the Legion. `UNTESTED` is a valid entry; an estimate is not.
Measure VeyAmux stage time with the F3 overlay in steady state, native upscaler
time with OptiScaler's overlay or the HelixSR log, and stream health with V+'s
stats overlay.

| Mode | Date | GPU ms (stage) | FPS | Bitrate | Drops | Feel (sentence) | Tool |
|---|---|---|---|---|---|---|---|
| Capture to monitor | UNTESTED | UNTESTED | UNTESTED | n/a | n/a | UNTESTED | VeyAmux F3 |
| Capture to TV | UNTESTED | UNTESTED | UNTESTED | UNTESTED | UNTESTED | UNTESTED | V+ stats |
| Native game | UNTESTED | UNTESTED | UNTESTED | n/a | n/a | UNTESTED | OptiScaler |
| Native game to TV | UNTESTED | UNTESTED | UNTESTED | UNTESTED | UNTESTED | UNTESTED | V+ stats |
| Video playback (mpv) | UNTESTED | UNTESTED | UNTESTED | n/a | UNTESTED | UNTESTED | `I` overlay |
| Video playback (MpvRx) | UNTESTED | UNTESTED | UNTESTED | n/a | UNTESTED | UNTESTED | app stats |

**SGSR vs ML on the 680M:** not applicable. There is no ML stage in any mode.
The ML fork is parked, not measured, and not part of this rig (`docs/10`).

## What 90 means

- The game still **simulates at 30 Hz**. You see 90 images, not 90 updates.
- Input latency gets **worse**, not better: 3x adds roughly one to two base
  frames (33-66 ms), plus capture and even-pacing latency.
- 3x has more artefacts than 2x, especially HUD text, foliage and fast pans.
- A fixed 90 Hz display is what makes the cadence even. VRR is not used here
  because lsfg needs a fixed refresh.

## Sanity checks

```bash
# display: fixed 90 Hz, adaptive sync off
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
≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×) · signal 1920×1080 @ 60 fps
```

If you use MangoHud, remember it can load above lsfg-vk and report 30 while
frame generation is working. Trust VeyAmux's info line, the F3 overlay and the
monitor OSD first.
