#!/usr/bin/env bash
# check-video-playback.sh - verify mpv + MPV Anime Build on Bazzite.
#
# Read-only. Does not download, install or touch the mpv config.
# Usage: ./scripts/check-video-playback.sh

set -u
fail=0
skip=0

say() { printf '\n== %s ==\n' "$1"; }
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
note(){ printf '  NOTE  %s\n' "$1"; }
skp() { printf '  SKIP  %s\n' "$1"; skip=$((skip + 1)); }
have(){ command -v "$1" >/dev/null 2>&1; }

say "mpv"
mpv_flatpak=0
if have flatpak && flatpak info io.mpv.Mpv >/dev/null 2>&1; then
  mpv_flatpak=1
  ok "Flatpak io.mpv.Mpv installed"
elif have mpv; then
  ok "system mpv: $(mpv --version 2>/dev/null | head -n 1)"
else
  bad "no mpv (Flatpak or native) found"
fi

say "Config location"
cfg=""
for d in "$HOME/.var/app/io.mpv.Mpv/config/mpv" "$HOME/.config/mpv"; do
  if [ -d "$d" ]; then cfg="$d"; break; fi
done
if [ -n "$cfg" ]; then
  ok "$cfg"
else
  bad "no mpv config directory (expected ~/.config/mpv or the Flatpak path)"
fi

if [ -n "$cfg" ]; then
  say "MPV Anime Build files"
  for f in mpv.conf input.conf scripts script-opts shaders fonts; do
    if [ -e "$cfg/$f" ]; then ok "$f"; else bad "$f missing"; fi
  done
  if ls "$cfg"/user-*.conf >/dev/null 2>&1; then
    printf '  user overrides: '; ls "$cfg"/user-*.conf | xargs -n1 basename | tr '\n' ' '; printf '\n'
  else
    note "no user-*.conf yet (the build creates one on the first menu change)"
  fi
  nconf="$(ls "$cfg"/mpv-*.conf 2>/dev/null | wc -l)"
  if [ "$nconf" -gt 1 ]; then
    bad "$nconf mpv-*.conf files; the build loads none when more than one exists"
  elif [ "$nconf" -eq 1 ]; then
    ok "exactly one personal override: $(ls "$cfg"/mpv-*.conf | xargs -n1 basename)"
  fi

  say "Shaders"
  if [ -d "$cfg/shaders" ]; then
    total="$(find "$cfg/shaders" -maxdepth 1 -type f -name '*.glsl' | wc -l)"
    printf '  %s GLSL shaders\n' "$total"
    [ "$total" -ge 20 ] && ok "shader pack looks complete" || bad "shader pack looks incomplete"
    for pat in 'Anime4K' 'FSRCNNX' 'ArtCNN'; do
      if find "$cfg/shaders" -maxdepth 1 -type f -iname "*${pat}*" | grep -q .; then
        ok "$pat shaders present"
      else
        note "$pat shaders not found (may be named differently in this build)"
      fi
    done
  fi

  say "Power Guard"
  if [ -f "$cfg/scripts/power_manager.lua" ]; then
    ok "power_manager.lua present"
  else
    bad "power_manager.lua missing; battery Eco switching will not work"
  fi
  if [ -f "$cfg/script-opts/power_manager.conf" ]; then
    grep -iE 'eco|battery|profile' "$cfg/script-opts/power_manager.conf" | sed 's/^/  /' | head -n 10
  else
    note "no power_manager.conf; defaults apply"
  fi
fi

say "Jellyfin external player"
shim=0
have jellyfin-mpv-shim && { ok "jellyfin-mpv-shim on PATH"; shim=1; }
if have flatpak && flatpak list 2>/dev/null | grep -qi 'jellyfin'; then
  flatpak list 2>/dev/null | grep -i 'jellyfin' | sed 's/^/  /'
fi
[ "$shim" -eq 0 ] && note "no desktop shim. On Android use Jellyfin -> Settings -> Playback -> External player."

say "Controls to verify by eye (cannot be checked from a script)"
cat <<'EOF'
  K        active profile, mode and shader chain
  I        input/output size, dropped frames, decoder
  L        Anime4K Fast <-> HQ   (use Fast on the 680M)
  Ctrl+G   shader killswitch
  Ctrl+P   Power Guard manual toggle
EOF

say "Summary"
printf '  failures: %d, skipped: %d\n' "$fail" "$skip"
if [ "$fail" -gt 0 ]; then
  printf '  Result: video playback stack NOT ready (see FAIL lines).\n'
  exit 1
fi
printf '  Result: config present. Dropped frames and GPU cost need a 5 minute play test.\n'
