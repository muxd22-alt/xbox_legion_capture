# 07 - Native games on the Legion Go S

This mode is the Legion playing its own Steam library. It has nothing to do with
the capture card and nothing to do with VeyAmux. The picture path is:

```
Game (DX12, Proton Experimental)
  | game's own DLSS / FSR 2+ / XeSS option
  v
HelixSR Scaler  OR  OptiScaler + FSR 4.1.2 Lite   (per game, one only)
  v
1920x1080 panel, 60 Hz (or 90 Hz only if the game holds it)
```

FSR 4, DLSS and XeSS need the game's motion vectors and depth buffer. A native
game has them; the Xbox capture feed does not. That is why this mode can use
them and mode 1 cannot.

> Status: **UNTESTED on the Legion Go S.** Every step below is the plan the
> on-device agent executes and measures. No frame times are claimed here.

## What is installed, and why

| Piece | Role | Licence / source |
|---|---|---|
| Decky Loader | Homebrew plugin host in Game Mode | https://github.com/SteamDeckHomebrew/decky-loader |
| DeckyMultiFrameGen | One panel that installs/removes the backends per game | GPL-3.0, https://github.com/MWGIH/DeckyMultiFrameGen |
| HelixSR | DLSS/FSR 4 networks as plain compute shaders on RDNA2 | Freeware, source not published; Scaler is GPL-3.0. https://github.com/lonewolf0622/HelixSR |
| OptiScaler (via Decky Framegen) | Turns the game's DLSS/FSR/XeSS hook into FSR 4.1.2 Lite | GPL-3.0, bundled by DeckyMultiFrameGen |
| Proton Experimental | The only Proton this mode supports | Valve |

**One backend per game.** HelixSR and OptiScaler both hook the same DX12 call.
Running both is not supported and is the usual cause of a black screen.

## Preconditions

Do not start until all of these are true:

1. Bazzite is booted into **Desktop Mode** for installation. Game Mode is only
   for testing.
2. The game is **single-player**. See the anti-cheat rule below.
3. The game exposes **DLSS, FSR 2 or newer, or XeSS** in its own graphics menu.
   A game with none of these cannot use this mode.
4. The game is forced to **Proton Experimental** (Steam -> game -> Properties ->
   Compatibility -> Force the use of a specific Steam Play compatibility tool).
5. You accept the RDNA2 cost warning at the bottom of this page.

## Install Decky Loader

In Desktop Mode, open Konsole and run the official installer:

```bash
curl -L https://github.com/SteamDeckHomebrew/decky-installer/releases/latest/download/install_release.sh | sh
```

Then, in Game Mode:

1. Open the Quick Access Menu (`...`).
2. Open the new **Decky** icon (plug).
3. Settings -> **Developer mode** (required to install a plugin from a URL).

If the Decky icon never appears after a reboot, check
`~/homebrew/services/PluginLoader` and the `plugin_loader.log` next to it. Do
not install a second copy of Decky.

## Install DeckyMultiFrameGen

In Decky -> Settings -> Developer -> **Install Plugin from URL**, enter:

```
https://github.com/MWGIH/DeckyMultiFrameGen/releases/latest/download/Decky-MultiFrameGen.zip
```

The ZIP from the latest release also works with **Install Plugin from ZIP** and
is the fallback if the URL install stalls.

Open the plugin. Under **Backends**:

1. Install **OptiScaler** (Decky Framegen bundle). This is the path that offers
   AMD's small **FSR 4.1.2 Lite** model, the handheld build.
2. Install **HelixSR**. Let its setup download and build what it needs. This is
   the path for games whose DLSS/XeSS option you want to keep.
3. Leave MAKO and ANR FG off for this rig. They are frame generation layers, not
   upscalers, and this guide does frame generation once, on the Legion, only in
   capture mode. MAKO 5.0 is checked separately in `docs/11-mako-5.md`: it cannot
   use VeyAmux's duplicate removal and must not stack with lsfg-vk.

`Build Preset K` and `Build Vulkan kernels` are optional and slow to build.
Leave them off for the first pass; they are not needed for FSR 4.1.2 Lite.

## Per-game setup

Pick **exactly one** row.

### A. FSR 4.1.2 Lite through OptiScaler

Use this when the game offers DLSS, FSR 2/3 or XeSS and you want AMD's small
FSR 4 model on the 680M.

1. In the plugin, select the game, set **Use -> OptiScaler**.
2. Open the game's panel and set the FSR 4 model to **AMD FSR 4.1.2 Lite**.
   This is the small model AMD ships for handheld chips. If the panel offers
   Valve's FSR 4.1.1 build, Cyboman's Lossy builds and stock FSR 4.0.2 as well,
   pick **4.1.2 Lite**, not the Valve build.
3. In the game, select **DLSS** (or FSR/XeSS if that is all it has). OptiScaler
   replaces the call; the game's own option is the switch.
4. Launch. Open OptiScaler's overlay with `Insert`.

Pass: the overlay names **FSR 4.1.2 Lite** as the active upscaler, the game's
internal render resolution is lower than 1080p, and the image is stable.

### B. HelixSR through the game's DLSS

