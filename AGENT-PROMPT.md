# Agent handoff prompt

Copy everything between the lines into your agent when you are at the setup
with the real hardware. It assumes the agent can run commands on the Legion.

---

You are setting up a console-capture frame-generation rig on a Legion Go S
running Bazzite. Work from the repo at
https://github.com/muxd22-alt/xbox_legion_capture (clone it if it is not
already on the machine).

**Goal:** Xbox Series S -> Joyzzz USB capture card -> Legion Go S (Bazzite) ->
**VeyAmux** -> **90 fps** on a 1080p monitor running **120 Hz with VRR**.

**The number:** capture 30 fps, VeyAmux frame generation **3x**, display 120 Hz
+ VRR. `30 x 3 = 90`. Do not chase 120; VeyAmux exposes 2x/3x only.

**Hardware:**
- Xbox Series S, controller paired to the Xbox.
- Joyzzz capture card: HDMI in, USB 3.0 out, 1080p60 capture.
- JSAUX 6-in-1 dock: HDMI 2.1, 3x USB-A 3.0, 100W PD.
- Legion Go S: AMD Z2 Go / Radeon 680M (12 CU), Bazzite, KDE Plasma.
- 1080p120 monitor with VRR.

**Non-goals - do not set these up:** TV, Xiaomi box, Sunshine, Moonlight,
network streaming, 4K, HDR, Windows, Veyra, OptiScaler, ReShade, DLSS Enabler.
Keep HDR off end to end.

**Rules:**
- One change at a time, then re-test.
- Prefer reversible changes. Do not uninstall anything or edit outside
  `~/.config`, `~/.local` and this repo without asking me.
- Ask before `rpm-ostree install` (it needs a reboot) or any Xbox change you
  cannot verify yourself.
- Do not buy or install Lossless Scaling; I own it. It must be on the Steam
  `lsfg-vk` beta branch.
- Do not run the VeyAmux AppImage with `sudo`.
- I cannot see the screen through you. Tell me exactly what to look at when a
  visual check is needed.

**Do this in order, and stop at the first failure:**

1. Collect facts and show output:
   `bazzite-version`, `plasmashell --version`, `kscreen-doctor -o`,
   `ls -l /dev/v4l/by-id/`, `v4l2-ctl --list-devices`,
   `v4l2-ctl -d /dev/v4l/by-id/<card>-video-index0 --list-formats-ext`,
   `wpctl status`, `ujust get-lsfg status`, `lsfg-vk-cli healthcheck`,
   `lsfg-vk-cli validate`, and whether Lossless Scaling is on the `lsfg-vk`
   branch. Use the by-id node, not `/dev/video0`.

2. Display. Confirm the external output is **1920x1080 @ 120 Hz** with
   **VRR/Adaptive Sync on**, scaling 100%, HDR off. VRR is required for 90 fps
   to look even. Fix this before anything else.

3. Capture. Find the real capture node and confirm **1920x1080 @ 30 fps**.
   Note MJPG vs YUYV/NV12. Prefer uncompressed at 30. Pass: 30 fps listed.

4. Lossless Scaling + lsfg-vk. Confirm the Steam **`lsfg-vk`** branch is
   installed, `ujust get-lsfg status` says `install`, and `lsfg-vk-cli
   healthcheck` reports no issues.

5. VeyAmux. Download the latest AppImage from the project's releases, `chmod
   +x`, run as my user. If FUSE fails, use `--appimage-extract-and-run`. Do not
   use sudo.

6. Source and audio. In VeyAmux choose the capture card, 1920x1080 @ 30, the
   best format offered, and the card's audio input plus the correct output.
   Confirm the sound meter moves.

7. Picture. Upscaling off/1:1 (1.5x max), noise reduction light, anti-flicker
   on, sharpness light, HDR off. Do not stack 2x/3x upscaling on top of 3x
   frame generation before measuring.

8. Frame generation. Method Lossless Scaling, **Fixed 3x**. Status must say
   **"Active through lsfg-vk"**. Info line should read
   `≈1920×1080 @ 30 fps -> 90 fps (Lossless Scaling 3×)`. If it says 60, the
   multiplier is 2x.

9. Verify motion. F3 frame-time overlay should be steady, not alternating.
   Monitor OSD should show 120 Hz with VRR active. The picture should be
   visibly smoother than 30 fps. If an overlay reports 30, remember it may load
   above lsfg-vk; trust VeyAmux first.

10. Soak test: 10 minutes of GTA VI driving. Check for uneven motion, black
    frames, HUD readability, audio sync, and whether I prefer it to 30 fps
    native.

**Fallback ladder if 90 does not hold:**
1. Check TDP: plugged in, performance profile, 28-40 W. At 15 W the 680M
   clocks down and 3x can collapse.
2. Upscaling off, noise reduction light, anti-aliasing off.
3. Enable "even out frame pacing" if offered.
4. Confirm VRR is actually active in KDE and the monitor OSD.
5. Switch to **Fixed 2x** and set the monitor to 60 Hz. Clean, low-latency.
6. Use the capture card's HDMI passthrough as the baseline.

**Troubleshooting notes:**
- `The specified shader DLL does not exist` or `Only Lossless.dll was found`
  means Steam is still on the normal branch.
- `lsfg-vk is not installed` -> VeyAmux's install button or
  `ujust get-lsfg install`.
- `LSFGVK_*` env vars are ignored unless `LSFGVK_ENV=1`.
- Log: `~/.config/VeyAmux/lsfg-vk.log`.
- MJPEG warning -> switch to YUYV/NV12 if the card offers it at 1080p30.
- The card's audio is separate; use VeyAmux's Sound tab.
- If the AppImage will not start, try `--appimage-extract-and-run` before
  changing anything else.

**Report back with:** the exact commands run, their output, the final
resolution/refresh/VRR state, the VeyAmux info line, measured frame times, and
which fallback (if any) we landed on. Write the result into a new file
`RESULTS.md` in the repo, then stop.

---
