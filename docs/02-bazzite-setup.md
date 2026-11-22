# Bazzite setup: lsfg-vk 4x + mpv

This is the working path. Do it in Desktop Mode.

## 0. What you need

- Lossless Scaling bought and installed through **Steam**.
- lsfg-vk V2 installed on Bazzite (`ujust get-lsfg`).
- mpv with Vulkan output. **Use the native mpv**, not the Flatpak: lsfg-vk is
  a Vulkan implicit layer, and a Flatpak mpv cannot see a layer installed in
  `~/.local`. If you must use the Flatpak, install the layer into the Flatpak
  runtime as described at `https://lsfg-vk.dev/docs/installation/flatpak/`.
- The capture card at the `/dev/v4l/by-id/...` node.
- The monitor set to **1920x1080@120, SDR, 100% scaling**.

## 1. Install lsfg-vk V2

Bazzite ships a `ujust` recipe that installs the current LSFG-VK V2 layer into
`~/.local`:

```bash
ujust get-lsfg
# or non-interactive:
ujust get-lsfg install
```

It downloads from `https://builds.lsfg-vk.dev/` and installs:

```
~/.local/lib/liblsfg-vk-layer.so
~/.local/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json
~/.local/bin/lsfg-vk-cli
~/.local/bin/lsfg-vk-ui
```

Verify:

```bash
ls -l ~/.local/lib/liblsfg-vk-layer.so
ls -l ~/.local/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json
```

Status:

```bash
ujust get-lsfg status
```

Expected: `install`.

## 2. Lossless Scaling

1. Install **Lossless Scaling** from Steam.
2. Right-click it -> Properties -> **Game Versions & Betas** -> select the
   **`lsfg-vk`** branch.
3. Let Steam download the branch. lsfg-vk needs the `Lossless.dll` from it.

If the UI cannot find the DLL automatically, point it at the file manually:

```
~/.steam/steam/steamapps/common/Lossless Scaling/Lossless.dll
```

For Flatpak Steam, look under:

```
~/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling/
```

## 3. Configure lsfg-vk

Open **Configure lsfg-vk** from the application menu, or run:

```bash
~/.local/bin/lsfg-vk-ui
```

Create a profile:

| Setting | Value |
|---|---|
| Name | `mpv 4x 1080p120` |
| Active in | `mpv` |
| Multiplier | **4** |
| Flow scale | **0.50** to start |
| Performance mode | **On** |
| Pacing mode | **Vsync** |
| Allow FP16 | **On** |

Or copy `../configs/lsfg-vk-120.toml` to `~/.config/lsfg-vk/conf.toml`:

```toml
version = 2

[global]
allow_fp16 = true

[[profile]]
name = "mpv 4x 1080p120"
active_in = "mpv"
multiplier = 4
flow_scale = 0.5
performance_mode = true
pacing_mode = "vsync"
```

Validate:

```bash
~/.local/bin/lsfg-vk-cli validate
~/.local/bin/lsfg-vk-cli validate -p     # print the parsed config
~/.local/bin/lsfg-vk-cli healthcheck     # check the install itself
```

The first command must say "The configuration file is valid." The second prints
what lsfg-vk parsed. `healthcheck` should report no legacy, duplicate or
missing files.

Prove the layer works before blaming mpv:

```bash
vkcube
# expected on stderr:
# (lsfg-vk) [INFO]: Using profile with name 'mpv 4x 1080p120'
# (lsfg-vk) [INFO]:   Multiplier: 4
```

If the cube spins slower than normal and those lines appear, lsfg-vk is
working. If not, run `VK_LOADER_DEBUG=layer vkcube` and look for
`VK_LAYER_LSFGVK_frame_generation`; that is the official diagnostic.

If your build rejects `[[profile]]`, let the GUI write the file once, then copy
the values into the section it created.

## 4. Set the monitor to 120 Hz

```bash
kscreen-doctor -o
```

Find the monitor output and confirm `1920x1080@120`. If it is 60:

```bash
kscreen-doctor output.<name>.mode.1920x1080@120
kscreen-doctor output.<name>.enable
```

Also in System Settings -> Display & Monitor:

- Resolution **1920x1080**
- Refresh **120 Hz**
- Scaling **100%**
- HDR **off**
- Adaptive sync: off for the first test (try on later if you drop to 3x/90)

