#!/usr/bin/env bash
# check-stream.sh - verify the Sunshine -> Moonlight V+ path on the Legion Go S.
#
# Read-only: prints facts and runs one 10 s encode test. Changes nothing.
# Usage: ./scripts/check-stream.sh
#
# Everything it prints is a measurement or a fact from this machine. If a step
# cannot be checked, it says SKIP, never "probably fine".

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
if have bazzite-version; then
  printf '  %s\n' "$(bazzite-version 2>&1 | head -n 1)"
else
  skp "bazzite-version not found (not Bazzite?)"
fi

say "Sunshine install"
sun_brew=0
if systemctl --user list-unit-files 2>/dev/null | grep -q '^homebrew.sunshine'; then
  sun_brew=1
  printf '  unit: homebrew.sunshine (Brew install)\n'
  systemctl --user is-active homebrew.sunshine >/dev/null 2>&1 \
    && ok "homebrew.sunshine is active" \
    || bad "homebrew.sunshine is not active (systemctl --user start homebrew.sunshine)"
elif systemctl --user list-unit-files 2>/dev/null | grep -q '^app-dev.lizardbyte.app.Sunshine'; then
  printf '  unit: app-dev.lizardbyte.app.Sunshine (Flatpak)\n'
  bad "Flatpak Sunshine cannot use KMS capture on a Deck image; reinstall via Bazzite Portal -> Sunshine -> Enable (Brew)"
else
  skp "no Sunshine user unit found"
fi

if have flatpak && flatpak info io.mpv.Mpv >/dev/null 2>&1; then
  note "mpv Flatpak present (unrelated to streaming; listed for context)"
fi

say "Sunshine capture / encoder settings"
conf="$HOME/.config/sunshine/sunshine.conf"
if [ -f "$conf" ]; then
  printf '  %s\n' "$conf"
  grep -E '^[[:space:]]*(capture|encoder|hevc_mode|av1_mode|adapter_name)' "$conf" 2>/dev/null \
    | sed 's/^/  /' || note "no capture/encoder lines; web UI defaults are in use"
  if grep -qE '^[[:space:]]*capture[[:space:]]*=[[:space:]]*kms' "$conf"; then
    ok "capture = kms"
  else
    bad "capture is not kms (Game Mode streaming needs KMS)"
  fi
  if grep -qE '^[[:space:]]*encoder[[:space:]]*=[[:space:]]*vaapi' "$conf"; then
    ok "encoder = vaapi"
  else
    note "encoder is not pinned to vaapi in the file; check Configuration -> Audio/Video"
  fi
else
  skp "$conf not found (Sunshine has not written its config yet)"
fi

say "Sunshine apps"
apps="$HOME/.config/sunshine/apps.json"
if [ -f "$apps" ]; then
  for name in "Xbox Capture" "Desktop / Game Mode"; do
    if grep -q "$name" "$apps" 2>/dev/null; then
      ok "app present: $name"
    else
      bad "app missing: $name (add it under Applications in the web UI)"
    fi
  done
else
  skp "$apps not found; add the two apps from docs/08"
fi

say "HEVC encode capability"
if have vainfo; then
  if vainfo 2>/dev/null | grep -q 'VAEntrypointEncSlice'; then
    va_out="$(vainfo 2>/dev/null)"
    if printf '%s' "$va_out" | grep -qi 'HEVCMain'; then
      ok "VA-API exposes HEVC encode (EncSlice)"
      printf '%s\n' "$va_out" | grep -i 'HEVCMain' | sed 's/^/  /' | head -n 4
    else
      bad "VA-API has an encoder but no HEVC profile; this rig cannot stream HEVC"
    fi
  else
    bad "no VAEntrypointEncSlice at all; hardware encode is not available"
  fi
else
  skp "vainfo not installed (sudo dnf install libva-utils in a toolbox, or check with ffmpeg)"
fi

say "VAAPI HEVC smoke test (10 s, 1080p60, 50 Mbps)"
if have ffmpeg && [ -e /dev/dri/renderD128 ]; then
  tmp="$(mktemp)"
  start=$(date +%s)
  if ffmpeg -hide_banner -loglevel info \
      -f lavfi -i testsrc2=size=1920x1080:rate=60 -t 10 \
      -vaapi_device /dev/dri/renderD128 \
      -vf 'format=nv12,hwupload' \
      -c:v hevc_vaapi -b:v 50M -maxrate 50M -bufsize 100M -f null - \
      >"$tmp" 2>&1; then
    elapsed=$(( $(date +%s) - start ))
    fps_line="$(grep -o 'fps=[[:space:]]*[0-9.]*' "$tmp" | tail -n 1 | tr -d ' ')"
    speed_line="$(grep -o 'speed=[[:space:]]*[0-9.]*x' "$tmp" | tail -n 1 | tr -d ' ')"
    ok "HEVC encode completed in ${elapsed}s (${fps_line:-fps unknown}, ${speed_line:-speed unknown})"
    if [ "${elapsed:-0}" -gt 12 ]; then
      bad "encode wall time ${elapsed}s for 10 s of video: not real time"
    fi
  else
    bad "ffmpeg HEVC encode failed; last lines:"
    tail -n 8 "$tmp" | sed 's/^/        /'
  fi
  rm -f "$tmp"
else
  skp "ffmpeg or /dev/dri/renderD128 missing"
fi

say "Display mode (what Sunshine will capture)"
if have kscreen-doctor; then
  kscreen-doctor -o 2>/dev/null | grep -E 'Output:|enabled|connected|Modes:|Geometry|Scale' | sed 's/^/  /' | head -n 30
  note "TV path: panel at 1920x1080 @ 60 Hz; monitor path: 1920x1080 @ 90 Hz fixed"
else
  skp "kscreen-doctor not found"
fi

say "Network"
if have ip; then
  ip -brief addr 2>/dev/null | sed 's/^/  /'
fi
wifi_if="$(ls /sys/class/net 2>/dev/null | grep -E '^(wl|wlan)' | head -n 1)"
if [ -n "$wifi_if" ] && have iw; then
  iw dev "$wifi_if" link 2>/dev/null | sed 's/^/  /'
  note "50 Mbps needs a stable 5 GHz link; wired is preferred"
fi

say "Summary"
printf '  failures: %d, skipped: %d\n' "$fail" "$skip"
if [ "$fail" -gt 0 ]; then
  printf '  Result: NOT READY for the TV path (see FAIL lines)\n'
  exit 1
fi
printf '  Result: stream prerequisites present. Latency and picture are still untested.\n'
