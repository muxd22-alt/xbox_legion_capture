# Handoff - 2026-11-24

## Repo / PR

- Branch: `feature/three-modes`
- PR: #1 (draft), `muxd22-alt/xbox_legion_capture`
- Local commits: `eb88438` (measured results) and this handoff commit.
- **Not pushed.** Push the branch to update PR #1:

```bash
cd /var/home/muxd/Downloads/XBOX_STREAMING
git push origin feature/three-modes
```

### GitHub auth

- GitHub Desktop is installed as the Flatpak `io.github.shiftey.Desktop`.
  Sign in there once, open this repository, select `feature/three-modes`, and
  press **Push origin**.
- The CLI has **no credential helper** configured. Do not use
  `git config credential.helper store` for a PAT; that writes the secret in
  plaintext.
- For persistent CLI/agent pushes, a dedicated SSH key is already generated:
  - Private key: `~/.ssh/id_ed25519_github` (mode 600, no passphrase)
  - Public key/fingerprint:
    ```
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxQJzDWH9ibn6UvW5U3Yu0rYEhL6bQv9Vz4TWgWplqq bazzite-legion-go-s-agent
    256 SHA256:kCQcWD3j+1sd240M/bwdScFnSKrxtdjnAlVY5mJyy+4
    ```
  - Add the public key at <https://github.com/settings/ssh/new> (title
    `Bazzite Legion Go S`), then push with:
    ```bash
    git push ssh feature/three-modes
    ```
  - The `ssh` remote is already configured; the `origin` HTTPS remote is left
    alone for GitHub Desktop. Never copy the private key into the repo or chat.

## Sunshine

The user fixed Sunshine. **Leave it alone.** Do not edit
`~/.config/sunshine/`, the service, credentials, or CSRF settings.

## Current hardware state

At the last check the capture card and TV were disconnected; the Legion was on
`eDP-1` at 1920x1080 @ 59.96. The capture measurements in `RESULTS.md` are from
the connected session.

When the card is reconnected:

- Capture **1920x1080 @ 30 fps MJPG**, not 1080p60. The MS2109 is USB 2.0 and
  1080p60 overruns the link.
- VeyAmux: **Lossless Scaling Fixed 2x**, Even out frame pacing on. Info line
  should read `1920x1080 @ 30 fps -> 60 fps (Lossless Scaling 2x)`.
- The saved profile `4x` is bound to `1920x1080@30 MJPEG` and is the default.

## Pending / blocked

- **DeckyMultiFrameGen:** ZIP staged at `~/Downloads/Decky-MultiFrameGen.zip`.
  Install via **Game Mode -> Decky -> Settings -> Developer -> Install Plugin
  from ZIP**, then install OptiScaler and HelixSR from the plugin's Backends
  panel. One backend per game; single-player only; leave MAKO/ANR FG off.
- **Sunshine KMS + Fold 4 / Moonlight V+:** host configured (`hevc_mode = 1`,
  two apps added, HEVC 1080p60/50M smoke test passes). KMS capture and the Fold
  client are untested. Do not change Sunshine without the user.
- **MAKO 5.0:** checked and parked. `docs/11-mako-5.md`; `scripts/check-mako.sh`.
  It is not a VeyAmux drop-in and must not stack with lsfg-vk.
- **mpv:** Flatpak 0.42.0 + MPV Anime Build v5.6 is installed at
  `~/.var/app/io.mpv.Mpv/config/mpv`; the Linux/AMD patch is applied. A
  5-minute anime playback test is still pending.

## Useful checks

```bash
./scripts/check-stream.sh
./scripts/check-native-games.sh
./scripts/check-video-playback.sh
./scripts/check-mako.sh
```

Read `RESULTS.md` for the measured numbers and the USB 2.0 capture proof.
