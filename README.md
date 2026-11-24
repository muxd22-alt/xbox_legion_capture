# Xbox, native games, and a 4K TV on one Legion Go S

Three modes on one Bazzite rig: play the Xbox Series S through a capture card,
play the Legion's own Steam library, and send either one to a 4K TV. HDR stays
off end to end. No Windows, no Veyra, no DLSS injection into a capture feed.

```
MODE 1 - Xbox capture to monitor
Xbox Series S (1080p60, HDR off, VRR off)
  | HDMI
Joyzzz capture card (1920x1080 @ 60)
  | USB 3.0
Legion Go S (Bazzite): stock VeyAmux, SGSR, LSFG 3x
  | 1920x1080 @ 90 Hz fixed, VRR off
Monitor

MODE 2 - Xbox capture to TV
same Legion chain, but LSFG 2x -> 60
  | Sunshine: KMS, VAAPI, HEVC, 1080p60, 50 Mbps
5 GHz Wi-Fi
  | Galaxy Z Fold 4 in DeX, HDMI 2.0 dock
Moonlight V+: SGSR 1080p -> 4K60, frame gen off
TV
```

Native games use the same Legion, the same 1080p60 stream, and the game's own
motion vectors through HelixSR or OptiScaler.

## The modes

| Mode | Source | Frame gen | Upscaler | Output / refresh |
|---|---|---|---|---|
| **Capture to monitor** | Xbox 1080p60 -> 30 unique | LSFG **3x** | Off / SGSR 1:1 | 1080p **90 Hz fixed**, VRR off |
| **Capture to TV** | Xbox 1080p60 -> 30 unique | LSFG **2x** | SGSR on Legion + **V+ SGSR** on Fold | 1080p60 stream -> **4K60** TV |
| **Native game** | Steam, Proton Experimental | none (VeyAmux not involved) | HelixSR or FSR **4.1.2 Lite** | 1080p **60 Hz** (90 only if the game holds it) |
| **Native game to TV** | Steam, Proton Experimental | none | game upscaler + **V+ SGSR** | 1080p60 stream -> **4K60** TV |

Rules that do not change:

- **30 x 3 = 90** for the monitor. 30 x 2 = 60 for the TV. Never 3x into a 60 Hz
  stream.
- **VRR off, fixed refresh.** lsfg-vk needs a fixed cadence; 90 fps on a fixed
  120 Hz panel is 3:2 and judders.
- **Frame generation once.** If VeyAmux runs LSFG, Moonlight V+ frame generation
  stays off.
- **1080p60 HEVC on the wire.** The 680M has no AV1 encoder and this rig does not
  use AV1 on either end. Sending 4K adds lag, not detail.
- **HDR off** on the Xbox, the capture, the Legion, the stream and the TV.

## The numbers

| Path | Unique frames | Multiplier | Wire | Display |
|---|---|---|---|---|
| Capture to monitor | 30 | 3x | none | 90 Hz fixed |
| Capture to TV | 30 | 2x | 1080p60 HEVC, 50 Mbps | 4K60, upscaled on the Fold |
| Native game | game's own | none | none | 60 Hz |
| Native game to TV | game's own | none | 1080p60 HEVC, 50 Mbps | 4K60, upscaled on the Fold |

The game still simulates at 30 Hz in capture mode. 90 is 90 pictures, not 90
updates. Latency goes up, not down.

## Hardware

| Part | Role | Limit that matters |
|---|---|---|
| Xbox Series S | GTA VI at ~1080p30 | 30 fps target; 60 Hz output |
| Joyzzz capture card | HDMI -> USB UVC | Capture 1080p60 |
| JSAUX 6-in-1 dock | USB-C hub, HDMI 2.1, USB-A 3.0 | Plug into the Legion USB4 port |
| Legion Go S | AMD Z2 Go, Radeon 680M (12 CU, RDNA2), 16 GB | 1080p only; no AV1 encode; no matrix cores |
| Monitor | 1080p with a real 90 Hz mode | Fixed 90 Hz, VRR off |
| Galaxy Z Fold 4 | Moonlight V+ client, DeX | 64-bit, Vulkan 1.1; HDMI 2.0 dock for 4K60 |
| 5G router | 5 GHz link to the Fold | 50 Mbps needs a clean link |
| Xiaomi box | plain Moonlight only | Not a V+ device |

