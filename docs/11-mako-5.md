# 11 - MAKO 5.0 (checked, parked)

Status: **evaluated 2026-11-24, not installed, not part of any mode.**

MAKO is a free, open-source frame-generation / scaling Vulkan layer for Linux
and SteamOS. It is not a VeyAmux integration and it is not a drop-in replacement
for the capture path in this repo.

## What MAKO 5.0 is

| Piece | What it does |
|---|---|
| **MAKO Decky v5.0.0** | Decky Loader plugin: per-game profiles, install/update of the Renderer, launch integration |
| **MAKO Renderer v5.0.0** | The Vulkan layer: MAKO FG, MAKO Scaler, bundled shaders |
| **MAKO FG** | Open-weight frame generation, Fixed/Adaptive, 2x-5x, SDR/HDR, flow scale |
| **MAKO Scaler** | Open spatial scaler; optional LS1 models need your own Lossless Scaling |
| **Shaders** | Bundled vkBasalt effects |

- Project: <https://github.com/eugeniosegala/MAKO>
- Releases: <https://github.com/eugeniosegala/MAKO/releases>
- License: **GPL-3.0-or-later** (MAKO FG / Scaler / shaders do not need Lossless
  Scaling; optional LSFG/LS1 models read a licensed Lossless Scaling install).
- Platform: x86_64 Linux, developed and tested on AMD RADV (Steam Deck, RDNA2).
  Legion Go S + Bazzite is not an officially tested combination.

## Why it is not a drop-in for VeyAmux

1. **VeyAmux owns duplicate removal.** A 30 fps game in a 60 Hz capture arrives
   with every picture twice. VeyAmux removes the repeats and feeds the unique
   30 fps pictures to lsfg-vk. MAKO hooks the application's Vulkan swapchain from
   the outside; it cannot see VeyAmux's dedupe. If VeyAmux frame generation is
   off, the app presents 60 Hz frames including duplicates and MAKO would
   generate between duplicates.
2. **Only one frame-generation layer.** lsfg-vk (VeyAmux) and MAKO must not both
   be active. The capture path is already "Active through lsfg-vk".
3. **The locked architecture uses frame generation once**, on the Legion, only
   in capture mode. Native games use upscalers (HelixSR / OptiScaler), not a
   second frame-generation layer.

This is also why `docs/07-native-games.md` says **leave MAKO and ANR FG off**.

## If it is tested later

MAKO Decky is the easy path on a Decky machine:

1. Game Mode -> Decky -> Settings -> Developer mode.
2. Developer -> **Install Plugin from Zip** -> `MAKO-Decky-v5.0.0.zip`.
3. Open **MAKO Decky** -> **Install MAKO Renderer**.
4. Pick **one** native single-player game. Add the launch option shown by MAKO
   (`~/.local/bin/mako-launch %command%` for the standalone Renderer; use the
   exact path MAKO prints) and start the game from Steam.
5. Start with **Fixed 2x**, MAKO Scaler off. Compare 3x only after recording 2x.
6. Do **not** run it with VeyAmux/lsfg-vk, and do not stack it with ANR FG.

Record: model, multiplier, GPU ms, FPS, ghosting/HUD artefacts, input delay, and
whether it beat the game's own FSR/DLSS path. Untested is a valid result.

## Hardware notes

- MAKO's Decky paths in upstream docs are `/home/deck`; this machine is
  `/home/muxd`. Prefer the standalone Renderer on Bazzite if Decky paths need
  editing.
- The standalone Renderer is a Vulkan layer plus a `mako-launch` wrapper. It is
  user-space and reversible; it is not installed here.
- A capture-card viewer is a Vulkan app, but the duplicate-frame problem above
  makes MAKO unsuitable for the Xbox capture feed without VeyAmux-side dedupe.
- Free for non-commercial use; GPL-3.0-or-later.

## Verdict

**Parked.** Use VeyAmux + lsfg-vk for the Xbox capture path and HelixSR or
OptiScaler for native games. Revisit MAKO only as a separate native-game
frame-generation experiment, with one layer and measured numbers.
