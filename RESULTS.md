# RESULTS - 2026-11-24

Measured on the Legion Go S. `UNTESTED` means exactly that; an estimate is not a
measurement. The capture measurements were taken on 2026-11-22/23 with the card
and TV connected. At the final check on 2026-11-24 the capture card and TV were
disconnected again, so those hardware rows are historical facts, not a current
live state.

## Facts

| Item | Value |
|---|---|
| Bazzite / Plasma / kernel | Bazzite 45.20261115 (Kinoite), Plasma 6.8.2, kernel 7.3.4-ogc6.1.fc45.x86_64 |
| GPU + driver | AMD Ryzen Z2 Go / Radeon 680M, RADV, Mesa 26.2.7 |
| Capture node + formats | `/dev/video1` / `usb-MACROSILICON_USB3.0_Capture-video-index0`; MS2109, **USB 2.0 (bcdUSB 2.00)**; MJPG 1920x1080 @ 60/30/25/20/10, YUYV 1920x1080 only @ 5 |
| Capture reality | **1080p60 MJPG overruns USB 2.0**; **1080p30 MJPG is clean** |
| Display | TV DP-2 **3840x2160 @ 60.00** verified; current eDP-1 1920x1080 @ 59.96 |
| Sunshine | native AppImage, `sunshine.service` active; `capture = kwin`, `encoder = vaapi`, `hevc_mode = 1`; two apps added |
| Decky / MultiFrameGen | Decky Loader v3.3.1 (root `plugin_loader.service`); DeckyMultiFrameGen v1.9.6 ZIP downloaded, **not installed** |
| HelixSR / OptiScaler | not installed |
| MAKO | v5.0.0 checked, **not installed** (`docs/11-mako-5.md`, `scripts/check-mako.sh`) |
| mpv | Flatpak `io.mpv.Mpv` 0.42.0 + MPV Anime Build v5.6 config; 148 GLSL shaders; VAAPI/gpu-next playback pass |
| Network | 5 GHz Wi-Fi, SSID `ZTE_E44A95_5G`, 5240 MHz, signal -60 dBm |

## Task results

| Task | Result | Evidence |
|---|---|---|
| 1. Capture to monitor | **PASS (adapted)** | 1080p30 MJPG -> Lossless Scaling 2x -> 60 fps; info line below; F3 33.36 ms / 2.73 ms jitter / 64.3 ms delay; **0** JPEG errors. 3x/90 is not possible on this card and the 1080p monitor has no 90 Hz mode. |
| 2. Capture to TV (direct) | **PASS** | DP-2 3840x2160 @ 60.00 active; 30 -> 60 is exact 1:1 on the 60 Hz TV. |
| 3. Sunshine -> Fold 4 / V+ TV | **PARTIAL / BLOCKED** | Sunshine active; HEVC EncSlice present; HEVC smoke test 180 fps / 3x real time; apps added. KMS capture, Fold 4 client and end-to-end 50 Mbps stream **UNTESTED**; host currently uses `capture = kwin`. |
| 4. Native games | **BLOCKED** | Decky Loader present, but DeckyMultiFrameGen/HelixSR/OptiScaler are not installed. The v1.9.6 ZIP is at `~/Downloads/Decky-MultiFrameGen.zip`; install it through Decky's UI in Game Mode. |
| 5. Video playback | **PASS (smoke)** | mpv 0.42.0 + Anime Build v5.6 config; test clip: `VO: [gpu-next] 1920x1080 vaapi[nv12]`, clean exit. A 5-minute anime play test is still needed. |
| 6. MAKO 5.0 | **CHECKED / PARKED** | `docs/11-mako-5.md`; `scripts/check-mako.sh` reports not installed. Not a VeyAmux drop-in; do not stack with lsfg-vk. |

## Measurements