Use this when the game's DLSS is good, when OptiScaler's proxy DLL will not
load, or when you want an alternative to compare against row A.

1. In the plugin, set **Use -> HelixSR**, method **HelixSR Scaler**.
2. In the game, select **DLSS** and pick the quality mode you want.
3. `Insert` opens HelixSR Scaler's menu. Under **DLSS Upscaler**, leave
   **HLX DLSS** selected (Preset K only if you built it).

On RDNA2, HelixSR's README marks HLX DLSS and HLX FSR 4 as *expected, int8*,
not tested on this exact iGPU. The on-device agent must confirm which one
actually runs and record the ms.

### C. FSR 4.1.2 Lite as a drop-in (FSR 3.1 games only)

Only for a game that ships FSR 3.1.x. In the plugin use **FSR drop-in**, then
select **AMD FSR** in the game. Do not use this on a game with anti-cheat that
checks files; the plugin itself warns and offers OptiScaler instead.

## Confirm FSR 4 is really running

Three independent checks; all three must agree.

1. **Watermark.** Turn on the FSR 4 watermark:
   - FSR4 Injector backend: add `FSR_WATERMARK=1 %command%` to the game's
     launch options.
   - OptiScaler backend: enable the FSR 4 watermark in OptiScaler's own menu
     (`Insert`). Exact label depends on the OptiScaler build the plugin installed.
   - HelixSR: the plugin's game panel shows whether HLX FSR 4 / HLX DLSS ran in
     the last session. Read that instead of expecting AMD's watermark.
2. **Overlay.** `Insert` shows the active upscaler and the internal resolution.
   "FSR 3" or "FSR 2" means the small model did not load.
3. **Log.** The game panel exposes the log:
   - OptiScaler -> `OptiScaler.log` next to the game's .exe.
   - HelixSR -> `HelixSR\helixsr.log`.
   - Drop-in -> `HLX_FSR.log`.

If the overlay says FSR 4 but the watermark does not appear, trust the overlay
and the log, and say so in the report. Watermarks differ per backend.

## Rollback

Every backend writes only into the game folder and its Steam launch options, and
every one of them keeps a backup.

1. DeckyMultiFrameGen -> game -> **Use -> Off**. This unpatches the game and
   restores the launch options it added.
2. If a game still will not start: Steam -> Properties -> Installed Files ->
   **Verify integrity of game files**.
3. HelixSR has its own `helixsr-uninstall.sh`; running it removes what the setup
   built. Do not delete `HelixSR/` by hand while a game still points at it.
4. To go back to stock behaviour for one session only, remove the added
   launch options and rename the proxy DLL (`dxgi.dll`, `winmm.dll`,
   `version.dll`, `dbghelp.dll`) back to what it was.

## Anti-cheat rule - hard

**Never** use this mode on a multiplayer game with Easy Anti-Cheat, BattlEye or
any kernel-level anti-cheat, even though HelixSR can sometimes get past EAC.
Adding DLLs to a protected game is a ban risk and is outside what this repo
supports. Single-player only. If the plugin shows an anti-cheat warning, stop.

## RDNA2 cost warning

The 680M has 12 CUs, no matrix hardware and shared 16 GB memory. FSR 4.1.2 Lite
is the smallest FSR 4 model, but it is still a network running as compute
shaders. Expect it to cost **more** than FSR 2/3 at the same output size, and
expect the gain to be sharpness, not free frames.

Practical consequences:

- Do not combine this with LSFG frame generation in a native game. Pick one.
- Do not run HelixSR and OptiScaler at once.
- 1080p output only. 1440p/4K native on this iGPU is not a target.
- If a game drops below 40 fps with the upscaler on, turn it off and lower the
  in-game preset instead. The upscaler cannot create GPU time.
- Plugged in, performance TDP. On battery the iGPU clocks down and the upscaler
  cost becomes a larger share of the frame.

## Measured results (fill in on the Legion)

| Game | Backend | Model | Internal res | Output | GPU ms | FPS | Verdict |
|---|---|---|---|---|---|---|---|
| UNTESTED | | | | | | | |

Measurement: OptiScaler overlay or HelixSR log for the upscaler ms, MangoHud for
frame time, 10 minutes of play. Record the number, not an impression.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Game starts, no overlay on `Insert` | Proxy DLL not loaded | Change Proxy DLL in the game panel: `dxgi` -> `winmm` -> `version` -> `dbghelp` |
| Black screen after the splash | Two backends in one game | Use -> Off, then pick one backend |
| Overlay says FSR 2/3 | FSR 4 model did not load | Reinstall the backend, confirm Proton Experimental, re-check the model in the panel |
| Game crashes on launch | Anti-cheat, or a Vulkan game with `dxgi.dll` | Stop if anti-cheat; for Vulkan try `dbghelp.dll` |
| Video plays, game audio only | Unrelated to upscaling | Check the Steam audio device, not this guide |
| Plugin update broke a game | Backend version drift | Use -> Off, Verify files, reinstall the backend |

Logs to attach to a bug report: `OptiScaler.log`, `helixsr.log`,
`HLX_FSR.log`, Steam launch options for the game, and the Bazzite version
(`bazzite-version`).
