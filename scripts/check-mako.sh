#!/usr/bin/env bash
# check-mako.sh - read-only check for MAKO 5.x / Decky on this machine.
#
# Usage: ./scripts/check-mako.sh
#
# MAKO is a game-oriented Vulkan frame-generation / scaling layer. It is NOT a
# VeyAmux integration and must not run together with lsfg-vk. This script only
# reports what is installed; it changes nothing.

set -u
fail=0
skip=0

say() { printf '\n== %s ==\n' "$1"; }
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
note(){ printf '  NOTE  %s\n' "$1"; }
skp() { printf '  SKIP  %s\n' "$1"; skip=$((skip + 1)); }
have(){ command -v "$1" >/dev/null 2>&1; }

say "Host"
printf '  %s\n' "$(uname -srm)"
printf '  user home: %s\n' "$HOME"

say "Decky Loader"
if [ -x "$HOME/homebrew/services/PluginLoader" ]; then
  ok "PluginLoader present: $HOME/homebrew/services/PluginLoader"
else
  skp "no $HOME/homebrew/services/PluginLoader"
fi
if systemctl list-unit-files 2>/dev/null | grep -q '^plugin_loader.service'; then
  if systemctl is-active plugin_loader >/dev/null 2>&1; then
    ok "plugin_loader.service is active (system unit, runs as root)"
  else
    bad "plugin_loader.service exists but is not active"
  fi
elif systemctl --user list-unit-files 2>/dev/null | grep -q '^plugin_loader'; then
  if systemctl --user is-active plugin_loader >/dev/null 2>&1; then
    ok "plugin_loader user service is active"
  else
    bad "plugin_loader user service exists but is not active"
  fi
else
  skp "no plugin_loader unit found"
fi
if [ -d "$HOME/homebrew/plugins" ]; then
  if [ -w "$HOME/homebrew/plugins" ]; then
    note "$HOME/homebrew/plugins is writable by this user"
  else
    note "$HOME/homebrew/plugins is root-owned; install plugins through Decky's UI"
  fi
fi

say "MAKO Decky / plugins"
found_mako=0
for d in "$HOME/homebrew/plugins"/*; do
  [ -f "$d/package.json" ] || continue
  if grep -qi 'mako' "$d/package.json" 2>/dev/null; then
    found_mako=1
    ok "found $d"
    grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$d/package.json" | head -n 1 | sed 's/^/        /'
  fi
  if grep -qi 'multiframegen' "$d/package.json" 2>/dev/null; then
    ok "found DeckyMultiFrameGen: $d"
  fi
done
[ "$found_mako" -eq 0 ] && skp "no MAKO Decky plugin in $HOME/homebrew/plugins"

say "MAKO Renderer / standalone"
for p in "$HOME/.local/bin/mako-launch" "$HOME/.local/bin/mako-run" "$HOME/.local/bin/mako-renderer"; do
  if [ -e "$p" ]; then ok "$p"; else skp "$p not found"; fi
done
for d in "$HOME/.local/share/vulkan/implicit_layer.d" /usr/share/vulkan/implicit_layer.d; do
  for f in "$d"/*mako* "$d"/*MAKO*; do
    [ -e "$f" ] && ok "Vulkan layer: $f"
  done
done
for d in "$HOME/.config/mako" "$HOME/.local/share/mako" "$HOME/.config/MAKO"; do
  [ -d "$d" ] && ok "config/data: $d"
done

say "Conflicts"
lsf=0
for d in "$HOME/.local/share/vulkan/implicit_layer.d" /usr/share/vulkan/implicit_layer.d; do
  for f in "$d"/*lsfg*; do [ -e "$f" ] && { lsf=1; printf '  lsfg-vk layer: %s\n' "$f"; }; done
done
[ "$lsf" -eq 1 ] && note "lsfg-vk is present. MAKO and lsfg-vk are both frame-generation layers; enable only one per app."
note "VeyAmux's duplicate-frame removal is inside VeyAmux; MAKO cannot use it. Do not run MAKO on the Xbox capture feed."

say "Summary"
printf '  failures: %d, skipped: %d\n' "$fail" "$skip"
if [ "$found_mako" -eq 1 ] || [ -e "$HOME/.local/bin/mako-launch" ] || [ -e "$HOME/.local/bin/mako-run" ]; then
  printf '  Result: MAKO components found. Test only on a native single-player game, one frame-gen layer.\n'
else
  printf '  Result: MAKO 5.x is NOT installed. This repo keeps it parked (docs/11).\n'
fi
