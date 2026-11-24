#!/usr/bin/env bash
# check-native-games.sh - verify the Decky + HelixSR / OptiScaler stack.
#
# Read-only. Usage:
#   ./scripts/check-native-games.sh                 # host-level checks
#   ./scripts/check-native-games.sh /path/to/game   # also inspect one game folder
#
# Server-safe (no GUI). Never installs or patches anything.

set -u
fail=0
skip=0

say() { printf '\n== %s ==\n' "$1"; }
ok()  { printf '  PASS  %s\n' "$1"; }
bad() { printf '  FAIL  %s\n' "$1"; fail=$((fail + 1)); }
note(){ printf '  NOTE  %s\n' "$1"; }
skp() { printf '  SKIP  %s\n' "$1"; skip=$((skip + 1)); }
have(){ command -v "$1" >/dev/null 2>&1; }

GAME="${1:-}"

say "Host"
printf '  %s\n' "$(uname -srm)"
if have bazzite-version; then bazzite-version 2>&1 | head -n 1 | sed 's/^/  /'; fi

say "Decky Loader"
if [ -d "$HOME/homebrew/plugins" ]; then
  ok "~/homebrew/plugins exists"
else
  bad "~/homebrew/plugins missing: Decky Loader is not installed for this user"
fi
if systemctl --user list-unit-files 2>/dev/null | grep -q '^plugin_loader'; then
  systemctl --user is-active plugin_loader >/dev/null 2>&1 \
    && ok "plugin_loader service is active" \
    || bad "plugin_loader is not active (systemctl --user restart plugin_loader)"
else
  note "no plugin_loader user unit; on Bazzite Decky may run under a different unit"
fi

say "DeckyMultiFrameGen"
mfg=""
for d in "$HOME/homebrew/plugins"/*; do
  [ -f "$d/package.json" ] || continue
  if grep -qi 'multiframegen' "$d/package.json" 2>/dev/null; then mfg="$d"; fi
done
if [ -n "$mfg" ]; then
  ver="$(grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' "$mfg/package.json" | head -n 1)"
  ok "found $mfg ${ver}"
else
  bad "DeckyMultiFrameGen not found in ~/homebrew/plugins"
fi

say "Backends present on disk"
if [ -n "$mfg" ]; then
  for b in OptiScaler HelixSR helixsr; do
    if find "$mfg" -maxdepth 3 -iname "*${b}*" -print -quit 2>/dev/null | grep -q .; then
      ok "backend asset: $b"
    fi
  done
  note "backend versions are shown in the plugin's Backends panel; this script does not guess them"
fi

say "Proton Experimental"
found_proton=0
for p in \
  "$HOME/.steam/steam/steamapps/common/Proton - Experimental" \
  "$HOME/.local/share/Steam/steamapps/common/Proton - Experimental" \
  "$HOME/.var/app/com.valvesoftware.Steam/data/Steam/steamapps/common/Proton - Experimental"; do
  if [ -d "$p" ]; then
    ok "$p"
    found_proton=1
  fi
done
[ "$found_proton" -eq 0 ] && bad "Proton - Experimental not found in the usual Steam libraries"

say "Anti-cheat rule"
note "This mode is single-player only. Never patch EAC/BattlEye games; a ban is not a supported outcome."

if [ -n "$GAME" ]; then
  say "Game folder: $GAME"
  if [ ! -d "$GAME" ]; then
    bad "not a directory"
  else
    for f in dxgi.dll winmm.dll version.dll dbghelp.dll OptiScaler.ini; do
      [ -e "$GAME/$f" ] && printf '  proxy/config: %s\n' "$f"
    done
    [ -d "$GAME/OptiScaler" ] && printf '  OptiScaler folder present\n'
    [ -d "$GAME/HelixSR" ] && printf '  HelixSR folder present\n'
    if [ -d "$GAME/OptiScaler" ] && [ -d "$GAME/HelixSR" ]; then
      bad "both OptiScaler and HelixSR are installed in this game; use exactly one"
    fi
    for log in OptiScaler.log HelixSR/helixsr.log HLX_FSR.log; do
      if [ -f "$GAME/$log" ]; then
        printf '  log: %s (last line)\n' "$log"
        tail -n 1 "$GAME/$log" | sed 's/^/        /'
      fi
    done
    if [ ! -d "$GAME/OptiScaler" ] && [ ! -d "$GAME/HelixSR" ]; then
      note "no backend installed here yet"
    fi
  fi
else
  skp "no game folder given; pass one to inspect its proxy DLLs and logs"
fi

say "Summary"
printf '  failures: %d, skipped: %d\n' "$fail" "$skip"
if [ "$fail" -gt 0 ]; then
  printf '  Result: native-game stack NOT ready (see FAIL lines).\n'
  exit 1
fi
printf '  Result: stack present. Upscaler ms and FPS still need a play test.\n'