## Quick start

1. **Xbox:** 1080p, 60 Hz, HDR off, VRR off, 8-bit, stereo uncompressed.
2. **Monitor:** 1920x1080 at a **fixed 90 Hz**, **VRR/Adaptive Sync: Never**,
   HDR off, 100% scaling. Check `kscreen-doctor -o` first.
3. **Capture:** 1080p**60** on the stable `/dev/v4l/by-id/...` node.
4. **VeyAmux:** stock AppImage from upstream. Capture card, 1080p60, cleanup
   light, **Fixed 3x**, **Even out frame pacing on**. Confirm
   "Active through lsfg-vk".
5. **Native games:** Decky + DeckyMultiFrameGen + HelixSR/OptiScaler. See
   `docs/07-native-games.md`.
6. **TV:** Sunshine via Bazzite Portal (Brew build, KMS), HEVC 1080p60 50 Mbps;
   V+ on the Fold with SGSR upscale and frame gen off. See
   `docs/08-stream-to-tv.md`.

If the monitor has no 90 Hz mode: 60 Hz fixed, frame generation 2x, target 60.

## Settings summary

### Xbox

1080p, 60 Hz, HDR off, VRR off, 8-bit, Standard colour, stereo uncompressed.
Xbox VRR off is deliberate: the capture card needs a steady signal.

### Capture

1920x1080 @ **60**, YUYV/NV12 if offered, otherwise MJPEG. 30 is a fallback, not
the starting point.

### Monitor

1920x1080 @ **90 Hz fixed**, **VRR off**, SDR, 100% scaling.

### VeyAmux

| Setting | Monitor mode | TV mode |
|---|---|---|
| Source | capture card 1080p60 | capture card 1080p60 |
| Upscaling | Off / 1:1 | Off / 1:1 (V+ does the 4K) |
| Noise reduction | Spatial or Both, low/medium | same |
| Anti-flicker | On | On |
| Sharpness | light | light |
| Frame generation | **Fixed 3x** | **Fixed 2x** |
| Even out frame pacing | On | On |
| Display | 1080p90, VRR off | 1080p60 |
| HDR | off | off |

VeyAmux stays stock. The parked ML fork is not part of any mode; see
`docs/10-parked-experiments.md`.

### Native games

Per game, exactly one backend:

- **OptiScaler + AMD FSR 4.1.2 Lite** for DX12 games with DLSS/FSR 2+/XeSS.
- **HelixSR Scaler** for the game's own DLSS path.
- **FSR drop-in** only for FSR 3.1 games without anti-cheat.

Force **Proton Experimental**. Single-player only; never anti-cheat multiplayer.

### TV / Moonlight V+

| Setting | Value |
|---|---|
| Client | Moonlight V+ arm64 on the Fold 4; plain Moonlight on the Xiaomi |
| Resolution | 1920x1080 |
| Frame rate | 60 |
| Codec | HEVC |
| Bitrate | 50 Mbps (40-60 band) |
| Video upscaling | SGSR (FSR 1 if SGSR is not offered) |
| Output | 3840x2160 via DeX / external display |
| Frame generation | **Off** |
| HDR | Off |

## Video playback upscaling (not the game stream)

Files and Jellyfin are a separate path and are documented separately:

- **Bazzite:** mpv + **MPV Anime Build v5.6**, Fast tier, Power Guard on
  (Eco on battery). https://github.com/Chinna95P/mpv-anime-build
- **Fold 4 / Pixel 8:** **MpvRx v1.3.2** with Anime4K and its thermal
  auto-downgrade to C/Fast, or mpvEx with the Anime Build's Android branch.
- **Jellyfin:** use the external player where the client offers it; do not expect
  the server to upscale.

Details: `docs/09-video-playback-upscaling.md`.

## What this rig is not

