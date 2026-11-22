# Signal chain and hardware

## What this repo is for

Play GTA VI from an Xbox Series S at **90 fps on a 1080p monitor**, using the
Legion Go S as a capture-and-frame-generation box running **VeyAmux**.

```
Xbox Series S  (1080p60 output, SDR)
  | HDMI
  v
Joyzzz capture card  (capture 1920x1080 @ 60)
  | USB 3.0
  v
JSAUX 6-in-1 dock  (USB-A 3.0)
  | USB-C upstream -> Legion USB4 port
  v
Legion Go S  (Bazzite, VeyAmux + lsfg-vk 3x)
  | HDMI 2.1 from dock
  v
1080p monitor  (fixed 90 Hz, VRR off)
```

## Hardware in hand

| Part | What it does | Limit that matters |
|---|---|---|
| Xbox Series S | Runs GTA VI at ~1080p30 | 30 fps target; only 60/120 Hz output |
| Joyzzz capture card | HDMI -> USB UVC, 4K30 passthrough, 1080p60 capture | Capture at **1080p60** |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1 4K120, 3x USB-A 3.0, 100 W PD | Plug into the Legion's **USB4** port |
| Legion Go S | AMD Z2 Go, Radeon 680M (12 CU), Bazzite | 3x/90; use a performance TDP |
| Monitor | 1080p with a 90 Hz mode | Fixed 90 Hz, VRR off |

## The core math: 30 unique x 3 = 90

GTA VI is a 30 fps game. The Xbox cannot output 30 Hz, so it sends a 60 Hz
signal with every picture twice. VeyAmux compares whole frames, drops the
repeats, and then asks Lossless Scaling / `lsfg-vk` for **3x** on the 30 unique
frames per second.

| Capture | VeyAmux | Output | Result |
|---|---|---|---|
| **60 fps** | dedupe -> 30, then **3x** | **90** | Correct and robust |
| 30 fps | 30, then 3x | 90 | Works, but can alias real frames |
| 60 fps | 2x without dedupe | 120 | Wrong: only 30 Hz of real motion |

## Why capture 60, not 30

- The 60 Hz signal contains all the information. Capturing 60 lets VeyAmux
  decide which frames are duplicates by comparing the whole picture.
- A 30 Hz capture decimates blindly. If the game's pictures arrive 17/50 ms
  apart instead of 33/33, a 30 Hz sampling clock can drop a real frame and keep
  a duplicate.
- 60 capture also delivers each new picture one 60 Hz interval sooner, which
  can reduce latency slightly.
- Cost: more USB bandwidth and more decode. Use 30 only if 60 overloads the
  link or the CPU.

At 1080p60, YUYV is about 248 MB/s. USB 3.0 can carry it, but many budget cards
only expose MJPEG at 1080p60. MJPEG is fine; VeyAmux warns when an uncompressed
mode exists.

## Display: fixed 90 Hz, VRR off

`lsfg-vk` 2 needs a **fixed refresh** to space generated frames evenly.
VeyAmux warns when Adaptive Sync is on, and its own docs say to turn VRR off for
VeyAmux.

- KDE: Display & Monitor -> **Adaptive sync: Never**.
- Monitor OSD: Adaptive Sync / FreeSync / G-Sync -> **off**.
- Set the display to the output rate: **1920x1080 @ 90 Hz** for 3x.

| Display mode | Frame gen | Output | Even? |
|---|---|---|---|
| **90 Hz fixed, VRR off** | **3x** | **90** | **Yes - target** |
| 120 Hz fixed, VRR off | 3x | 90 | No: 3:2 judder |
| 120 Hz + VRR | 3x | 90 | Not with lsfg; VRR must be off |
| 60 Hz fixed, VRR off | 2x | 60 | Yes - fallback |
| 120 Hz fixed, VRR off | 2x | 60 | Yes, exact 2:1 |

