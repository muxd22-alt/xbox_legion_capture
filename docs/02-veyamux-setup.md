# VeyAmux setup

Goal: **Xbox -> capture card -> VeyAmux -> 90 fps on a 120 Hz VRR monitor.**

Do this in Desktop Mode on the Legion. One change at a time.

## 0. What you need

- Xbox Series S, controller, HDMI cable.
- Joyzzz capture card and a USB 3.0 cable.
- JSAUX dock, Legion charger, HDMI cable to the monitor.
- Legion Go S on Bazzite, updated, plugged in.
- Monitor set to **1920x1080 @ 120 Hz with VRR/Adaptive Sync on**.
- Lossless Scaling owned on Steam (only needed for its frame generation).
- VeyAmux AppImage.

## 1. Lossless Scaling

VeyAmux does not ship Lossless Scaling; it uses your copy.

1. Install **Lossless Scaling** from Steam.
2. Library -> right-click Lossless Scaling -> **Properties** -> **Betas** ->
   select the **`lsfg-vk`** branch.
3. Let Steam download it.

The normal branch only has `Lossless.dll`. lsfg-vk 2 needs the shaders from the
`lsfg-vk` branch, or you get `The specified shader DLL does not exist`.

VeyAmux finds Lossless Scaling in all Steam libraries, including the Flatpak
one.

## 2. lsfg-vk 2

Two options:

```bash
# Bazzite recipe
ujust get-lsfg install
ujust get-lsfg status        # expect: install
```

or, inside VeyAmux, use **Frame generation -> Install lsfg-vk 2**.

VeyAmux's automatic install downloads the official build from
`builds.lsfg-vk.dev`, checks it against a known SHA-256 and unpacks it into
`~/.local`. To turn that off, start it with `VEYAMUX_LSFG_AUTOINSTALL=0`.

Verify:

```bash
~/.local/bin/lsfg-vk-cli healthcheck
~/.local/bin/lsfg-vk-cli validate
```

`healthcheck` should report no legacy, duplicate or missing files.

## 3. Download and run VeyAmux

- Releases: https://github.com/8BiTw0LF/VeyAmux/releases
- Take the latest `VeyAmux-x86_64.AppImage` (1.7 at the time of writing).
- The AppImage is unsigned and unsandboxed. Download it from the release page,
  run it as your user, never with `sudo`.

```bash
chmod +x VeyAmux-x86_64.AppImage
./VeyAmux-x86_64.AppImage
```

If the AppImage refuses to start with a FUSE error:

```bash
./VeyAmux-x86_64.AppImage --appimage-extract-and-run
```

Start without frame generation at any time:

```bash
VEYAMUX_LSFG=0 ./VeyAmux-x86_64.AppImage
```

## 4. Capture source and audio

On the start screen choose **Capture card**.

- Select the **capture card**, not a metadata node.
- Resolution **1920x1080**, frame rate **30** (or 60 if that is all the card
  offers; VeyAmux removes duplicates).
- Prefer **YUYV/NV12** if the card lists it at 1080p30. If it only has MJPEG,
  VeyAmux will warn you when an uncompressed mode exists.
- **Sound:** pick the capture card's input in the Sound tab, and your speakers
  or headphones as the output. There is a sound meter and an audio delay
  control.

Keep the Xbox on **Stereo uncompressed**. Dolby/DTS bitstream usually gives
silence over a budget UVC card.

## 5. Picture cleanup

Open the menu with **P** (or Select + Start on a controller).

At 1080p -> 1080p there is nothing to enlarge. Spend the GPU on cleanup, not on
upscaling:

| Setting | Start with |
|---|---|
| Upscaling | **Off/1:1** if offered; otherwise **1.5x** maximum |
| Noise reduction | **Spatial** (MJPEG) or **Both**, low/medium |
| Anti-flicker | **On** |
| Sharpness | light |
| Anti-aliasing | Off or SMAA light |
| FSR 3.1.6 | Native AA only if you want TAA-like edge calming |
| Texture / clarity / dehaze | 0 to start; small amounts later |
| HDR | **Off** |

