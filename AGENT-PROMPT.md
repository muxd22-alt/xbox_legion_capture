# Agent handoff prompt

Copy everything between the lines into the agent that runs **on the Legion Go S**.
It assumes the agent can run commands on the machine and that a human is there to
look at the screen.

---

You are extending one Bazzite gaming rig into three modes. Work from
https://github.com/muxd22-alt/xbox_legion_capture on branch
`feature/three-modes` (draft PR #1). Read `README.md`, `docs/07`, `docs/08`,
`docs/09` and `docs/10` before touching anything.

**Machine:** Legion Go S, AMD Z2 Go, Radeon 680M (12 CU, RDNA2, no matrix
cores), 16 GB, Bazzite, KDE Plasma, 1920x1200 internal panel.
**Capture:** Xbox Series S -> Joyzzz USB capture card -> 1080p60.
**TV client:** Galaxy Z Fold 4 in DeX on an HDMI 2.0 dock, Moonlight V+ (64-bit).
**Second client:** Xiaomi box, plain Moonlight only.

## The locked architecture - do not redesign it

| Mode | Frame gen | Upscaler | Refresh |
|---|---|---|---|
| Capture to monitor | LSFG **3x** | Off/SGSR 1:1 | 1080p **90 Hz fixed**, VRR off |
| Capture to TV | LSFG **2x** | SGSR + V+ SGSR on the Fold | 1080p60 stream -> **4K60** |
| Native game | none | HelixSR or FSR **4.1.2 Lite** | 1080p **60 Hz** |
| Native game to TV | none | game upscaler + V+ SGSR | 1080p60 stream -> **4K60** |

- `30 x 3 = 90` on the monitor. `30 x 2 = 60` on the TV. Never 3x into 60.
- Sunshine: **KMS capture, VAAPI, HEVC only**, 1920x1080, 60 fps, 50 Mbps.
- Moonlight V+ on the Fold: 1080p60, HEVC, 50 Mbps, SGSR to 3840x2160,
  **frame generation off**. Plain Moonlight on the Xiaomi.
- Video playback (mpv Anime Build, MpvRx, Jellyfin) is a separate path, not the
  game stream.

## Hard facts - do not fight these

- The 680M has **no AV1 encoder**. Do not select AV1 anywhere.
- A capture feed has **no motion vectors or depth**. FSR 4, DLSS and XeSS cannot
  run on the Xbox picture. Do not inject them.
- At 1080p -> 1080p a spatial upscaler cleans, it does not add detail.
- VeyAmux is **stock upstream**. The ML fork is parked (`docs/10`) and is not
  part of any mode. Do not install it, build it or benchmark it.
- 4K on the wire adds no detail and adds lag. The Fold upscales.

## Rules

- One change at a time, then re-test. Prefer reversible changes.
- **No `rpm-ostree` layering.** No sudo changes to the image. Allowed: `ujust`
  recipes, Flatpak, user-space installers (Decky, AppImage), Bazzite Portal.
  Ask before anything else system-wide.
- Do not run VeyAmux with `sudo`.
- **Never** patch anti-cheat multiplayer games. Single-player only.
- Do not push to `8BiTw0LF`. The fork remote is `muxd22-alt`.
- Branches and draft PRs only. Do not merge to `main`.
- If a step fails twice, **stop**: report the command, the output and the two
  options. Do not loop.
- Report only measured numbers. If you did not measure it, write `UNTESTED`.
  An impression is not a number.

## Preflight - collect facts, change nothing

Run and paste the output into `RESULTS.md` under "Facts":

```bash
bazzite-version
plasmashell --version
kscreen-doctor -o
ls -l /dev/v4l/by-id/
v4l2-ctl --list-devices
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext
wpctl status
ujust get-lsfg status
~/.local/bin/lsfg-vk-cli healthcheck
vainfo | head -n 40
flatpak list --columns=application,version
systemctl --user status homebrew.sunshine --no-pager
rpm-ostree status --booted   # read-only, do not layer anything
```

Then run the repo checkers and save their output:

```bash
./scripts/check-capture.sh
./scripts/check-veyamux.sh
./scripts/check-stream.sh
./scripts/check-native-games.sh
./scripts/check-video-playback.sh
```

Stop and report if `vainfo` has no HEVC `EncSlice` entrypoint, or if the capture
card does not offer 1080p60.

## Task 1 - Mode 1 (capture to monitor) must stay green

Do not change this mode while working on the others. Verify it first:

1. Monitor: 1920x1080 @ **90 Hz fixed**, **VRR off** in KDE and in the OSD.
2. Xbox: 1080p, 60 Hz, HDR off, VRR off.
3. VeyAmux: capture card, 1080p60, cleanup light, **Fixed 3x**, even pacing on.
4. Info line reads `30 fps -> 90 fps (Lossless Scaling 3x)`.
5. 10 minutes of driving: even motion, no black frames, audio in sync.

Record: F3 overlay GPU ms, VeyAmux info line, monitor OSD refresh.

Pass: 90 Hz fixed, 3x active, steady motion. If it is not green, fix this before
any other mode.

## Task 2 - Native games (docs/07)

1. Desktop Mode. Install Decky Loader:

   ```bash
   curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
   ```

2. Game Mode -> Decky -> Settings -> Developer mode.
3. Install DeckyMultiFrameGen from URL (or ZIP):
   `https://github.com/MWGIH/DeckyMultiFrameGen/releases/latest/download/Decky-MultiFrameGen.zip`
4. Backends: install **OptiScaler (Decky Framegen)** and **HelixSR**. Leave MAKO
   and ANR FG off. Leave Preset K / Vulkan kernel builds off for the first pass.
5. Pick **one test game** that offers DLSS/FSR 2+/XeSS, single-player, forced to
   **Proton Experimental**.
6. Per game, set **Use -> OptiScaler**, model **AMD FSR 4.1.2 Lite**. In the game
   select DLSS (or FSR/XeSS). `Insert` shows the active upscaler.
7. Confirm FSR 4 is real: overlay + log + watermark (see `docs/07` section
   "Confirm FSR 4 is really running"). All three must agree, or report which two
   disagree.
8. Play 10 minutes. Record: backend, model, internal res, output res, upscaler
   ms, FPS, and whether it was better than the game's own FSR 2/3.
9. Roll back with **Use -> Off**, then re-enable only if it passed.

Pass: FSR 4.1.2 Lite named in the overlay, stable image, no crash, no
anti-cheat game touched. If the overlay says FSR 2/3, it did not pass.

Stop if: black screen twice, crash twice, or the plugin warns about anti-cheat.

## Task 3 - Sunshine and the TV (docs/08)

1. Bazzite Portal -> App Install -> **Sunshine** -> **Enable** (Brew/beta). The
   flatpak cannot do KMS on this image.
2. Verify:

   ```bash
   systemctl --user status homebrew.sunshine --no-pager
   vainfo | grep -i -E 'VAProfileHEVCMain|VAEntrypointEncSlice'
   ```

3. Run the 10 s HEVC encode test from `docs/08`; record the reported fps/speed.
4. Web UI (`https://localhost:47990`): encoder **VAAPI**, codec **HEVC**,
   1920x1080, 60 fps, **50 Mbps**, HDR off, capture **KMS**.
5. Add the two apps exactly as in `docs/08`:
   - **Xbox Capture (VeyAmux)** - stock AppImage; prep command sets 1080p60.
   - **Desktop / Game Mode** - `/usr/bin/sleep infinity`.
6. On the Legion, set VeyAmux to **Fixed 2x** for this mode and confirm the info
   line reads 60, not 90.
7. Fold 4: install **Moonlight V+ arm64**. Settings -> Frame generation ->
   **Check device support** (must be 64-bit + Vulkan 1.1). Stream: 1080p, 60,
   HEVC, 50 Mbps, **SGSR upscale**, output 3840x2160, **frame gen off**.
8. Pair, launch **Desktop / Game Mode**, then **Xbox Capture (VeyAmux)**.
9. 10 minutes: record V+ stats (fps, codec, bitrate, dropped frames), Legion GPU
   ms, and a written verdict on input delay.

Pass: 60 fps end to end, HEVC, no frame-gen stacking, 4K panel driven by V+.
Do not "improve" this by raising the stream to 1440p/4K.

Stop if: HEVC encode is missing, KMS cannot capture after two connector attempts,
or the Fold falls back to 32-bit/Vulkan-1.0.

## Task 4 - Video playback (docs/09, separate path)

This does not involve Sunshine or VeyAmux.

1. Install mpv (Flatpak) and the **MPV Anime Build v5.6** into its config dir.
2. Set Anime4K to **Fast**, keep **Power Guard** on, HDR off.
3. `./scripts/check-video-playback.sh`; then play 5 minutes of 1080p anime on the
   TV: `K`/`I` overlays, dropped frames, decoder.
4. Fold 4 and Pixel 8: **MpvRx v1.3.2 arm64**, Anime4K, thermal auto-downgrade
   left on. Alternatively mpvEx + the Anime Build Android branch; not both.
5. Jellyfin: set the external player where the client offers it.

Pass: no dropped frames at the chosen tier, no thermal throttle on the Fold.
If Fast still drops, fall back to mpv `spline64` and say so.

## Task 5 - Measurements (required)

Fill the "Measured results" tables in `docs/07`, `docs/08`, `docs/09` and the
log in `docs/05`. For each row give the number and how it was measured:

| What | How |
|---|---|
| VeyAmux GPU ms | F3 overlay, steady state, 60 s |
| Native upscaler ms | OptiScaler overlay or HelixSR log |
| Stream fps/bitrate/drops | V+ stats overlay |
| Encode cost | the ffmpeg test, then Sunshine's own stats |
| End-to-end feel | one written sentence, explicitly not a number |

Anything not measured is `UNTESTED`. Do not estimate. Do not copy a number from
another GPU.

## Task 6 - Report and stop

1. Write `RESULTS.md` at the repo root with: facts, commands run, pass/fail per
   task, measured tables, and the fallback chosen (if any).
2. Commit to `feature/three-modes`, push, and add the results to draft PR #1.
3. Do not merge. Do not open a PR against `8BiTw0LF`.
4. Stop.

## Failure ladder

| Problem | Order to try |
|---|---|
| 90 does not hold | TDP plugged in/28-40 W -> upscaling off -> NR light -> even pacing on -> VRR really off -> 2x at 60 Hz |
| Stream is 30 fps | VeyAmux 3x -> set 2x; panel 30 Hz -> 60; check V+ fps setting |
| Black stream | KMS connector wrong -> pin it; flatpak Sunshine -> reinstall via Portal |
| HEVC encode fails | force VAAPI -> re-run ffmpeg test -> report `vainfo` |
| Fold stutters at 4K | 32-bit V+ -> arm64 build; HDMI 1.4 dock -> HDMI 2.0; TV interpolation off |
| Native game black screen | Use -> Off; one backend only; proxy DLL order; Verify files |
| Native game says FSR 3 | model not loaded; reinstall backend; confirm Proton Experimental |

## Report template

```markdown
# RESULTS - <date>

## Facts
- Bazzite / Plasma / kernel:
- GPU + driver:
- Capture node + formats:
- Display mode (monitor / TV):
- Sunshine install + encoder:
- Decky / MultiFrameGen / HelixSR / OptiScaler versions:

## Task results
| Task | Pass/Fail | Evidence |
|---|---|---|

## Measurements
| Mode | GPU ms | FPS | Bitrate | Drops | Feel (sentence) |
|---|---|---|---|---|---|

## Fallbacks used
-

## Untested / blocked
-
```

---
