# Optional post-processing (safe, inside mpv)

Everything here is optional. Get 4x/120 stable first (`02-bazzite-setup.md`),
then add one thing at a time and re-measure.

## Why the OptiScaler / ReShade stack does not apply

That advice is for **PC games running under Proton**. Your Legion is not running
a game; it is showing a UVC video stream in `mpv`. There is no game engine, no
D3D device, no depth buffer and no motion vectors to hook.

| Tool | What it actually hooks | Why it cannot work here |
|---|---|---|
| OptiScaler | Replaces `nvngx_dlss.dll` / `dxgi.dll` in a game folder and intercepts the game's DLSS calls | `mpv` never calls DLSS and has no `dxgi.dll` |
| ReShade | Injects into a game's D3D/OpenGL/Vulkan device, often reading the game's depth buffer | No game device; depth-based effects have no depth input |
| DLSS Enabler | Drop-in bundle of OptiScaler + FSR frame gen + SSGI for game folders | Same problem: there is no game folder to drop it into |
| Gamescope FSR/NIS | Compositor-level upscaling of a game's swapchain | You are not running `mpv` inside Gamescope |
| FSR 4.1.2 Lite (driver or OptiScaler) | A game's FSR 3.1/4 calls, motion vectors, jitter and depth | No game on the Legion, and the Z2 Go is not on AMD's official list (Z2 Extreme and Z2 A are) |
| "DLSS 5 Linux ports" / leaked runtimes | Prebuilt closed binaries injected into Proton | Not applicable, and installing "leaked" runtimes is a malware and stability risk. Do not. |

`WINEDLLOVERRIDES="dxgi=n,b"` is a Proton game launch option. It does nothing
for `mpv`.

There is also a physics problem: DLSS/FSR 2+/XeSS are **temporal** upscalers.
They need motion vectors, jitter and depth from the game engine. A capture card
delivers a finished 2D image. No shader can reconstruct that data. Only
**spatial** filters (CAS, FSR 1, sharpen) are possible.

AMD's FSR 4.1.2 lightweight INT8 model (players call it "FSR 4.1.2 Lite") is in
the same category: it is a game-side ML upscaler, not a video filter. It also is
not officially supported on the **Z2 Go** in the Legion Go S. AMD's list covers
Ryzen AI 9 300/400, Ryzen AI Z2 Extreme, Z2 Extreme and Z2 A, plus the full
INT8 model on RX 6000/7000 and Ryzen AI Max. Z2 Go and the plain Z2 are absent.

## What is safe and useful

`mpv` has its own GLSL shader chain, running inside its Vulkan renderer. That
happens **before** `lsfg-vk` hooks the present call, so the two compose instead
of fighting. This is the correct place for "ReShade-like" effects here.

### CAS 1.2 — recommended

AMD FidelityFX Contrast Adaptive Sharpening, ported to mpv by agyild:

```
https://gist.github.com/agyild/bbb4e58298b2f86aa24da3032a0d2ee6
```

Download `CAS.glsl` to `~/.config/mpv/shaders/CAS.glsl`, then in `mpv.conf`:

```ini
glsl-shaders=~~/shaders/CAS.glsl
```

- Cheap, luma-only, designed for exactly this.
- Default `Sharpness` is mild. For a bit more, edit the `//!PARAM Sharpness`
  value in the file from `0.0` to about `0.2-0.4`. Higher also sharpens
  compression noise from MJPEG.
- At 1080p -> 1080p this is **sharpening only**. It cannot recover detail the
  Xbox or the card threw away.

### FSR 1 — only if you capture below 1080p

```
https://gist.github.com/agyild/82219c545228d70c5604f865ce0b0ce5
```

`FSR.glsl` is EASU (spatial upscale) + RCAS (sharpen). At 1:1 the EASU pass
does not run, so it behaves like RCAS. It is worth it only if you drop the
capture to 1600x900 or 1280x720 to save GPU for 4x:

```ini
glsl-shaders=~~/shaders/FSR.glsl
```

### Deband and colour — nearly free

MJPEG and cheap capture chains band badly in skies and fog:

```ini
deband=yes
deband-iterations=2
deband-threshold=35
```

Colour is a plain GPU multiply, no shader needed:

```ini
# defaults are 0 / 1 / 1; nudge to taste
contrast=0
saturation=1.05
gamma=0
```

### Scaling

If you capture at 900p and output 1080p, pick a better scaler than bilinear:

```ini
scale=ewa_lanczossharp
dscale=mitchell
```

`bilinear` is correct and cheapest for true 1:1.

## Do not stack Vulkan layers

`vkBasalt` and ReShade-as-a-layer also hook the present chain. `lsfg-vk` needs
that chain to itself for pacing. The official troubleshooting guide says to
disable other Vulkan layers when frame generation misbehaves, and MangoHud is
one of them. Keep post-processing inside mpv's shader chain, not as a layer.

## Budget

Every shader costs GPU time that 4x needs. On the 680M, CAS at 1080p is
roughly a fraction of a millisecond per frame, but it is not zero. Order:

1. Get 4x/120 stable with no shaders.
2. Add `deband=yes` (cheapest).
3. Add CAS.
4. Only then consider FSR 1 or more colour tweaks.

If fps drops below 120, remove shaders before lowering the multiplier.

## Verify

```bash
# shader compile errors show up here
mpv av://v4l2:/dev/v4l/by-id/<card>-video-index0 --fs --msg-level=all=warn ...

# optional fps check (MangoHud may load above lsfg-vk and under-report)
MANGOHUD=1 mpv ...
```

Pass: no shader compile errors, still ~120 fps, text is sharper rather than
haloed. If the CAS shader fails to compile, your mpv/libplacebo is older than
the 2026-11 revision; use the earlier revision in the gist's history.

## Safety

These are plain GLSL text files in `~/.config/mpv/shaders/`. No system
changes, no DLL injection, no network, no anti-cheat exposure. To undo, comment
out the `glsl-shaders` line. Only download shaders from the linked gists or
official AMD FidelityFX ports, never a random prebuilt binary.
