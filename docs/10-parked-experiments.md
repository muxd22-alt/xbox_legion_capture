# 10 - Parked experiments (not in any mode)

These were considered and are **deliberately not used**. They stay documented so
nobody re-opens them by accident.

## ML upscale stage in VeyAmux (the fork)

A fork of VeyAmux with a small spatial CNN (ArtCNN C4F16) as
`Upscaler::MlCnn = 4` was scoped and a draft PR exists:

- PR: https://github.com/muxd22-alt/VeyAmux/pull/1
- Branch: `feature/ml-upscale` in `muxd22-alt/VeyAmux`
- Status: **experimental, not used, not measured, not merged**

Why it is parked:

1. **No output enlargement in the locked paths.** The Xbox feed is 1080p and the
   monitor is 1080p. At 1080p -> 1080p a spatial CNN cleans and sharpens; it does
   not add detail. The SGSR path already does the cleaning for less GPU time.
2. **The TV path does not need it.** The stream is 1080p60 by design, and the
   Fold 4 upscales to 4K with V+ SGSR. Adding a CNN on the Legion before encode
   would spend GPU time on pixels that are about to be compressed and upscaled
   again.
3. **It cannot compete on budget.** The 680M has no matrix cores. ArtCNN is
   plain compute: roughly 7k MACs per output pixel across 4 layers. The scoped
   budget was 6 ms at 1080p -> 1080p and 10 ms at 1080p -> 2160p; that is not a
   safe assumption on 12 CUs and was never measured.
4. **Maintenance.** A private fork would need its own AppImage, its own updater
   policy and its own shader weights. The stock AppImage is what the rest of this
   repo verifies.

If it is ever revisited, the acceptance gate is unchanged: measured GPU ms with
`veyamux-upscale-test` on the 680M, SGSR parity or better on a still, and the
Auto fallback proven. Until then, it is a link, not a mode.

## Higher-than-1080p host output / 1440p virtual display

Rejected for the TV path. The source is 1080p. Encoding 1440p or 4K does not add
detail, costs encode time and link bandwidth, and adds latency. The Fold does the
only upscale that matters.

## FSR 4 / DLSS / XeSS on the capture feed

Not possible. They need engine motion vectors and depth. The HDMI feed has
neither, and there is no engine to hook. Do not inject them.

## AV1

The 680M cannot encode AV1 and this rig does not assume the Fold can decode it.
HEVC only, 1080p60, 40-60 Mbps.

## 3x into the TV

90 generated frames sampled into a 60 fps stream beat against the capture
cadence. The TV path is 2x, full stop.

## MAKO 5.0

Checked 2026-11-24, **parked**. MAKO is a game-oriented Vulkan frame-generation /
scaling layer (GPL-3.0-or-later), not a VeyAmux integration. VeyAmux removes the
duplicate 60 Hz pictures inside its own capture path; MAKO cannot use that dedupe,
and it must not stack with lsfg-vk. Details and a safe test procedure:
`docs/11-mako-5.md`.
