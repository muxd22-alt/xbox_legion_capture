# 09 - Video playback upscaling (files and Jellyfin)

This is a **separate section** from the game stream. Nothing here runs through
Sunshine, VeyAmux, lsfg-vk or Moonlight V+. It is for watching files and Jellyfin
on the Legion, the Fold 4 and the Pixel 8.

The rule is the same as everywhere else in this repo: upscale **once**, and only
where the output is genuinely larger than the source.

> Status: **UNTESTED on this hardware.** The players and tiers are chosen; the
> frame times are not measured yet.

## Bazzite: mpv + MPV Anime Build v5.6

Build: https://github.com/Chinna95P/mpv-anime-build (MIT)

It is a configuration and shader pack, not a player. It auto-detects anime vs
live action, and on a 680M the **Fast** tier is the correct default. The HQ tier
uses the parallel compute (`*_CMP.glsl`) ArtCNN paths and is the first thing to
drop frames on 12 CUs.

### Install

1. Install mpv as a Flatpak (user space, no image changes):

   ```bash
   flatpak install flathub io.mpv.Mpv
   ```

   With the Flatpak the config directory is
   `~/.var/app/io.mpv.Mpv/config/mpv`, not `~/.config/mpv`. If you install mpv
   from Homebrew or the distro instead, use `~/.config/mpv` as the build's README
   says.

2. Download the v5.6 release ZIP and extract its **contents** into that config
   directory, so that `mpv.conf`, `input.conf`, `scripts/`, `script-opts/`,
   `shaders/` and `fonts/` sit directly inside it.

3. Install the bundled `Source Sans Pro` font if the stats overlay looks wrong.

4. Keep personal overrides in exactly one `mpv-personal.conf` beside `mpv.conf`.
   The build loads it after its own config, so build updates do not overwrite it.
   Do not edit the shipped `mpv.conf` for personal taste.

### Settings for the 680M

| Setting | Value | Where |
|---|---|---|
| Anime4K quality | **Fast** | `L` cycles Fast/HQ, or UOSC -> Anime4K |
| Anime pipeline | Auto | `Ctrl+L`; path/keyword detection |
| Power Guard | **On** | default; `Ctrl+P` toggles manually |
| Hardware decode | VA-API | default on Linux; Power Guard restores it after Eco |
| HDR | **Off** | keep the rig SDR end to end |
| Native scaler | `spline64` | build default |
| Shader killswitch | `Ctrl+G` | use to prove the cost of the shaders |

Power Guard is the reason this build is here: on battery it drops to the
`[Low-End]` bilinear profile, locks the heavy shaders out and restores the exact
VA-API decoder when AC returns. The Legion is a handheld; that behaviour is not
optional.

### Confirm it is working

- `K` shows the active profile, mode and shader chain. It must say Anime (or
  Live Action) and list the shaders actually loaded.
- `I` shows input vs output resolution, dropped frames and the decoder.
- `Ctrl+G` disables all shaders. If the picture barely changes, the shader chain
  was not doing anything; check `K` again.
- Watch 5 minutes of 1080p anime on the 4K TV. Pass: no dropped frames, no audio
  drift, GPU not pinned at 100%.

### Cost note

1080p -> 4K is a 4x pixel count. Even the Fast tier is a real GPU load on 12 CUs.
If it drops frames:

1. `Ctrl+G` to confirm the shaders are the cause.
2. Drop to Fast if you were on HQ.
3. Turn off debanding/denoise first; they are cheap-looking but not free.
4. Fall back to mpv's native `spline64` upscale. A stable 60 beats a sharp 43.

## Android: Fold 4 on the TV, Pixel 8 handheld

Two supported choices. Pick one per device; do not stack them.

### MpvRx v1.3.2 (recommended for the Fold 4)

https://github.com/Riteshp2001/mpvRx/releases/tag/v1.3.2 - install the
**arm64-v8a** APK.

- Anime4K is bundled and set up on first run; no manual shader copying.
- v1.3.2 adds `ThermalMonitor`: it samples Android's thermal headroom every
  10 seconds and **proactively downgrades Anime4K to C/Fast below 40% headroom**,
  before frames start dropping. On a docked Fold running 4K output this is the
  feature that matters.
- The Ambient shader budget is also capped by thermal state (8/12/18 samples).
- Keep HDR off to match the rig. If you turn it on, the app's hdr-toys pipeline
  needs GPU Next + Vulkan; it falls back to Off with an error pill otherwise.

### mpvEx + the Anime Build's Android branch

https://github.com/Chinna95P/mpv-anime-build/tree/android

Use this if you already run mpvEx or Aniyomi and want the same shader logic as
the Legion. It ships Android-specific shader tiers; expect the same Fast-first
rule. Do not run it and MpvRx on the same device as your default.

### What not to do

- Do not enable frame generation in MpvRx/mpv for film and TV. It is a different
  artefact problem from games and it is not part of this rig.
- Do not install Moonlight V+ on the Xiaomi. That box stays on plain Moonlight
  for game streaming and out of this section entirely.

## Jellyfin

| Client | How to use mpv/MpvRx |
|---|---|
| Jellyfin Android (Fold 4, Pixel 8) | Settings -> Playback -> **External player**; pick mpv or MpvRx |
| Jellyfin desktop (Bazzite) | `jellyfin-mpv-shim` (Flatpak or pipx) points Jellyfin at mpv |
| Jellyfin web | No external player; use the Android app or the shim |

Jellyfin's own player is fine for convenience. Use the external player when you
want the Anime Build / MpvRx shader chain; do not expect Jellyfin's transcoder to
do the upscaling. Keep direct play on, and let the client upscale.

## Measured results (fill in on the Legion)

| Device | Player | Content | Source -> output | Tier | GPU ms / dropped frames | Verdict |
|---|---|---|---|---|---|---|
| Legion -> TV | mpv v5.6 | 1080p anime | 1080p -> 2160p | Fast | UNTESTED | UNTESTED |
| Fold 4 -> TV | MpvRx 1.3.2 | 1080p anime | 1080p -> 2160p | Anime4K (auto) | UNTESTED | UNTESTED |
| Pixel 8 | MpvRx 1.3.2 | 1080p anime | 1080p -> 2400x1080 | Anime4K (auto) | UNTESTED | UNTESTED |

Report dropped frames and the decoder from `I`/stats, not an impression. If the
number is not measured, write UNTESTED.
