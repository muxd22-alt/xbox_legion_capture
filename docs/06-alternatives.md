# Alternatives and upgrades

Only read this if the main path is not enough. The main path is
`02-bazzite-setup.md`.

## Veyra (Windows only) - not usable on Bazzite

- Repo: https://github.com/Likely7/Veyra-NRVideo
- Veyra 2.2.0, released 2026-11-20.
- Windows 11 x64 + DirectX 12 only. The demo host is an RTX 5090.
- It does capture -> dedupe -> frame gen -> upscale -> output in one app.
- If you add a Windows partition to the Legion, Veyra can do 60 -> 30 -> 4x with
  proper duplicate removal. That is cleaner than lsfg-vk for a 30 fps console,
  but Veyra's full pipeline (dedupe + frame gen + upscale) is heavier than
  lsfg's frame gen alone. On the 680M, assume 1080p60 is realistic; 120 with
  the whole pipeline is not. The video's 120 is an RTX 5090.

## Desktop GPU

If you have a desktop with an RTX 40/50:

```
Xbox -> capture card -> desktop (Windows + Veyra) -> 1080p120 monitor
```

That is the best-quality version of this project. The Legion is not needed.

## Decky LSFG-VK plugin

- https://github.com/xXJSONDeruloXx/decky-lsfg-vk
- A Game Mode plugin that installs/configures lsfg-vk and manages per-game
  profiles.
- Not needed for this path: you run `mpv` in Desktop Mode with a single
  `active_in = "mpv"` profile.
- Useful if you later want frame gen in Steam games, not for the capture feed.

## Decky-Framegen / OptiScaler

- https://github.com/xXJSONDeruloXx/Decky-Framegen
- Injects OptiScaler (FSR/XeSS frame gen) into PC games.
- **Not relevant** to a console capture feed. It does not touch a UVC stream.

## OBS + VkCapture instead of mpv

- OBS can preview the capture card and lsfg-vk can hook the OBS Vulkan window.
- Heavier than mpv, more places to misconfigure, and OBS may force its own frame
  pacing.
- Use only if mpv cannot open the card or you need recording/overlay.

## Capture card upgrades

The Joyzzz card is likely MJPEG at 1080p. A card with **1080p60 YUYV/NV12** or a
better UVC implementation would reduce latency and artifacts. Look for:

- 1080p60 uncompressed over USB 3.0, not MJPEG.
- 4K60 passthrough (clean monitor path).
- UVC class-compliant, no driver.
- HDMI 2.0 input minimum.

Do not buy a "4K60 capture" stick at a low price; it is usually 4K30 or MJPEG.

## GPU reality

The Z2 Go has a **full Radeon 680M: 12 RDNA2 CUs, up to ~2.2 GHz**, with
LPDDR5X-6400 shared memory. It is not a cut-down 660M.

The useful data point is lsfg-vk 2.0's own benchmark on a 680M: **2x at
1280x800, 100% flow scale, FP16 on** took **3.30 ms per generated frame**
(302 base fps). Scale that to 1080p (2.03x the pixels) and 4x (3 generated
frames per input):

- ~6.7 ms per generated frame at 1080p
- ~20 ms per input frame at 4x, 100% flow, no performance mode
- budget at 30 fps input: 33.3 ms

So generation fits with room to spare, and `flow_scale = 0.5` plus performance
mode roughly halves it. The thing that can break 4x is not the model; it is
**TDP and clocks** (15 W vs 28-40 W) and, to a lesser degree, MJPEG decode
stealing CPU.

What the 680M can do here:

- 1080p30 MJPEG decode: yes, CPU or VCN.
- 1080p120 frame gen at 4x from a 30 fps base: **likely yes**, benchmark to
  confirm.
- 1080p120 frame gen at 4x from a 60 fps base: no, and it would be wrong
  anyway.
- AV1 encode: no. HEVC encode: yes.

There is no software trick that turns a 680M into a 5090, but this workload is
much lighter than gaming at 120 fps because the source is only 30 fps. If 4x
does not hold, fix TDP first, then try 3x/90 with VRR.

## HDR (later)

HDR needs an HDR capture card, an HDR-capable host path, an HDR client, and an
HDR display. The Joyzzz card is SDR. Keep HDR off.