## 5. Verify the capture format

Use the stable by-id path, not `/dev/video0`. UVC cards often expose a metadata
node and the numbering can swap between boots:

```bash
ls -l /dev/v4l/by-id/
v4l2-ctl --list-devices
v4l2-ctl -d /dev/v4l/by-id/<your-card>-video-index0 --list-formats-ext
```

You need `1920x1080` at `30` fps. Prefer **YUYV/NV12** if the card offers it at
1080p30: it removes MJPEG artifacts and decode latency. At 1080p30 uncompressed
is only ~124 MB/s, well inside USB 3.0, so it is worth checking. `MJPG` is the
usual fallback.

If only 60 fps is listed, use the fallback in step 6.

If `v4l2-ctl` is missing:

```bash
rpm-ostree install v4l-utils
# reboot
```

## 6. Run mpv

The config is `../configs/mpv-lsfg.conf`. Minimal command:

```bash
CARD=/dev/v4l/by-id/<your-card>-video-index0
mpv av://v4l2:$CARD --fs \
  --profile=low-latency \
  --untimed \
  --video-sync=desync \
  --demuxer-lavf-o=video_size=1920x1080,framerate=30,input_format=mjpeg \
  --vo=gpu-next --gpu-api=vulkan \
  --hwdec=vaapi \
  --no-audio --no-osc --osd-level=0
```

Key points:

- `framerate=30` is the base lsfg sees. This is the 4x input.
- `--video-sync=desync` + `--untimed` stop mpv from resampling 30 -> 120
  itself. If mpv duplicates to 120 first, lsfg sees 120 and multiplies that.
- `--gpu-api=vulkan` is mandatory. lsfg-vk only hooks Vulkan apps.
- Do **not** use `--video-sync=display-resample` here.
- `--no-audio` is intentional: v4l2 is video only. Audio is routed separately
  (see `04-audio-controller.md`).

If the card will not do 30 fps at 1080p, capture 60 and drop to 30 in mpv:

```bash
mpv av://v4l2:$CARD --fs \
  --profile=low-latency --untimed --video-sync=desync \
  --demuxer-lavf-o=video_size=1920x1080,framerate=60,input_format=mjpeg \
  --vf=fps=30:round=near \
  --vo=gpu-next --gpu-api=vulkan --hwdec=vaapi \
  --no-audio --no-osc --osd-level=0
```

## 7. Confirm 120

**Do not trust MangoHud alone here.** MangoHud is a Vulkan layer too, and layer
order is not guaranteed. If MangoHud loads *before* lsfg-vk, it sees only the
app's 30 fps and reports **30 even when frame generation is working**. This is
documented by lsfg-vk itself.

Confirm in this order:

1. The terminal where you launch mpv prints lsfg lines, for example:
   `(lsfg-vk) [INFO]: Using profile with name 'mpv 4x 1080p120'` and
   `Multiplier: 4`. That means the layer is active.
2. The picture is visibly smoother than a 30 fps feed, and the monitor OSD
   confirms 120 Hz.
3. Only then use an overlay as a sanity check. If MangoHud says 30 while the
   picture is clearly smooth, it is the layer-order false negative, not a
   failure.

```bash
# overlay, if you want a number (may under-report; see above)
MANGOHUD=1 mpv av://v4l2:$CARD --fs ...
```

- ~**120**: working.
- ~**60**: multiplier 2, or the monitor is at 60 Hz.
- ~**240** or tearing: you are capturing 60 and multiplying 4x.
- ~**30** with a visibly smooth picture: MangoHud is above lsfg. Ignore it.

Launch once **without** `MANGOHUD=1` and without any other layers (VkBasalt,
vkShade) before concluding lsfg is broken.

Check the layer is loaded:

```bash
vulkaninfo --summary 2>/dev/null | grep -i lsfg
ls ~/.local/share/vulkan/implicit_layer.d/ | grep -i lsfg
```

If `vulkaninfo` is missing:

```bash
rpm-ostree install vulkan-tools
# reboot
```

## 8. Tune for the 680M

The Z2 Go's Radeon 680M has 12 CUs and the base rate is only 30 fps, so lsfg
gets ~33 ms per input frame. 4x is **likely to fit**, because the GPU is idle
most of the time between console frames. Prove it with the built-in benchmark
before changing anything:

