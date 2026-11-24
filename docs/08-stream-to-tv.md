# 08 - Stream to the TV (Sunshine -> Fold 4 -> 4K60)

The TV path is deliberately boring: **the Legion sends 1080p60 HEVC and the
Fold 4 does the 4K**. Everything below exists to keep that one sentence true.

```
Legion Go S (Bazzite, KMS capture)
  | Sunshine: HEVC, 1920x1080, 60 fps, 50 Mbps
  v
5 GHz Wi-Fi on the 5G router (wired Ethernet preferred)
  v
Galaxy Z Fold 4 in DeX, HDMI 2.0 dock
  | Moonlight V+ (64-bit): SGSR upscale 1080p -> 3840x2160, frame gen OFF
  v
4K60 TV
```

> Status: **UNTESTED on this hardware.** Commands and settings are the plan the
> on-device agent runs and measures. No bitrate, ms or latency number here is a
> measurement.

## Why 1080p60 HEVC and not 4K

- The source is 1080p. The Xbox capture is 1920x1080, and native games run at
  1080p on the 680M. Encoding 4K cannot add detail that was never there.
- The 680M (RDNA2, VCN 3.x) has **no AV1 encoder**. AV1 encode needs newer VCN
  hardware. HEVC is the correct codec on this iGPU.
- This rig treats AV1 as unavailable on both ends, so do not select it anywhere.
- A 4K encode costs GPU time and link bandwidth for zero detail, and it adds
  latency. 1080p60 at 50 Mbps keeps the frame budget for VeyAmux and lsfg.
- The Fold 4 upscales 1080p to 4K with SGSR inside Moonlight V+. That is the
  only upscale in this path, and it happens after decode, off the Legion.

**Rejected on purpose:** 1440p or 4K host output, a 1440p virtual display, and
a forked VeyAmux that outputs higher than 1080p. The capture is 1080p; none of
those add detail, and all of them add lag.

## Frame generation: done once, on the Legion

| Mode | Legion | Client (V+) |
|---|---|---|
| Capture to TV | VeyAmux **Fixed 2x** -> 60 fps | **Frame generation OFF** |
| Native game to TV | game's own 60 fps (no LSFG) | **Frame generation OFF** |

`30 x 2 = 60`. Do **not** run 3x for the TV path: 90 generated frames sampled
into a 60 fps stream beats against the capture cadence and looks worse than 2x.
Do **not** turn on V+ frame generation as well. Frame generation twice is how
you get 120 ms of lag and ghosting.

V+ frame generation also needs developer features enabled, Android 10, a
64-bit ARM CPU, Vulkan 1.1, and an imported `Lossless.dll`. Since it stays off,
none of that is configured here.

## Install Sunshine (KMS capture)

Bazzite's **flatpak** Sunshine cannot capture through KMS, and the Legion runs
the Deck image in Game Mode where KMS is the capture path. Use the Bazzite
Portal path that installs the Brew (beta) build:

1. Open **Bazzite Portal** -> **App Install** -> **Sunshine**.
2. Choose **Enable** (beta, Brew). Wait for the terminal step and give the
   password when asked for capture permissions.
3. `ujust setup-sunshine` is the scripted equivalent if the Portal entry is
   missing; it is not a substitute for the brew install on Deck images.

Do not layer an RPM with `rpm-ostree` for this. It is not needed and it blocks
image updates.

Check the service:

```bash
systemctl --user status homebrew.sunshine --no-pager
# flatpak installs would be app-dev.lizardbyte.app.Sunshine instead
```

The web UI is `https://localhost:47990`. Set a username and password on first
run; it is not the same as the Bazzite login.

## Confirm HEVC encode exists before configuring anything

```bash
vainfo | grep -i -E 'VAProfileHEVCMain|VAEntrypointEncSlice'
```

Pass: a HEVC **EncSlice** entrypoint. If only `VAEntrypointVLD` (decode)
appears, HEVC encode is not exposed and this path cannot work; stop and report.

Encoder smoke test (10 s, 1080p60, 50 Mbps, no output file):

```bash
ffmpeg -hide_banner -f lavfi -i testsrc2=size=1920x1080:rate=60 -t 10 \
  -vaapi_device /dev/dri/renderD128 \
  -vf 'format=nv12,hwupload' \
  -c:v hevc_vaapi -b:v 50M -maxrate 50M -bufsize 100M -f null -
```

Pass: it finishes with no `No usable encoding profile` error and reports a
sustained `fps` near 60. Record the reported speed; it is the first real number
for this mode.

## Sunshine configuration

In the web UI, **Configuration -> Audio/Video**:

| Setting | Value |
|---|---|
| Encoder | **VAAPI** |
| Codec | **HEVC** (H.265) |
| Resolution | 1920x1080 |
| Frame rate | 60 |
| Bitrate | **50 Mbps** (40-60 is the band) |
| HDR | Off |
| Audio | Stereo, the Legion's output device |
| Capture | **KMS** |

In `~/.config/sunshine/sunshine.conf` the two lines that matter:

```ini
capture = kms
encoder = vaapi
```

If KMS picks the wrong screen, list connectors and pin one:

```bash
for f in /sys/class/drm/card*-*/status; do echo "$f: $(cat "$f")"; done
```

Use the connector whose status is `connected`. On the Legion this is usually the
internal panel (`eDP-1`) in handheld use, or the dock's HDMI output when a
display is attached.

## Two Sunshine apps

Add both under **Applications** in the web UI (or in `apps.json`). The names are
deliberately plain: this rig uses **stock VeyAmux**, so there is no "ML" build to
launch.

### 1. Xbox Capture (VeyAmux)