If `kscreen-doctor -o` lists no 90 Hz mode, do not run 3x on 120 Hz. Use
**Fixed 2x at a fixed 60 Hz** and target a clean 60.

## Cabling

1. Xbox HDMI OUT -> capture card **HDMI IN**.
2. Capture card USB -> any **USB-A 3.0** port on the JSAUX dock.
3. Dock USB-C upstream -> Legion **USB4** port (not the plain USB-C 3.2 port).
4. Legion charger -> dock **PD 100 W** input.
5. Dock HDMI -> monitor.
6. Optional: capture card **HDMI OUT** -> monitor, for the zero-software
   passthrough comparison.

Do not put a USB 2.0 hub between the card and the dock. 1080p60 needs the USB
3.0 bandwidth.

## Capture format

Use the stable by-id node; UVC cards often expose a metadata node and the
numbering can swap between boots:

```bash
ls -l /dev/v4l/by-id/
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext
```

- Need `1920x1080` at **60** fps. `30` is an acceptable fallback.
- Prefer **YUYV/NV12** at 60 if the card lists it.
- **MJPEG** is the usual mode at 1080p60 and is fine.
- Do not select a 30 fps mode just because the game is 30 fps. VeyAmux removes
  the duplicates from 60.

## 1080p or 720p?

Keep the Xbox at **1080p** and capture **1080p60**.

- The card can do 1080p60, so resolution is not the bottleneck.
- The Xbox's hardware upscaler is better than reconstructing a 720p capture in
  software.
- HUD text, the minimap and fine geometry stay sharp.
- 3x/90 from 30 unique frames is within the 680M's budget. Measure before
  downgrading.

720p is a **fallback**, not the default. If 90 will not hold:

1. Drop the cleanup cost first: upscaling off, noise reduction low,
   anti-aliasing off.
2. Then capture 1600x900 or 1280x720 and let VeyAmux upscale.
3. 720p -> 1080p is exactly **1.5x**, which SGSR, FSR 1 and NIS handle cleanly,
   and 3x at 720p is much cheaper than at 1080p.
4. Accept the softer image. No upscaler recovers detail that was never
   captured.

Do **not** set the Xbox to 720p just to help VeyAmux. That throws away detail
before the capture, and some games also reduce their internal render resolution
when the output is lowered.

## Remote Play is PlayStation-only

VeyAmux's **PlayStation Remote Play** uses the chiaki-ng protocol and supports
**PS5/PS4 only**. It cannot connect to an Xbox. The Xbox path is the capture
card.

The **720p/1080p at 30/60 buttons on the start screen are the built-in demo**
(Abyssal Garden), not your console. Use them to test the Legion's upscaling and
frame-generation headroom; they are not a capture mode.

## What "upscaling" means here

- The **capture card does not upscale**. It captures and sends the signal.
- The **Xbox does the internal upscaling**. Series S often renders GTA VI below
  1080p and hardware-upscales to a 1080p output. That is what you capture.
- The **monitor is 1080p**, so the correct output is 1:1. There is no missing
  detail for VeyAmux to reconstruct.
- VeyAmux's upscalers (SGSR, FSR 1, NIS, FSR 3.1.6) are for 1.5x/2x/3x. Above
  1:1 they supersample and scale back down, which costs GPU. At 1:1 the useful
  work is **noise reduction, anti-flicker and sharpening**.
- VeyAmux is frame generation plus cleanup. It is not a detail-recovery model.

## Latency reality

| Stage | Typical |
|---|---|
| Capture (1080p60, MJPEG) | 15-35 ms |
| VeyAmux dedupe + 3x | 33-66 ms |
| Even out frame pacing | +17 ms at 60 Hz |
| Display at 90 Hz | 5-15 ms |

Expect roughly **90-150 ms** end to end. Fine for GTA VI, not for online
shooters. VeyAmux's F3 overlay reports its own delay; measure it rather than
guessing.

The controller stays paired to the Xbox, so controller latency is unchanged.
Frame generation adds display latency, not input latency.
