# Troubleshooting

Fix one thing at a time. VeyAmux's own status box and log are the first place to
look.

## VeyAmux / lsfg-vk errors

| Symptom | Cause | Fix |
|---|---|---|
| "Only Lossless.dll was found" | Steam is on the normal branch | Properties -> Betas -> **`lsfg-vk`**, let it download |
| "The specified shader DLL does not exist" | Same, or `LSFGVK_DLL_PATH` points at the old DLL | Switch branch; do not point at `Lossless.dll` |
| "lsfg-vk is not installed" | No lsfg-vk 2 layer | VeyAmux's **Install lsfg-vk 2**, or `ujust get-lsfg install` |
| Old lsfg-vk 1.x detected | Leftover files | `lsfg-vk-cli healthcheck`; remove the 1.x files it lists |
| Frame generation turns off after a crash | State left dirty | Press **Try again** in the menu |
| Status is not "Active through lsfg-vk" | Layer not loaded or wrong profile | Check the log; then `vulkaninfo --summary 2>/dev/null | grep -i lsfg` |
| Frame gen active but info says 60 | Multiplier is 2x | Set **Fixed 3x** |
| Frame gen active but info says 30 | lsfg not actually generating | Check the `(lsfg-vk)` lines and the log |
| `LSFGVK_*` environment variables do nothing | They are ignored unless enabled | Add `LSFGVK_ENV=1` |

Log:

```bash
tail -n 100 ~/.config/VeyAmux/lsfg-vk.log
```

## 90 looks uneven

90 fps on a 120 Hz panel needs VRR to avoid 3:2 judder.

- [ ] VRR/Adaptive Sync on in KDE **and** the monitor OSD.
- [ ] Monitor actually at 120 Hz (`kscreen-doctor -o`).
- [ ] VeyAmux's **even out frame pacing** enabled if offered.
- [ ] Not running in a window; use fullscreen.
- [ ] TDP high enough (plugged in, performance profile).

If VRR cannot be made to work, use **Fixed 2x** and set the monitor to 60 Hz.
That is the clean, low-latency fallback.

## No picture / black screen

| Symptom | Cause | Fix |
|---|---|---|
| No device in VeyAmux | Wrong node selected | Pick the capture node, not the metadata node |
| Black screen at 30 fps | Format mismatch | Try MJPEG; if already MJPEG, try YUYV/NV12 |
| Picture appears then drops | Console changed resolution/HDR/refresh | VeyAmux reconnects; wait, or restart capture |
| Washed-out colours | HDR or range mismatch | HDR off on Xbox and in VeyAmux; match colour range |
| Card not found after reboot | `/dev/videoN` moved | Use `/dev/v4l/by-id/...` |

```bash
ls -l /dev/v4l/by-id/
v4l2-ctl --list-devices
```

## AppImage will not start

FUSE error:

```bash
./VeyAmux-x86_64.AppImage --appimage-extract-and-run
```

Permission error:

```bash
chmod +x VeyAmux-x86_64.AppImage
```

Do not run it with `sudo`. It needs your user's PipeWire, display and Vulkan
session.

## MJPEG warning

VeyAmux warns when the card sends compressed MJPEG while an uncompressed mode
exists.

```bash
v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext
```

If `YUYV` or `NV12` exists at 1920x1080 @ 30, switch to it. At 30 fps it is only
~124 MB/s and fits USB 3.0. It removes blocking and decode latency.

## Audio

| Symptom | Cause | Fix |
|---|---|---|
| No audio | Wrong input/output in VeyAmux | Sound tab: card input, speaker output |
| Silence only in games | Xbox set to Dolby/DTS | Xbox audio: **Stereo uncompressed** |
| Audio ahead of video | Frame gen delay | Increase audio delay in VeyAmux |
| No card audio in `wpctl` | USB 2.0 port or bad cable | Use USB-A 3.0 on the dock; try another cable |
| Crackling | Buffer too small | Raise the audio buffer/latency slightly |

Fallback routing is in `04-audio-controller.md`.

## Overlay says 30

MangoHud and other overlays are Vulkan layers. If one loads **before** lsfg-vk,
it only sees the app's real frames and reports 30 even when frame generation is
working. lsfg-vk documents this layer-order limitation.

Trust, in order:

1. VeyAmux info line (`30 -> 90`).
2. VeyAmux F3 frame-time overlay.
3. Monitor OSD (120 Hz + VRR).
4. Visible smoothness.
5. MangoHud last.

If you are debugging, launch once without any overlay.

## GPU / performance

| Symptom | Cause | Fix |
|---|---|---|
| 90 not stable | TDP too low | Plug in, performance profile, 28-40 W |
| 90 not stable | Cleanup too heavy | Upscaling off, NR low, anti-aliasing off |
| 90 not stable | 3x too much for the scene | Use 2x/60 |
| Fans loud / hot | 3x on a handheld | Cap TDP, improve airflow, accept 2x |
| Frame times alternate | VRR/pacing | Enable even pacing, confirm VRR, fullscreen |

## Rollback

1. Frame generation **Off** in VeyAmux, or start with `VEYAMUX_LSFG=0`.
2. `ujust get-lsfg uninstall` removes the layer.
3. Unplug USB and use the card's HDMI passthrough.
4. The Xbox still works straight into the monitor.

## What not to install

- OptiScaler, ReShade, DLSS Enabler: they hook a game's renderer. There is no
  game here, only a video feed.
- FSR 4 / DLSS "capture feed" DLLs: same problem, plus supply-chain risk.
- vkBasalt / ReShade as a Vulkan layer: they compete with lsfg-vk for the
  present chain.