- **Not FSR 4 / DLSS on the Xbox picture.** A capture feed has no motion vectors
  or depth. Only a spatial upscaler fits, and at 1080p -> 1080p it cleans rather
  than adds detail.
- **Not 120 from 30.** LSFG exposes 2x/3x. 90 is the monitor target.
- **Not 4K from the Legion.** The capture is 1080p; the Fold does the 4K.
- **Not an Xbox Remote Play client.** VeyAmux's Remote Play option is
  PlayStation-only.
- **Not a VRR tool.** Frame generation and VRR do not mix here.

## Verify

```bash
# display: fixed 90 Hz (monitor) or 60 Hz (TV), VRR off
kscreen-doctor -o

# capture formats on the stable node
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext

# lsfg-vk
ujust get-lsfg status
~/.local/bin/lsfg-vk-cli healthcheck

# streaming prerequisites (HEVC encode, KMS, network)
./scripts/check-stream.sh

# native-game stack
./scripts/check-native-games.sh

# mpv Anime Build
./scripts/check-video-playback.sh
```

VeyAmux's info line for monitor mode:

```
≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×) · signal 1920×1080 @ 60 fps
```

For TV mode it must read `-> 60 fps (Lossless Scaling 2×)`.

## Repo map

| File | What it is |
|---|---|
| `docs/01-signal-chain.md` | Hardware, cabling, capture formats, why 60 capture and 90 Hz. |
| `docs/02-veyamux-setup.md` | Install and configure VeyAmux end to end. |
| `docs/03-checklist.md` | Home-day checklist with pass/fail steps. |
| `docs/04-audio-controller.md` | Audio through VeyAmux, controller facts. |
| `docs/05-settings.md` | All settings, the test matrix and the measurement log. |
| `docs/06-troubleshooting.md` | VeyAmux/lsfg errors, VRR, audio, rollback. |
| `docs/07-native-games.md` | Decky, DeckyMultiFrameGen, HelixSR, FSR 4.1.2 Lite, rollback, RDNA2 cost. |
| `docs/08-stream-to-tv.md` | Sunshine KMS/VAAPI/HEVC, two apps, V+ on the Fold, frame-gen-once. |
| `docs/09-video-playback-upscaling.md` | mpv Anime Build, MpvRx, Jellyfin. Not the game path. |
| `docs/10-parked-experiments.md` | The ML fork and 1440p host output: why they are not in any mode. |
| `AGENT-PROMPT.md` | Copy-paste briefing and acceptance checks for the on-device agent. |
| `scripts/check-capture.sh` | V4L2 by-id nodes, formats and audio sources. |
| `scripts/check-veyamux.sh` | VeyAmux, lsfg-vk, display mode and logs. |
| `scripts/check-stream.sh` | Sunshine service, KMS, HEVC encode test, network. |
| `scripts/check-native-games.sh` | Decky, plugin, Proton Experimental, one game's proxies/logs. |
| `scripts/check-video-playback.sh` | mpv config, shader pack, Power Guard. |

## Safety

- VeyAmux is an **AppImage**: unsigned and unsandboxed. Download it from the
  project's releases, run it as your user, never with `sudo`.
- Do not install "FSR 4 / DLSS on a capture feed" DLLs. There is no engine to
  hook on an HDMI feed.
- No `rpm-ostree` layering for this rig. Sunshine comes from Bazzite Portal,
  everything else is user space or Flatpak.
- Never patch anti-cheat multiplayer games with upscaler DLLs.

## Sources

- VeyAmux: https://github.com/8BiTw0LF/VeyAmux
- lsfg-vk: https://lsfg-vk.dev/docs/
- Bazzite Sunshine: https://docs.bazzite.gg/Advanced/sunshine/
- HelixSR: https://github.com/lonewolf0622/HelixSR
- DeckyMultiFrameGen: https://github.com/MWGIH/DeckyMultiFrameGen
- Moonlight V+: https://github.com/qiin2333/moonlight-vplus
- MPV Anime Build: https://github.com/Chinna95P/mpv-anime-build
- MpvRx: https://github.com/Riteshp2001/mpvRx
