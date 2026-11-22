# Agent handoff prompt

Copy everything between the lines into your agent when you are at the setup
with the real hardware. It assumes the agent can run commands on the Legion.

---

You are setting up a local console-capture frame-generation rig on a Legion Go S
running Bazzite. Work from the repo at
https://github.com/muxd22-alt/xbox_legion_capture (clone it if it is not
already on the machine).

**Goal:** Xbox Series S -> Joyzzz USB capture card -> Legion Go S (Bazzite) ->
`mpv` + `lsfg-vk` -> **1920x1080 @ 120 Hz, SDR, 1:1** on an external monitor.

**The one number:** capture **30 fps**, lsfg-vk multiplier **4**, display
**120 Hz**. `30 x 4 = 120`. lsfg-vk does not remove duplicate frames, so do not
capture 60 and use 2x.

**Hardware:**
- Xbox Series S, controller paired to the Xbox.
- Joyzzz capture card: HDMI in, USB 3.0 out, 4K30 passthrough, 1080p60 capture.
- JSAUX 6-in-1 dock: HDMI 2.1, 3x USB-A 3.0, 100W PD.
- Legion Go S: AMD Z2 Go / Radeon 680M, Bazzite, KDE Plasma.
- External 1080p120 monitor.

**Non-goals — do not set these up:** TV, Xiaomi box, Sunshine, Moonlight,
network streaming, 4K, HDR, Windows, Veyra. HDR stays off end to end.

**Read first:** `README.md`, `docs/02-bazzite-setup.md`, `docs/03-checklist.md`,
`docs/05-settings.md`.

**Rules:**
- Make one change at a time and re-test.
- Prefer reversible changes. Do not uninstall anything or edit files outside
  `~/.config`, `~/.local`, and the repo without asking me.
- Ask before `rpm-ostree install` (it needs a reboot) or any Xbox setting change
  you cannot verify yourself.
- Do not buy or install Lossless Scaling; I already own it. It must be on the
  Steam `lsfg-vk` branch.
- I cannot see the screen through you, so tell me exactly what to look at when
  a visual check is needed.

**Do this in order, and stop at the first failure:**

1. Collect facts and show me the output:
   `bazzite-version`, `plasmashell --version`, `mpv --version`,
   `kscreen-doctor -o`, `v4l2-ctl --list-devices`,
   `v4l2-ctl -d <capture-node> --list-formats-ext`, `wpctl status`,
   `ujust get-lsfg status`, `lsfg-vk-cli validate`, `lsfg-vk-cli healthcheck`.

2. Display. Confirm the external output is **1920x1080@120**, scaling 100%,
   HDR off. If it is 60 Hz, fix it before anything else. Pass: `kscreen-doctor`
   shows 120.

3. Capture. Find the real capture node (UVC cards often expose a metadata node
   too). Confirm **1920x1080 @ 30 fps** exists. Note MJPG vs YUYV. Pass: 30 fps
   listed.

4. lsfg-vk. Profile must be active for `mpv`, multiplier 4, flow_scale 0.5,
   performance_mode true, pacing_mode vsync, allow_fp16 true. Run `vkcube` and
   confirm the `(lsfg-vk)` lines and that the cube spins slower than normal.
   Pass: profile is selected and frames are generated.

5. mpv baseline with lsfg disabled: stable 30 fps, correct colours, no black
   frames. Pass: 30 fps for 2 minutes.

6. mpv with lsfg enabled: MangoHud should read ~120. If frame gen does not
   start, re-test without MangoHud and without other Vulkan layers. Pass: ~120
   and playable.

7. Soak test: 10 minutes of GTA VI driving. Check for desync, black frames,
   HUD readability, and whether I prefer it to 30 fps native.

**Fallback ladder if 120 does not hold:**
1. Raise flow_scale 0.5 -> 0.65 -> 0.75.
2. Keep performance mode on, lower flow_scale back to 0.5.
3. Multiplier 3 (90 fps) and enable VRR on the monitor.
4. Capture 1600x900 or 1280x720, let mpv scale to 1080p.
5. Multiplier 2 at 60 Hz.
6. Use the capture card's HDMI passthrough (no software) as the baseline.

**Troubleshooting notes:**
- Always run `lsfg-vk-cli validate` and `healthcheck` before blaming mpv.
- Confirm the layer loads with `VK_LOADER_DEBUG=layer mpv ...` and look for
  `VK_LAYER_LSFGVK_frame_generation`.
- A Flatpak mpv will not see the layer. Use native mpv.
- `--gpu-api=vulkan` is mandatory.
- If Wayland fullscreen breaks pacing, test windowed once.
- MJPEG + `--hwdec=vaapi` can black-screen; try `--hwdec=no`.
- The card's audio is a separate PipeWire source; mpv's v4l2 input is video
  only. Use `pw-link` or a loopback.

**Report back with:** the exact commands run, their output, the final
resolution/refresh, measured fps, and which fallback (if any) we landed on.
Write the result into a new file `RESULTS.md` in the repo, then stop.

---
