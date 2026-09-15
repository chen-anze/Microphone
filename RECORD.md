# Redrix microphone configuration record

Recorded on 2026-09-14 in America/New_York.

## Result

The Redrix internal microphone array originally appeared as two stereo input
sources. `Internal Microphone 1` carries usable audio; `Internal Microphone 2`
does not. Microphone 2 is now suppressed by a WirePlumber rule, and Microphone
1 is the default input, unmuted, at 300% (`+28.63 dB`).

The Mic2 configuration survived a WirePlumber restart. WirePlumber stores
per-route gain state, while the checked-in rule makes the Mic2 removal
persistent across service restarts and logins. The later 300% setting was
verified live; a full reboot test was not performed during this session.

## System specifications

| Component | Detected value |
| --- | --- |
| Host name | `dragonfly` |
| Product | Google Redrix rev3 Chromebook |
| Board | Google Redrix |
| Firmware | coreboot / MrChromebox 2606.1 |
| Architecture | x86_64 |
| Processor | 12th Gen Intel Core i7-1265U; 10 cores, 12 threads; up to 4.8 GHz |
| Memory | 31 GiB usable |
| Main storage | 476.9 GiB NVMe, Micron `MTFDKBA512QFM-1BD1AABHA` |
| Operating system | Fedora Linux 44, KDE Plasma Desktop Edition |
| Running kernel | `7.2.5-200.fc44.x86_64` |
| Audio controller | Intel Alder Lake PCH-P HD Audio, PCI `8086:51c8` |
| Kernel audio driver | `sof-audio-pci-intel-tgl` / `snd_soc_sof_rt5682` |
| ALSA card | `sof-rt5682`, long name `Google-Redrix-rev3` |
| PipeWire | 1.6.8 (`pipewire-pulseaudio` 1.6.8) |
| WirePlumber | 0.5.14 |
| PulseAudio compatibility tools | 17.0 |
| ALSA library / SOF firmware | 1.2.16.1 / 2025.12.2 |
| Audio format | 48,000 Hz, two channels; float32 internal microphone sources |

The audio server identifies itself as `PulseAudio (on PipeWire 1.6.8)`. The
active card profile is `HiFi`. PipeWire owns the ALSA devices, so an `arecord`
or `amixer` probe from a separate restricted process may report no available
sound card even while the PipeWire sources work normally.

## Device names

```text
Microphone 1:
alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic1__source

Microphone 2:
alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic2__source
```

Before the change, Microphone 1 was already the default, unmuted, and at 153%
(`+11.00 dB`). Microphone 2 was present as a source and muted at 100%.

After the final gain adjustment, Microphone 1 was the only internal microphone
source exposed by PipeWire. Its verified state was:

```text
Default Source: alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic1__source
Volume: front-left: 196608 / 300% / 28.63 dB,
        front-right: 196608 / 300% / 28.63 dB
Mute: no
```

The card may continue to advertise a `Mic2` *port* in its static HiFi profile.
The WirePlumber rule prevents the corresponding source node from being created,
which keeps it out of application input-device lists.

## Why this approach

The SOF/UCM topology exposes one four-channel ALSA capture device,
`hw:sofrt5682,99`, as two PipeWire stereo nodes:

| PipeWire source | Channels from the ALSA device | HiFi profile device |
| --- | --- | --- |
| Internal Microphone 1 | `AUX0`, `AUX1` | 8 |
| Internal Microphone 2 | `AUX2`, `AUX3` | 7 |

Both internal sources belong to the same ALSA card and `HiFi` card profile.
Turning the whole profile off would also remove the working microphone and the
card's speaker, headphone, headset, and HDMI routes. Muting Mic2 with `pactl`
stops its signal but leaves it visible to applications. Suspending it is also a
runtime state rather than a durable removal.

WirePlumber creates the individual ALSA nodes, and WirePlumber 0.5 supports
`monitor.alsa.rules` with an `update-props` action. Matching the exact Mic2
`node.name` and setting `node.disabled = true` prevents only that node from
being created. This preserves the rest of the card and survives new sessions.

`SUSPENDED` in `pactl list short sources` is the normal idle state. It means no
application is recording; it does not mean Microphone 1 is disabled.

## Changes applied

### Chronology

| Stage | Observed or applied state |
| --- | --- |
| Discovery | Mic1 default, unmuted, 153% (`+11.00 dB`); Mic2 exposed and muted at 100% |
| Live adjustment | Mic1 raised to 200%; Mic2 muted and suspended |
| Persistent disable | Exact Mic2 node disabled with a WirePlumber rule; service restarted |
| First verification | Mic2 absent; Mic1 default, unmuted, 200% (`+18.06 dB`) |
| Final gain adjustment | Mic1 raised to 300% (`+28.63 dB`) |
| Final verification | Mic2 absent; Mic1 default, unmuted, 300% |

The initial live-only stage used:

```bash
pactl set-default-source "$MIC1"
pactl set-source-mute "$MIC1" 0
pactl set-source-volume "$MIC1" 200%
pactl set-source-mute "$MIC2" 1
pactl suspend-source "$MIC2" 1
```

After persistent Mic2 removal was verified, the final gain adjustment used:

```bash
pactl set-source-volume "$MIC1" 300%
```

The persistent WirePlumber rule was installed at:

```text
~/.config/wireplumber/wireplumber.conf.d/51-disable-internal-mic2.conf
```

It matches the exact Mic2 node name and sets `node.disabled = true`. WirePlumber
was restarted to apply it. After the restart, Mic2 was absent and Mic1 remained
the default source. Its gain was subsequently raised from 200% to 300%.

No microphone recording was made during configuration or verification.

The final checks prove control-plane state: source enumeration, default source,
mute state, and configured gain. They do not prove acoustic quality or physical
microphone sensitivity because no sample was recorded or analyzed.

## Evidence collection commands

System specifications were collected from `uname`, `/etc/os-release`, selected
non-serial DMI fields under `/sys/class/dmi/id`, `lscpu`, `free`, `lsblk`,
`lspci`, `/proc/asound/cards`, RPM package queries, and each audio tool's version
output. Live audio state was read using `pactl info`, `pactl list short sources`,
`pactl list sources`, `pactl list cards`, `pactl get-default-source`,
`pactl get-source-volume`, and `pactl get-source-mute`.

Dynamic PulseAudio/PipeWire object numbers such as source `431` before the
WirePlumber restart and `1046` afterward were intentionally excluded from the
scripts. The persistent node names are the reproducible identifiers.

## Files and use

- `51-disable-internal-mic2.conf` is the persistent WirePlumber rule.
- `apply.sh` installs the rule, restarts WirePlumber, applies the Mic1 settings,
  and runs verification. It is safe to run repeatedly.
- `verify.sh` checks that Mic2 is absent and Mic1 is default, unmuted, and 300%.
- `undo.sh` removes the installed rule, restarts WirePlumber, and resets Mic1 to
  its observed 153% baseline. It exposes Mic2 again and restores its observed
  muted, 100% state.
- `collect-diagnostics.sh` captures reproducibility metadata without recording
  any audio.
- `README.md` is the operational guide; `CHANGELOG.md` records the evolution of
  the configuration.

Run from this directory:

```bash
./apply.sh
./verify.sh
```

To reverse the documented configuration:

```bash
./undo.sh
```

The 300% setting is a software boost. It can raise microphone noise and clip
loud speech; reduce the percentage if either becomes objectionable.
