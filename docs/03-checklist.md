# Home-day checklist

Goal: **90 fps in VeyAmux**, Xbox -> capture card -> Legion -> VeyAmux
dedupe + 3x -> fixed 90 Hz display, VRR off. No TV, no Moonlight, no network.

## 0. Bring

- [ ] Xbox Series S + controller + HDMI cable.
- [ ] Joyzzz capture card + USB 3.0 cable.
- [ ] JSAUX dock + Legion charger.
- [ ] Legion Go S, Bazzite updated.
- [ ] 1080p monitor with a 90 Hz mode + HDMI cable.
- [ ] This repo on the Legion (or a USB stick).
- [ ] Lossless Scaling owned on Steam.

## 1. Baseline: passthrough

- [ ] Xbox HDMI -> capture card **HDMI IN**.
- [ ] Capture card **HDMI OUT** -> monitor.
- [ ] Xbox set to 1080p60, HDR off.
- [ ] Play five minutes.

Pass: 1080p60, zero software, no added lag. This is the reference. If it fails,
fix cables/Xbox before touching Bazzite.

## 2. Cable the Legion path

- [ ] Capture card USB -> **USB-A 3.0** on the dock.
- [ ] Dock USB-C upstream -> Legion **USB4** port.
- [ ] Legion charger -> dock **PD 100 W**.
- [ ] Dock HDMI -> monitor.
- [ ] Remove the passthrough cable (or keep it for A/B comparison).

Pass: Legion charges, monitor shows the desktop.

## 3. Xbox settings

Settings -> General -> TV & display options -> Video fidelity & overscan:

- [ ] Resolution **1080p**
- [ ] Refresh **60 Hz**
- [ ] Allow 4K **off**
- [ ] HDR10 **off**, Dolby Vision **off**
- [ ] VRR **off**
- [ ] Colour depth **8-bit**
- [ ] Colour space **Standard** (try PC RGB only if blacks crush)

Audio: **Stereo uncompressed**.

Xbox VRR stays off because the capture card needs a steady signal.

## 4. Monitor settings

```bash
kscreen-doctor -o
```

- [ ] A real **1920x1080@90** mode exists.
- [ ] Selected **90 Hz**.
- [ ] **Adaptive sync: Never** (KDE) and **VRR off** in the monitor OSD.
- [ ] Scaling **100%**.
- [ ] HDR **off**.
- [ ] Monitor **Game / Overdrive** mode.

No 90 Hz mode? Stop and use **2x at 60 Hz** instead. Do not run 3x on 120 Hz;
it will judder 3:2.

## 5. Capture card

```bash
v4l2-ctl --list-devices
ls -l /dev/v4l/by-id/
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext
```

- [ ] `1920x1080` at **60 fps** exists.
- [ ] Format noted: `MJPG`, or `YUYV/NV12` if offered (prefer it).
- [ ] Audio source appears in `wpctl status`.

Run `../scripts/check-capture.sh` for a one-shot report.

## 6. Lossless Scaling + lsfg-vk

- [ ] Lossless Scaling installed on Steam.
- [ ] Properties -> Betas -> **`lsfg-vk`** branch selected.
- [ ] `ujust get-lsfg install` (or VeyAmux's install button).
- [ ] `ujust get-lsfg status` -> `install`.
- [ ] `lsfg-vk-cli healthcheck` -> no issues.
- [ ] `lsfg-vk-cli validate` -> valid.

## 7. VeyAmux

- [ ] Latest AppImage downloaded from the releases page.
- [ ] `chmod +x`, run as your user (never `sudo`).
- [ ] FUSE fallback if needed: `--appimage-extract-and-run`.
- [ ] Start screen -> **Capture card** (not Remote Play, not the demo).
- [ ] Card selected, 1920x1080, **60 fps**.
- [ ] Audio input selected, output selected, meter moving.

## 8. Picture

Menu **P**:

- [ ] Upscaling **off/1:1** (or 1.5x at most).
- [ ] Noise reduction **Spatial** or **Both**, low/medium.
- [ ] Anti-flicker **on**.
- [ ] Sharpness light.
- [ ] HDR off.

## 9. Frame generation

- [ ] Method: **Lossless Scaling**.
- [ ] Multiplier: **Fixed 3x**.
- [ ] **Even out frame pacing: on** (about +17 ms).
- [ ] Status: **"Active through lsfg-vk"**.
- [ ] Info line: `≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×)`.

If it says 2x, you are at 60. If it says nothing, frame gen is not active.

## 10. Acceptance

- [ ] Drive in GTA VI for 10 minutes: no black frames, no desync.
- [ ] Motion is even, not alternating fast/slow.
- [ ] HUD/minimap readable.
- [ ] Controller still controls the Xbox directly.
- [ ] You prefer 90 over 30 native. If not, use 2x/60.

## 11. Rollback

- [ ] Frame generation **Off** in VeyAmux (or start with `VEYAMUX_LSFG=0`).
- [ ] Set the monitor back to 120 Hz and VRR on for desktop use if you want.
- [ ] `ujust get-lsfg uninstall` removes the layer if needed.
- [ ] Unplug USB and use the card's HDMI passthrough.
- [ ] The Xbox still works straight into the monitor.
