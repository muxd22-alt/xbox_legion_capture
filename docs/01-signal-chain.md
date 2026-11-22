# Signal chain and hardware

## What this repo is for

Play GTA VI from an Xbox Series S at **90 fps on a 1080p monitor**, using the
Legion Go S as a capture-and-frame-generation box running **VeyAmux**.

```
Xbox Series S  (1080p60 output, SDR)
  | HDMI
  v
Joyzzz capture card  (capture 1920x1080 @ 30 fps)
  | USB 3.0
  v
JSAUX 6-in-1 dock  (USB-A 3.0)
  | USB-C upstream -> Legion USB4 port
  v
Legion Go S  (Bazzite, VeyAmux + lsfg-vk 3x)
  | HDMI 2.1 from dock
  v
1080p120 monitor  (120 Hz + VRR, showing 90 fps)
```

## Hardware in hand

| Part | What it does | Limit that matters |
|---|---|---|
| Xbox Series S | Runs GTA VI at ~1080p30 | 30 fps target; HDMI 2.1 out |
| Joyzzz capture card | HDMI -> USB UVC, 4K30 passthrough, 1080p60 capture | Capture at **1080p30** |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1 4K120, 3x USB-A 3.0, 100 W PD | Plug into the Legion's **USB4** port |
| Legion Go S | AMD Z2 Go, Radeon 680M (12 CU), Bazzite | 3x/90 with VRR; use a performance TDP |
| Monitor | 1080p120 with VRR | 120 Hz + VRR, showing 90 fps |

## The core math: 30 x 3 = 90

GTA VI is a 30 fps game. The Xbox outputs a 60 Hz signal, so every game frame
is sent twice. VeyAmux compares whole frames, drops the repeats, and then asks
Lossless Scaling / `lsfg-vk` for **3x** on the 30 unique frames per second.

| Capture | VeyAmux frame gen | Output | Result |
|---|---|---|---|
| **30 fps** | **3x** | **90** | Correct: 2 generated frames between each real frame |
| 60 fps | 2x | 120 images | Only 30 Hz of real motion unless duplicates are removed |
| 60 fps | 3x | 180 | More than the panel shows; uneven |

VeyAmux's duplicate removal means a 60 fps capture is usable, but feeding it a
clean 30 fps stream is the simplest path.

90 is an exact multiple of 30, so the cadence is even. Your monitor runs
**120 Hz with VRR**, which lets it present 90 fps without 3:2 judder. Without
VRR, 90 on a fixed 120 Hz panel would look uneven.

120 fps would need 4x. VeyAmux does not expose 4x, so 90 is the target.

## Cabling

1. Xbox HDMI OUT -> capture card **HDMI IN**.
2. Capture card USB -> any **USB-A 3.0** port on the JSAUX dock.
3. Dock USB-C upstream -> Legion **USB4** port (not the plain USB-C 3.2 port).
4. Legion charger -> dock **PD 100 W** input.
5. Dock HDMI -> monitor.
6. Optional: capture card **HDMI OUT** -> monitor, for the zero-software
   passthrough comparison.

Do not put a USB 2.0 hub between the card and the dock. 1080p MJPEG needs the
USB 3.0 bandwidth.

## Capture format

Use the stable by-id node; UVC cards often expose a metadata node and the
numbering can swap between boots:

```bash
ls -l /dev/v4l/by-id/
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext
```

- Need `1920x1080` at `30` fps.
- Prefer **YUYV/NV12** if the card offers it at 1080p30. At 30 fps that is
  about 124 MB/s, which fits USB 3.0, and it removes MJPEG blocking plus decode
  latency.
- **MJPEG** is the usual fallback. VeyAmux warns when an uncompressed mode
  exists but MJPEG is selected.

## What "upscaling" means here

- The **capture card does not upscale**. It captures 1080p30 and sends it over
  USB.
- The **Xbox does the internal upscaling**. Series S often renders GTA VI below
  1080p and hardware-upscales to a 1080p output. That is what you capture.
- The **monitor is 1080p**, so the correct output is 1:1. There is no missing
  detail for VeyAmux to reconstruct.
- VeyAmux's upscalers (SGSR, FSR 1, NIS, FSR 3.1.6) are for 1.5x/2x/3x. Above
  1:1 they supersample and scale back down, which costs GPU. At 1:1 the useful
  work is **noise reduction, anti-flicker and sharpening**, not enlargement.
- VeyAmux is frame generation plus cleanup. It is not a detail-recovery model.

## 1080p or 720p?

Keep the Xbox at **1080p** and capture **1080p30**.

- The card can do 1080p30, so resolution is not the bottleneck.
- The Xbox's hardware upscaler is better than reconstructing a 720p capture in
  software.
- HUD text, the minimap and fine geometry stay sharp.
- 3x/90 from a 30 fps base is within the 680M's budget. Measure before
  downgrading.

720p is a **fallback**, not the default. If 90 will not hold:

1. Drop the cleanup cost first: upscaling off, noise reduction low,
   anti-aliasing off.
2. Then capture 1600x900 or 1280x720 and let VeyAmux upscale.
3. 720p -> 1080p is exactly **1.5x**, which SGSR, FSR 1 and NIS handle cleanly,
   and 3x at 720p is much cheaper than 3x at 1080p.
4. Accept the softer image. No upscaler recovers detail that was never
   captured.

Do **not** set the Xbox to 720p just to help VeyAmux. That throws away detail
before the capture, and some games also reduce their internal render resolution
when the output is lowered.

### 30 or 60 fps capture?

If the card offers 1080p60, capturing 60 and letting VeyAmux remove duplicates
can deliver each unique frame slightly sooner (one 60 Hz interval instead of one
30 Hz interval), at the cost of more USB bandwidth and decode. Try both; 30 is
simpler, 60 may shave a few milliseconds.

## Remote Play is PlayStation-only

VeyAmux's **PlayStation Remote Play** uses the chiaki-ng protocol and supports
**PS5/PS4 only**. It cannot connect to an Xbox. The Xbox path is the capture
card.

The **720p/1080p at 30/60 buttons on the start screen are the built-in demo**
(Abyssal Garden), not your console. Use them to test the Legion's upscaling and
frame-generation headroom; they are not a capture mode.

## Latency reality

| Stage | Typical |
|---|---|
| Capture (1080p30, MJPEG) | 20-40 ms |
| VeyAmux processing + 3x | 33-66 ms (one to two 30 fps frames) |
| Display at 120 Hz + VRR | 5-15 ms |

Expect roughly **80-140 ms** end to end. That is fine for GTA VI and not fine
for online shooters. VeyAmux's F3 overlay reports its own delay; measure it
rather than guessing.

The controller stays paired to the Xbox, so controller latency is unchanged.
Frame generation adds display latency, not input latency.