| Mode | GPU ms / timing | FPS | Bitrate | Drops | Feel |
|---|---|---|---|---|---|
| Capture 1080p30, dashboard | 33.36 ms, 2.73 ms jitter, 64.3 ms delay | 30 -> 60 | n/a | 0 JPEG errors | steady |
| Capture in-game GTA VI | 33.36 ms / 2.73 ms jitter / 64.3 ms delay | 27-29 -> 55-57 | n/a | 0 JPEG errors | smooth; game dips below 30 |
| TV direct 4K60 | n/a | 60 output | n/a | n/a | exact 1:1 at 4K60 |
| HEVC encode smoke test | 4 s for 10 s of 1080p60 | 180 fps test | 50 Mbps | 0 | 3x real time |
| mpv test clip | n/a | 60 fps clip | n/a | 0 | VAAPI decode, gpu-next |
| MAKO | not measured | | | | parked |

Exact VeyAmux info line:

```
1920×1080 @ 30 fps → 60 fps (Lossless Scaling 2×) · signal 1920×1080 MJPG @ 30.00 fps · live
```

Frame generation status:

```
Active through lsfg-vk. Lossless Scaling: /var/home/muxd/.local/share/Steam/steamapps/common/Lossless Scaling
lsfg-vk is loaded: [INFO]: Using profile with name 'VeyAmux' (identified via environment)
```

F3 overlay on the dashboard:

```
30.0 fps · 33.36 ms · 1%-low 26 fps · jitter 2.73 ms · delay 64.3 ms
Frame pacing repair: 0% of the pictures moved to an even rhythm (+1 refresh of delay)
```

## Why the capture is 1080p30

The card is a **MacroSilicon MS2109, `bcdUSB 2.00`**, despite the "USB3.0
Capture" product name. It is on the 480 Mbps bus with a 3×1024-byte isochronous
payload. Direct ffmpeg proof:

```bash
ffmpeg -f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 60 \
       -i /dev/video1 -t 10 -f null -
# 300 x "No JPEG data found" / "Found EOI before any SOF"

ffmpeg -f v4l2 -input_format mjpeg -video_size 1920x1080 -framerate 30 \
       -i /dev/video1 -t 8 -f null -
# 0 errors, 30 fps

ffmpeg -f v4l2 -input_format mjpeg -video_size 1280x720 -framerate 60 \
       -i /dev/video1 -t 8 -f null -
# 0 errors, 60 fps, but softer
```

With 1080p30 selected, VeyAmux logged **0** new `No JPEG data` lines over a
5-second sample. The card must be replugged after an HDMI resolution change; it
dropped off USB once during setup and came back as `/dev/video1`.

## TV 4K60

The TV initially exposed only 4K30 (**max TMDS 300 MHz**, EDID 1.3, no 4K60
mode). After enabling the TV's enhanced HDMI mode and/or using the correct HDMI
2.0 port, KDE listed and used **3840x2160 @ 60.00**. VeyAmux's 30 -> 60 output is
exact 1:1 on that 60 Hz mode. The TV is currently disconnected again; the
current panel is eDP-1 at 1920x1080 @ 59.96.

## Sunshine (host side)

- Native AppImage at `~/.local/opt/sunshine-app`, user unit `sunshine.service`,
  active.
- Config backed up before changes:
  `~/.config/sunshine/sunshine.conf.bak-*`,
  `~/.config/sunshine/apps.json.bak-*`.
- `hevc_mode = 1` (allow HEVC with H.264 fallback); `encoder = vaapi`;
  `capture = kwin` for the desktop path.
- Added apps: **Xbox Capture (VeyAmux)** and **Desktop / Game Mode**.
- `vainfo` exposes `VAProfileHEVCMain: VAEntrypointEncSlice`.
- HEVC smoke test: 1080p60, 50 Mbps, 180 fps test / 3x real time.
- KMS capture requires Game Mode; it is not enabled in Desktop Mode. The Fold 4
  / Moonlight V+ client is not available to this agent, so the end-to-end stream
  remains **UNTESTED**.

## Native games (blocked on Decky UI)

- Decky Loader v3.3.1 is installed and its root `plugin_loader.service` is active.
- `~/homebrew/plugins` is **root-owned**; only Decky's UI can install a plugin.
- DeckyMultiFrameGen v1.9.6 ZIP is downloaded to
  `~/Downloads/Decky-MultiFrameGen.zip`.
