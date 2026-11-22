# Home-day checklist

Goal: **1080p120 on the monitor**, Xbox -> capture card -> Legion -> lsfg 4x.
No TV, no Moonlight, no network.

## 0. Bring

- [ ] Xbox Series S + controller + HDMI cable.
- [ ] Joyzzz capture card + USB cable.
- [ ] JSAUX dock + Legion charger.
- [ ] Legion Go S, Bazzite updated.
- [ ] 1080p120 monitor + HDMI cable.
- [ ] This repo on the Legion (or a USB stick).

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

Pass: Legion charges, monitor shows the desktop at 1080p120.

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

## 4. Monitor settings

- [ ] `kscreen-doctor -o` shows **1920x1080@120**.
- [ ] Scaling **100%**.
- [ ] HDR **off**.
- [ ] Monitor **Game / Overdrive** mode.
- [ ] Adaptive sync **off** for the first test.

## 5. Capture card

```bash
v4l2-ctl --list-devices
ls -l /dev/v4l/by-id/
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext
```

- [ ] `1920x1080` at **30 fps** exists.
- [ ] Note the format: `MJPG`, or `YUYV` if offered (prefer it).
- [ ] Audio source appears in `wpctl status`.

Run `../scripts/check-capture.sh` for a one-shot report.

## 6. lsfg-vk

- [ ] Lossless Scaling installed on Steam, beta branch **`lsfg-vk`**.
- [ ] `ujust get-lsfg install`.
- [ ] `ujust get-lsfg status` -> `install`.
- [ ] Profile: `mpv`, multiplier **4**, flow **0.5**, performance **on**,
      pacing **vsync**, FP16 **on**.
- [ ] `lsfg-vk-cli validate` passes.

## 7. mpv

```bash
CARD=/dev/v4l/by-id/<card>-video-index0
mpv av://v4l2:$CARD --fs \
  --profile=low-latency --untimed --video-sync=desync \
  --demuxer-lavf-o=video_size=1920x1080,framerate=30,input_format=mjpeg \
  --vo=gpu-next --gpu-api=vulkan --hwdec=vaapi \
  --no-audio --no-osc --osd-level=0
```

- [ ] Picture appears fullscreen.
- [ ] The terminal prints `(lsfg-vk) ... Multiplier: 4`.
- [ ] The picture is visibly smoother than 30 fps.
- [ ] `MANGOHUD=1` is only a sanity check: it can show 30 when it loads above
      lsfg-vk. Do not treat that as failure.
- [ ] Without lsfg (disable the profile), the same command shows ~30.

If it shows 60, the display is 60 Hz or the multiplier is 2. If it shows 240,
you are capturing 60 and multiplying 4x.

## 8. Audio

- [ ] Card source linked to speakers (`pw-link`), or looped to a sink.
- [ ] Audio in sync enough for dialogue.
- [ ] Xbox not set to Dolby/DTS.

Details: `04-audio-controller.md`.

## 9. Acceptance

- [ ] Drive in GTA VI for 10 minutes: no black frames, no desync.
- [ ] HUD/minimap readable (4x smears text first).
- [ ] Camera pans look smoother than 30 native.
- [ ] Controller still controls the Xbox directly.
- [ ] You prefer 120 over 60 passthrough. If not, use 3x/90 or 2x/60.

## 10. Rollback

- [ ] Disable the lsfg profile (multiplier 1 / off).
- [ ] Or run mpv without lsfg.
- [ ] Or unplug USB and use the card's HDMI passthrough.
- [ ] `ujust get-lsfg uninstall` removes the layer if needed.
- [ ] The Xbox still works straight into the monitor.