```bash
lsfg-vk-cli benchmark -w 1920 -h 1080 -m 4 -f 0.5 -p -t 10
```

Read **Base FPS** (how many input frames per second it can process):

| Base FPS | Meaning |
|---|---|
| 60+ | 4x has plenty of headroom. Raise flow scale later. |
| 40-60 | 4x should hold at 30 fps input. |
| 33-40 | Tight. Keep flow 0.5 + performance mode. |
| under 33 | Generation alone cannot keep up. Use 3x. |

The benchmark is generation-only, so leave it some headroom. For a
representative number, run mpv (or a 1080p30 video) in the background while it
runs.

Then tune in this order:

1. Stable 120? Raise flow scale to 0.65, then 0.75. Higher looks better, costs
   more.
2. Not stable? Keep flow 0.5 and performance mode on, and check TDP: plug in
   and use a performance profile. At 15 W the 680M clocks down and 4x can
   collapse.
3. Still not stable? Drop multiplier to **3** (90 fps). 90 is an exact multiple
   of 30, but most 120 Hz panels do not have a 90 Hz mode, so enable VRR if the
   monitor supports it. 90 without VRR judders.
4. Still not stable? Capture at **1600x900** or **1280x720** and let mpv scale
   to 1080p. LSFG cost scales with resolution.
5. Last resort: **2x** (60 fps) with the monitor at 60 Hz. Smooth, low
   artifacts, no 120.

4x means the GPU generates **90 frames per second** on top of decoding and
presenting. That is the real cost, not the multiplier itself. The honest
trade-off at 4x is quality: 30 fps base means large disocclusions, so expect
halos around the car and smearing on HUD text during fast pans. 3x has fewer
artifacts and may look better even when 4x runs fine.

## 9. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| FPS stays 30 | lsfg not active | `lsfg-vk-cli validate`, check `active_in = "mpv"`, check the Vulkan layer file |
| FPS stays 60 | multiplier 2, or display 60 Hz | Multiplier 4, `kscreen-doctor` 120 |
| FPS 240 / tearing | capturing 60, 4x | `framerate=30` or `--vf=fps=30:round=near` |
| Stutter every second | mpv resampling to 120 before lsfg | `--video-sync=desync --untimed` |
| lsfg works in games but not mpv | mpv not on Vulkan | `--gpu-api=vulkan --vo=gpu-next` |
| lsfg active in games, never in mpv | mpv is a Flatpak | Install the layer into the Flatpak runtime, or use the native/Bazzite mpv |
| Frame gen starts then stops fullscreen | Wayland + vsync pacing | Run mpv windowed for the test, or use an X11 session |
| Nothing hooks, no log lines | profile name mismatch | `VK_LOADER_DEBUG=layer mpv ...` and look for `VK_LAYER_LSFGVK_frame_generation`; try `LSFGVK_ENV=1` |
| Worked until MangoHud/VkBasalt | another Vulkan layer | Test without `MANGOHUD=1` and without other layers |
| Heavy ghosting | 4x + high flow scale | flow 0.5, performance mode; compare 3x |
| GPU pegged, below 120 | 680M limit | 3x, 900p, or 2x/60 |
| Black screen | wrong format / hwdec | `input_format=yuyv422`, try `--hwdec=no` |
| Washed-out colours | HDR on | HDR off in Xbox and KDE |
| No audio | v4l2 is video only | Loop the card source to speakers |
| Screen stuck at 60 after reboot | KDE reset the mode | Re-apply 120 Hz in Display settings |

## 10. Success criteria

- [ ] `ujust get-lsfg status` says `install`.
- [ ] `lsfg-vk-cli healthcheck` reports no issues.
- [ ] `lsfg-vk-cli validate` passes.
- [ ] `vkcube` prints `(lsfg-vk)` lines and spins slower than normal.
- [ ] `kscreen-doctor -o` shows 1920x1080@120.
- [ ] `v4l2-ctl` shows 1080p30 on the by-id node.
- [ ] mpv without lsfg shows a stable 30 fps feed.
- [ ] The `(lsfg-vk)` lines appear, and the picture is visibly smoother.
- [ ] 10 minutes of driving: no desync, no black frames, HUD readable.
- [ ] You prefer it to 30 fps native. If not, use 2x/60 or passthrough.
