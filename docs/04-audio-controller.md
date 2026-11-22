# Audio and controller

## Controller

- The Xbox controller stays **paired to the Xbox**. A capture card is one-way
  video; it cannot send input back.
- The Legion only receives the picture. Do not try to pair the controller to the
  Legion and forward it; there is no supported path to the Xbox over UVC.
- This is why the Veyra video claims no added input latency: the controller
  path is unchanged. Frame generation adds display latency, not controller
  latency.
- Keep the controller in range of the Xbox. If the Legion is between you and the
  console, the controller still talks to the console, not the Legion.

## Audio

The capture card exposes a **USB audio input**. HDMI audio does not travel over
USB by itself, and `mpv av://v4l2:` is **video only**.

### Find the source

```bash
wpctl status
```

Look under **Audio -> Sources** for the capture card (often "USB Audio" or the
card's name). Note its node name or ID.

### Local playback

Link the card source to your speakers:

```bash
pw-link <card-source> <speaker-sink>
```

Or in a desktop mixer, select the card as input and enable "listen"/"monitor".

### If you later stream or record

Create a sink and loop the card into it:

```bash
pactl load-module module-null-sink sink_name=xbox
pw-loopback --capture-props='node.target=<card-source>' \
            --playback-props='node.target=xbox'
```

Then capture "Monitor of xbox" in OBS/Sunshine. Not needed for the monitor-only
path.

### Sync

- Frame generation delays video by roughly one 30 fps frame. If audio runs
  ahead, that is expected.
- There is no audio-delay slider in mpv for a live v4l2 source. Fix it at the
  source (loopback latency) or accept ~30 ms.
- Keep the Xbox on **Stereo uncompressed**. Dolby/DTS bitstream is not captured
  by budget UVC cards and gives you silence.

### Quick checks

```bash
# list sources and sinks
wpctl status

# watch the card's audio level
pw-mon | grep -i <card-name>

# test speakers
speaker-test -c 2 -t sine -l 1
```

If there is no audio at all:

1. Confirm the Xbox audio output is HDMI stereo, not headset.
2. Confirm the card's USB audio device appears in `wpctl status`.
3. Confirm the card is in a USB 3.0 port; some cards drop audio on USB 2.0.
4. Try a different USB cable.
