#!/usr/bin/env bash
# check-capture.sh - report the capture card's devices, formats and audio source.
# Run on Bazzite (Desktop Mode terminal).

set -uo pipefail

echo "== capture devices =="
if command -v v4l2-ctl >/dev/null 2>&1; then
    v4l2-ctl --list-devices
else
    echo "v4l2-ctl not found. Install v4l-utils:"
    echo "  rpm-ostree install v4l-utils   (then reboot)"
    echo "  # or: sudo dnf install v4l-utils  (inside a container)"
fi

echo
echo "== stable by-id paths (use these, not /dev/videoN) =="
ls -l /dev/v4l/by-id/ 2>/dev/null || echo "  (none)"

echo
echo "== formats per device =="
for dev in /dev/video*; do
    [ -e "$dev" ] || continue
    echo "--- $dev ---"
    v4l2-ctl -d "$dev" --list-formats-ext 2>/dev/null \
        | grep -E 'Index|Pixel Format|Name|Size: Discrete|Interval: Discrete' \
        || echo "  (no formats / not a capture node)"
done

echo
echo "== usb ids =="
lsusb 2>/dev/null | grep -iE 'capture|uvc|hdmi|joyzzz|macro|febon|elgato|avermedia' \
    || echo "  (no obvious capture device in lsusb)"

echo
echo "== audio sources (PipeWire) =="
if command -v wpctl >/dev/null 2>&1; then
    wpctl status | sed -n '/Audio/,/Video/p'
else
    echo "wpctl not found (is PipeWire running?)"
fi

echo
echo "== expected =="
echo "  1920x1080 @ 60 fps preferred: VeyAmux removes the duplicate frames."
echo "  30 fps is a fallback if 60 overloads USB or decode."
echo "  Prefer the /dev/v4l/by-id/... path: /dev/videoN can swap between boots."
echo "  MJPG is expected at 60; YUYV/NV12 is better if offered."
echo "  If 60 is missing, check the Xbox output setting and the HDMI/USB 3.0 link."
