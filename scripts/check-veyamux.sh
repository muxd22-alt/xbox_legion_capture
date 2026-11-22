#!/usr/bin/env bash
# check-veyamux.sh - verify the VeyAmux + lsfg-vk + 120 Hz VRR setup.
# Run in Desktop Mode on Bazzite.

set -uo pipefail

echo "== display =="
if command -v kscreen-doctor >/dev/null 2>&1; then
    kscreen-doctor -o | grep -E 'Output|enabled|connected|1920x1080|90|120|Adaptive|VRR' || true
else
    echo "  kscreen-doctor not found (are you in a KDE session?)"
fi

echo
echo "== VeyAmux AppImage =="
found_vey=0
for d in "$HOME" "$HOME/Downloads" "$HOME/Applications" "$HOME/.local/bin"; do
    while IFS= read -r f; do
        [ -n "$f" ] || continue
        found_vey=1
        if [ -x "$f" ]; then echo "  OK   $f"; else echo "  chmod +x needed: $f"; fi
    done < <(find "$d" -maxdepth 2 -iname 'VeyAmux*.AppImage' 2>/dev/null)
done
[ "$found_vey" -eq 0 ] && echo "  MISS no VeyAmux*.AppImage found under $HOME"

echo
echo "== Lossless Scaling / lsfg-vk.dll =="
found_dll=0
for d in \
    "$HOME/.steam/steam/steamapps/common/Lossless Scaling" \
    "$HOME/.local/share/Steam/steamapps/common/Lossless Scaling" \
    "$HOME/.var/app/com.valvesoftware.Steam/.local/share/Steam/steamapps/common/Lossless Scaling"; do
    if [ -d "$d" ]; then
        echo "  dir  $d"
        ls -1 "$d" 2>/dev/null | grep -iE 'dll$|lsfg' | sed 's/^/       /'
        found_dll=1
    fi
done
[ "$found_dll" -eq 0 ] && echo "  MISS Lossless Scaling install not found in the usual Steam dirs"

echo
echo "== lsfg-vk install =="
for f in \
    "$HOME/.local/lib/liblsfg-vk-layer.so" \
    "$HOME/.local/share/vulkan/implicit_layer.d/VkLayer_LSFGVK_frame_generation.json" \
    "$HOME/.local/bin/lsfg-vk-cli" \
    "$HOME/.local/bin/lsfg-vk-ui"; do
    if [ -e "$f" ]; then echo "  OK   $f"; else echo "  MISS $f"; fi
done

echo
echo "== lsfg-vk status =="
if command -v ujust >/dev/null 2>&1; then
    ujust get-lsfg status 2>/dev/null || true
fi
if [ -x "$HOME/.local/bin/lsfg-vk-cli" ]; then
    "$HOME/.local/bin/lsfg-vk-cli" healthcheck || true
    "$HOME/.local/bin/lsfg-vk-cli" validate || true
else
    echo "  lsfg-vk-cli not installed"
fi

echo
echo "== VeyAmux config / log =="
CFG="$HOME/.config/VeyAmux"
if [ -d "$CFG" ]; then
    ls -l "$CFG" 2>/dev/null
    if [ -f "$CFG/lsfg-vk.log" ]; then
        echo "  --- last 20 log lines ---"
        tail -n 20 "$CFG/lsfg-vk.log" | sed 's/^/  /'
    fi
else
    echo "  MISS $CFG (VeyAmux has not run yet)"
fi

echo
echo "== capture devices =="
if command -v v4l2-ctl >/dev/null 2>&1; then
    ls -l /dev/v4l/by-id/ 2>/dev/null || echo "  no /dev/v4l/by-id entries"
    v4l2-ctl --list-devices
else
    echo "  v4l2-ctl not found (rpm-ostree install v4l-utils)"
fi

echo
echo "== expected =="
echo "  display: 1920x1080 @ 90 Hz fixed, VRR/Adaptive Sync OFF"
echo "  capture: 1920x1080 @ 60 fps on the by-id node (30 is a fallback)"
echo "  lsfg:    Lossless Scaling on the 'lsfg-vk' Steam branch"
echo "  VeyAmux: frame generation Fixed 3x + Even out frame pacing"
echo "  status:  'Active through lsfg-vk'"
echo "  output:  30 unique fps -> 90 fps on a 90 Hz display"
