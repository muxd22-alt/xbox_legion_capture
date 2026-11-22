# Audio and controller

## Controller

- The Xbox controller stays **paired to the Xbox**. A capture card is one-way
  video; it cannot send input back.
- The Legion only receives the picture. Do not pair the controller to the Legion
  and try to forward it; there is no supported path to the Xbox over UVC.
- Frame generation adds display latency, not controller latency. The controller
  path is unchanged.
- VeyAmux's menu can be driven by a controller (open with **P** or Select +
  Start). That is only for the menu; gameplay still goes to the Xbox.
- Keep the controller in range of the Xbox. The Legion sitting between you and
  the console does not matter.

## Audio

VeyAmux handles the capture card's audio itself. That is one of the reasons to
use it instead of a raw video viewer.

In VeyAmux:

1. Open **Sound**.
2. Input: the capture card's USB audio source (often "USB Audio" or the card's
   name).
3. Output: your speakers or headphones.
4. Watch the sound meter while the Xbox plays something.
5. If audio runs ahead of the picture, use the **audio delay** control. Frame
   generation delays video by roughly one 30 fps frame, so a small positive
   delay on the audio is normal.

Keep the Xbox on **Stereo uncompressed**. Dolby/DTS bitstream is usually not
captured by budget UVC cards and gives you silence.

### If VeyAmux has no audio

Find the source and test it outside the app:

```bash
wpctl status
speaker-test -c 2 -t sine -l 1
```

Common causes:

1. Xbox audio output is set to a headset, not HDMI.
2. The card's USB audio device is missing from `wpctl status`.
3. The card is in a USB 2.0 port; some cards drop audio there.
4. A different input is selected in VeyAmux.
5. The output device in VeyAmux is wrong or muted.

### Fallback: route the card with PipeWire

If you need audio without VeyAmux:

```bash
# list sources and sinks
pw-link -o
pw-link -i

# link the card source to your speakers
pw-link <card-source> <speaker-sink>
```

Or use a loopback sink for recording:

```bash
pactl load-module module-null-sink sink_name=xbox
pw-loopback --capture-props='node.target=<card-source>' \
            --playback-props='node.target=xbox'
```

This is only a fallback. VeyAmux's Sound tab is the normal path.

### Sync expectations

- Capture + 3x adds roughly one to two 30 fps frames of video delay
  (33-66 ms).
- If the audio is clearly ahead, add delay in VeyAmux.
- There is no perfect sync without measuring. Dialogue-level sync is enough for
  GTA VI.

### Quick checks

```bash
# sources and sinks
wpctl status

# watch the card's audio
pw-mon | grep -i <card-name>

# test the speakers
speaker-test -c 2 -t sine -l 1
```
