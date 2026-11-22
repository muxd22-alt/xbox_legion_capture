#!/usr/bin/env bash
# check-lsfg.sh - verify the 1080p120 lsfg-vk setup on Bazzite.
# Run in Desktop Mode.

set -uo pipefail

echo "== display modes =="
if command -v kscreen-doctor >/dev/null 2>&1; then
    kscreen-doctor -o | grep -E 'Output|enabled|connected|1920x1080|120|Hz' || true
else
    echo "  kscreen-doctor not found (are you in a KDE session?)"
fi

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

echo
echo "== config =="
CFG="${XDG_CONFIG_HOME:-$HOME/.config}/lsfg-vk/conf.toml"
if [ -f "$CFG" ]; then
    echo "  $CFG"
    grep -E '^(version|\[|name|active_in|multiplier|flow_scale|performance_mode|pacing_mode|allow_fp16)' "$CFG" || true
else
    echo "  MISS $CFG"
fi

echo
echo "== validate =="
if [ -x "$HOME/.local/bin/lsfg-vk-cli" ]; then
    "$HOME/.local/bin/lsfg-vk-cli" validate || true
else
    echo "  lsfg-vk-cli not installed"
fi

echo
echo "== vulkan layer =="
if command -v vulkaninfo >/dev/null 2>&1; then
    vulkaninfo --summary 2>/dev/null | grep -i lsfg || echo "  lsfg not in vulkaninfo summary"
else
    echo "  vulkaninfo not installed (rpm-ostree install vulkan-tools)"
fi

echo
echo "== expected =="
echo "  display: 1920x1080 @ 120 Hz, SDR, 100% scaling"
echo "  config:  multiplier = 4, performance_mode = true, pacing_mode = \"vsync\""
echo "  output:  ~120 fps in MangoHud when mpv runs at 30 fps capture"