Notes:

- 2x/3x upscaling renders above 1080p and scales back down. It looks slightly
  different and costs real GPU time that 3x frame generation needs.
- Noise reduction before sharpening is the important order. It removes MJPEG
  blocking so sharpening does not amplify it.
- Anti-flicker calms thin lines and foliage without delaying the whole frame.
- GTA VI already uses TAA. Adding another temporal AA pass can soften the image.

## 6. Frame generation: Fixed 3x

In the **Frame generation** tab:

1. Choose **Lossless Scaling** as the method.
2. Set **Fixed 3x**.
3. If the menu shows **Restart now**, press it.
4. The status box must say **"Active through lsfg-vk"**.

Do not choose the free **AMD FSR 3.1.6 2x** for this goal. It is 2x, not 3x.

VeyAmux writes its own profile at `~/.config/VeyAmux/lsfg-vk.toml` and leaves
your other lsfg profiles alone. You do not need the lsfg UI or a hand-written
profile.

If there is an **even out frame pacing** toggle, enable it. It costs about one
refresh of latency and makes 3x land evenly.

## 7. Display: 120 Hz + VRR

In KDE and in the monitor's OSD:

- Resolution **1920x1080**
- Refresh **120 Hz**
- **VRR / Adaptive Sync / FreeSync: on**
- Scaling **100%**
- HDR **off**
- Game/Overdrive picture mode

90 fps on 120 Hz only looks even with VRR. Check that VRR is actually active;
some monitors require it in the OSD as well as in KDE.

```bash
kscreen-doctor -o
```

You want the monitor output enabled at `1920x1080@120`, with adaptive sync on.

## 8. Confirm 90

- VeyAmux's info line should read like
  `≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×)`.
- **F3** opens the frame-time overlay. Frame times should be steady, not
  alternating long/short.
- The monitor OSD should show 120 Hz with VRR active.
- The picture should be visibly smoother than 30 fps while driving.

Check the log if something is off:

```bash
tail -n 50 ~/.config/VeyAmux/lsfg-vk.log
```

MangoHud is not needed here, and if you use it, it can under-report: it is a
Vulkan layer and may load above lsfg-vk, so it sees only the app's frames. Trust
VeyAmux's info line, the F3 overlay and the monitor OSD first.

## 9. Tune for the 680M

The Z2 Go has a full 12-CU Radeon 680M. At a 30 fps base there is real headroom,
but 3x still means generating **60 extra frames per second**.

Order:

1. **Plug in and use a performance TDP.** At 15 W the 680M clocks down and 90
   can collapse. 28-40 W is the useful range.
2. Keep **noise reduction light** and **upscaling off/1x**. These are the first
   costs to cut.
3. If frame times are uneven, enable **even out frame pacing**.
4. If 90 still will not hold, switch frame generation to **Fixed 2x** and set
   the monitor to 60 Hz. You lose 90 but gain the lowest latency and the
   cleanest image.
5. If the card is sending MJPEG and offers YUYV/NV12 at 1080p30, switch the
   capture format. That frees CPU and removes blocking.

Do not expect 4x/120 from VeyAmux. It exposes 2x/3x only.

## 10. Success criteria

- [ ] Lossless Scaling is on the `lsfg-vk` Steam branch.
- [ ] `lsfg-vk-cli healthcheck` reports no issues.
- [ ] VeyAmux starts and sees the capture card.
- [ ] Capture is 1920x1080 at 30 fps on the by-id node.
- [ ] Monitor is 1920x1080@120 with VRR active.
- [ ] Frame generation status says **"Active through lsfg-vk"**.
- [ ] VeyAmux info line says `30 fps -> 90 fps (Lossless Scaling 3×)`.
- [ ] 10 minutes of driving: even motion, no black frames, readable HUD.
- [ ] You prefer it to 30 fps native. If not, use 2x/60 or passthrough.
