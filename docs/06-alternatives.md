# Alternatives and upgrades

Only read this if the main path is not enough. The main path is
`02-bazzite-setup.md`.

## Veyra (Windows only) - not usable on Bazzite

- Repo: https://github.com/Likely7/Veyra-NRVideo
- Veyra 2.2.0, released 2026-11-20.
- Windows 11 x64 + DirectX 12 only. The demo host is an RTX 5090.
- It does capture -> dedupe -> frame gen -> upscale -> output in one app.
- If you add a Windows partition to the Legion, Veyra can do 60 -> 30 -> 4x with
  proper duplicate removal. That is cleaner than lsfg-vk for a 30 fps console.
- On the 680M, expect 1080p60, not 120. The video's 120 is an RTX 5090.

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

The Z2 Go / Radeon 680M can do:

- 1080p60 HEVC encode: yes.
- 1080p120 frame gen at 4x: maybe, scene-dependent.
- 1080p120 with 4x plus heavy capture decode: tight.
- AV1 encode: no.

There is no software trick that turns a 680M into a 5090. If 4x/120 does not
hold, 3x/90 with VRR is the honest fallback.

## HDR (later)

HDR needs an HDR capture card, an HDR-capable host path, an HDR client, and an
HDR display. The Joyzzz card is SDR. Keep HDR off.
