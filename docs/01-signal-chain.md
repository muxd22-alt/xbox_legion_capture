# Signal chain and hardware

## What this repo is for

Play GTA VI on an Xbox Series S at **1080p120 on a monitor**, using the Legion
Go S as a real-time frame-generation box:

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
Legion Go S  (Bazzite, mpv Vulkan + lsfg-vk 4x)
  | HDMI 2.1 from dock
  v
1080p120 monitor  (1920x1080 @ 120 Hz, SDR, 1:1)
```

No TV, no Xiaomi box, no Moonlight, no Sunshine, no network, no 4K.

## Hardware in hand

| Part | What it does | Limit that matters |
|---|---|---|
| Xbox Series S | Runs GTA VI at ~1080p30 | 30 fps target; HDMI 2.1 out |
| Joyzzz capture card | HDMI -> USB UVC, 4K30 passthrough, 1080p60 capture | Capture at **1080p30** for the 4x path |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1 4K120, 3x USB-A 3.0, 100 W PD | Plug into the Legion's **USB4** port |
| Legion Go S | AMD Z2 Go, Radeon 680M-class, Bazzite | 1080p120 with 4x is the stretch goal |
| Monitor | 1080p120 HDR | Run it **SDR, 120 Hz, 100% scaling** |

## The core math: 30 x 4 = 120

GTA VI is a 30 fps game. The Xbox outputs a 60 Hz signal, so every game frame
is sent twice. lsfg-vk has **no duplicate-frame removal** (that is a Veyra
feature). Therefore:

| Capture | lsfg multiplier | Output | Motion quality |
|---|---|---|---|
| **30 fps** | **4x** | **120** | Correct: 3 generated frames between each real frame |
| 60 fps | 2x | 120 | 120 images, but only 30 Hz of real motion (duplicates) |
| 60 fps | 4x | 240 | Too many frames; vsync drops them, bad pacing |

Capture at **30**, multiply by **4**. This is the whole trick.

lsfg-vk does **not** deduplicate or re-time the input. It generates
`multiplier - 1` frames per input frame and presents the result. So the output
only lands on 120 when the input is 30 fps **and** the display is actually
running at 120 Hz. If the display is at 60 Hz, you get 60 presented frames no
matter what the multiplier says.

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

## Path D: passthrough fallback

The card has an HDMI output. If you connect it straight to the monitor:

```
Xbox -> card HDMI IN -> card HDMI OUT -> monitor
```

you get 1080p60 with no software and no added latency. Use it to:

- prove the Xbox and cables are fine,
- compare 60 native vs 120 generated,
- keep playing if lsfg or mpv misbehaves.

The card's passthrough is rated 4K30; 1080p60 passes fine.

## What "upscaling" means here

- The **capture card does not upscale**. It captures 1080p30 and sends it over
  USB.
- The **Xbox does the internal upscaling**. Series S often renders GTA VI below
  1080p and hardware-upscales to a 1080p output. That is what you capture.
- The **monitor is 1080p**, so the correct output is 1:1. There is nothing to
  upscale. Running 1080p -> 1200p on the internal panel would only add scaling
  cost and soften the image.
- lsfg-vk is **frame generation only**. It is not an upscaler. A CAS/FSR shader
  in mpv can sharpen, but it costs the GPU headroom you need for 4x.

## Latency reality

| Stage | Typical |
|---|---|
| Capture (MJPEG 1080p30) | 20-40 ms |
| lsfg 4x | 33-66 ms (one to two 30 fps frames) |
| mpv present at 120 Hz | 8-16 ms |
| Monitor processing (game mode) | 5-15 ms |

Expect **80-140 ms** end to end. Fine for GTA VI, not for online shooters. The
controller stays paired to the Xbox, so controller latency is unchanged.