- Install path: Game Mode -> Decky -> Settings -> Developer -> Install Plugin
  from ZIP -> then install OptiScaler and HelixSR from the plugin's Backends
  panel. One backend per game, single-player only. Leave MAKO/ANR FG off.
- Proton Experimental is present in both Steam library paths.

## Video playback

- `flatpak install --user flathub io.mpv.Mpv` -> 0.42.0.
- MPV Anime Build v5.6 copied to `~/.var/app/io.mpv.Mpv/config/mpv`.
- Linux-specific patch in `mpv.conf`: commented the Windows-only
  `gpu-context=winvk` and the D3D11 VSR lines, and set the Linux profile
  `hwdec=vaapi` (upstream had `nvdec,vulkan,auto`).
- Smoke test:

  ```
  VO: [gpu-next] 1920x1080 vaapi[nv12]
  Exiting... (End of file)
  ```

- `./scripts/check-video-playback.sh` reports 0 failures; 148 GLSL shaders
  (Anime4K, FSRCNNX, ArtCNN), Power Guard present.
- Press **L** to choose Anime4K **Fast** on the 680M; **K** shows the active
  profile, **I** shows decoder/dropped frames. A 5-minute anime test is still
  needed.

## MAKO 5.0

Checked, not installed. MAKO Decky v5.0.0 / Renderer v5.0.0, GPL-3.0-or-later;
MAKO FG is an open-weight 2x-5x frame generator, MAKO Scaler is open, no
Lossless Scaling needed for those. It is a **game-oriented Vulkan layer**:
VeyAmux removes duplicate 60 Hz frames internally, and MAKO cannot use that
dedupe, so it is not a drop-in for the capture path. Do not run it together with
lsfg-vk. See `docs/11-mako-5.md`; `scripts/check-mako.sh` confirms it is not
installed.

## Fallbacks used

- 1080p30 capture instead of 1080p60 (USB 2.0 limit).
- 2x -> 60 instead of 3x -> 90 (no 90 Hz mode; 4K60 is exact 1:1).
- Direct TV 4K60 for the current display; the Sunshine/Fold path is optional.
- Kwin capture + H.264 fallback with HEVC allowed, not KMS/HEVC-only.
- mpv Anime Build patched for Linux/AMD.

## Untested / blocked

- DeckyMultiFrameGen + HelixSR/OptiScaler installation and per-game test.
- KMS capture in Game Mode; Fold 4/Moonlight V+ client; 50 Mbps end-to-end.
- MAKO 5.0 installation/test (deliberately parked).
- 10-minute TV/Fold stream soak; 5-minute anime playback test.
- At the final check the capture card and TV were disconnected; live capture
  measurements above are from the connected session.

## Reproduce

```bash
# capture facts
v4l2-ctl -d /dev/video1 --get-fmt-video
v4l2-ctl -d /dev/video1 --get-parm

# VeyAmux: choose 1920x1080 @ 30 fps MJPG, then:
# P -> Frame gen -> Fixed 2x, Even out frame pacing on
# info line: 1920x1080 @ 30 fps -> 60 fps (Lossless Scaling 2x)

# stream host
./scripts/check-stream.sh

# video playback
./scripts/check-video-playback.sh

# MAKO evaluation
./scripts/check-mako.sh
```

## Notes

- VeyAmux does **not** remember the capture mode. On every start it opens mode
  0 = 1080p60, which overruns this card. Select **1080p30 MJPG** and Start.
- The saved VeyAmux profile `4x` is first in the profile order and bound to
  `1920x1080@30 MJPEG`; it matches the final picture settings.
- Desktop shortcut:
  `~/Desktop/VeyAmux.desktop` -> `~/.local/share/applications/veyamux.desktop`,
  icon `~/.local/share/icons/hicolor/scalable/apps/veyamux.svg`,
  Exec `~/Applications/VeyAmux-x86_64.AppImage --fullscreen --dialog`.
- Do not stack frame generation: VeyAmux/lsfg-vk for capture, no MAKO/ANR FG,
  and Moonlight V+ frame generation off for the TV path.