Runs the stock VeyAmux AppImage fullscreen and sets the panel to 1080p60 for the
stream.

```json
{
  "name": "Xbox Capture (VeyAmux)",
  "cmd": "/home/deck/Applications/VeyAmux-x86_64.AppImage",
  "prep-cmd": [
    {
      "do": "kscreen-doctor output.eDP-1.mode.1920x1080@60",
      "undo": "kscreen-doctor output.eDP-1.mode.1920x1200@60"
    }
  ]
}
```

Replace `eDP-1` and the undo mode with what `kscreen-doctor -o` reports on the
machine. VeyAmux itself must be set to **Fixed 2x** and **VRR off** for this
mode; the monitor profile (3x, 90 Hz) is mode 1 and is not used while streaming.

### 2. Desktop / Game Mode

A session holder, not a launcher. It keeps the stream alive while you are in
Plasma or in Game Mode; you switch modes yourself before connecting.

```json
{
  "name": "Desktop / Game Mode",
  "cmd": "/usr/bin/sleep infinity"
}
```

Do not point this at `plasmashell` or `gamescope-session`: the app exiting ends
the stream.

## Moonlight V+ on the Fold 4

V+ is the 64-bit Android build: https://github.com/qiin2333/moonlight-vplus

Install the **arm64-v8a** APK on the Fold 4. The Xiaomi box keeps **plain
Moonlight**: V+ is the experimental client here, the Xiaomi is the known-good
one. Do not install V+ on the Xiaomi.

Stream settings:

| Setting | Value |
|---|---|
| Resolution | **1920x1080** |
| Frame rate | **60** |
| Codec | **HEVC** |
| Bitrate | **50 Mbps** |
| HDR | Off |
| Video upscaling | **SGSR** (FSR 1 if SGSR is not offered in your build) |
| Output resolution | **3840x2160** (DeX / external display) |
| Frame generation | **Off** |
| External display | Settings -> **Send stream to external display** |

Confirm the device first: Settings -> Frame generation -> **Check device
support**. It must report Android 10+, 64-bit ARM and Vulkan 1.1. With frame
generation off this is informational, but it also proves the build is 64-bit.
A 32-bit client will not load the upscaler's Vulkan path and will stutter at 4K.

DeX notes:

- Use the HDMI 2.0 dock. 4K60 needs HDMI 2.0 bandwidth; a USB-C hub with HDMI
  1.4 will drop to 4K30.
- Set the TV to **Game mode** and disable its own motion interpolation. The TV
  must not add a second frame-generation layer.
- Keep the Fold on a charger for long sessions; sustained 4K decode plus SGSR
  will throttle otherwise.

## Network

| Link | Verdict |
|---|---|
| Wired Ethernet into the dock | Preferred |
| 5 GHz Wi-Fi on the 5G router, same room | Acceptable for 50 Mbps |
| 2.4 GHz | Not acceptable |
| Wi-Fi extender / powerline | Not measured; expect latency spikes |

The Legion and the Fold must be on the same router and the same subnet. If the
router has band steering, pin both devices to the 5 GHz SSID for the test so the
comparison is not contaminated by a 2.4 GHz roam.

## Verify, in order

1. `vainfo` shows HEVC `EncSlice`; the ffmpeg test above runs at ~60 fps.
2. Sunshine web UI shows **KMS** as the capture backend and **VAAPI/HEVC** as
   the encoder.
3. Pair the Fold 4. Launch **Desktop / Game Mode** first: the desktop appears at
   1080p60.
4. Launch **Xbox Capture (VeyAmux)**. VeyAmux's info line must read 30 -> 60
   (`Lossless Scaling 2x`), not 90.
5. In V+, open the stream stats: 60 fps, HEVC, bitrate near 50 Mbps, no dropped
   frames after 2 minutes.
6. Watch 10 minutes of driving. Check for: uneven motion, audio drift, HUD
   shimmer, and whether the TV's game mode is actually on.

Pass: 60 fps end to end, HEVC, no frame-gen stacking, 4K panel driven by V+.

## Failure ladder

| Symptom | Try |
|---|---|
| Black screen, audio only | KMS picked the wrong connector; pin it, or attach a display to the dock |
| 503 / cannot capture | Sunshine running as flatpak; reinstall via Portal -> Sunshine -> Enable (Brew) |
| `Couldn't import RGB Image` | Wrong encoder; force VAAPI, then re-run the ffmpeg test |
| Stream is 30 fps | VeyAmux still on 3x, or the panel is at 30 Hz; set 2x and 1080p60 |
| Stutter at 4K on the Fold | V+ built 32-bit, or the dock is HDMI 1.4, or the TV is interpolating |
| High latency | Turn off V+ frame generation, turn off the TV's motion smoothing, go wired |
| Bitrate collapses | Wi-Fi congestion; move to 5 GHz line of sight or wired |

## Measured results (fill in on the Legion)

| Test | Encoder / codec | Resolution | Bitrate | Legion GPU ms | FPS | End-to-end feel |
|---|---|---|---|---|---|---|
| Capture to TV | VAAPI HEVC | 1080p60 | 50 Mbps | UNTESTED | UNTESTED | UNTESTED |
| Native game to TV | VAAPI HEVC | 1080p60 | 50 Mbps | UNTESTED | UNTESTED | UNTESTED |
| Xiaomi (plain Moonlight) | VAAPI HEVC | 1080p60 | 50 Mbps | UNTESTED | UNTESTED | UNTESTED |

"End-to-end feel" is a written verdict from the person holding the controller:
input delay, motion evenness, HUD readability. It is not a number and must not be
presented as one.
