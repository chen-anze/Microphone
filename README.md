# Redrix Chromebook microphone fix

This project configures the internal microphone on a Google Redrix rev3
Chromebook running Fedora with PipeWire and WirePlumber. It hides the unusable
`Internal Microphone 2` source and makes `Internal Microphone 1` the default,
unmuted input at 300% gain.

The rule is deliberately hardware-specific. Read [RECORD.md](RECORD.md) for the
machine specifications, original state, exact changes, and observed results.

## What changes

`apply.sh` performs four actions:

1. Confirms that the expected Redrix Mic1 PipeWire source exists.
2. Installs `51-disable-internal-mic2.conf` under the current user's
   `~/.config/wireplumber/wireplumber.conf.d/` directory.
3. Restarts the current user's WirePlumber service so Mic2 is no longer created.
4. Selects Mic1, unmutes it, sets it to 300%, and runs `verify.sh`.

No root privileges are required. Run the scripts as the desktop user whose
PipeWire session owns the audio devices. The WirePlumber restart briefly
disconnects audio applications.

## Requirements

- Bash
- PipeWire with the PulseAudio compatibility server
- WirePlumber 0.5 configuration fragments
- `pactl`, `systemctl`, `install`, and standard GNU command-line tools
- The exact source names recorded in [RECORD.md](RECORD.md)

This setup was tested with Fedora 44, PipeWire 1.6.8, WirePlumber 0.5.14, and
`pulseaudio-utils` 17.0. Package names and configuration locations may differ on
other distributions.

On Fedora, the relevant packages are:

```bash
sudo dnf install pipewire pipewire-pulseaudio wireplumber pulseaudio-utils
```

## Apply

From this directory:

```bash
chmod +x apply.sh verify.sh undo.sh collect-diagnostics.sh
./apply.sh
```

Expected final line:

```text
PASS: Microphone 2 is disabled; Microphone 1 is default, unmuted, and at 300%.
```

The scripts use stable PipeWire node names, not the numeric source IDs shown by
`pactl`. Numeric IDs are regenerated when WirePlumber restarts.

## Verify later

```bash
./verify.sh
```

For an explicit reboot test, reboot normally, return to the graphical session,
and run `./verify.sh` again. A source state of `IDLE` or `SUSPENDED` is healthy
when no application is recording.

## Undo

```bash
./undo.sh
```

This removes only this project's installed rule, restarts WirePlumber, exposes
Mic2 again, and restores the observed starting state: Mic1 selected, unmuted,
and at 153%; Mic2 muted at 100%.

## Diagnostics

Print a report:

```bash
./collect-diagnostics.sh
```

Or save one for comparison or a future issue report:

```bash
./collect-diagnostics.sh diagnostics.txt
```

The collector reads system and audio metadata. It does not record audio. It
redacts the PulseAudio user name and cookie. Review the report before publishing
it because it still includes the host name, hardware, kernel, package versions,
audio node names, and active audio configuration.

## Troubleshooting

### `Connection failure: Connection refused`

Run the script from a terminal inside the active graphical login and as the same
user running PipeWire. Do not run it with `sudo`. Check the services with:

```bash
systemctl --user status pipewire pipewire-pulse wireplumber
```

### The expected Mic1 source was not found

Do not remove the preflight check. Capture the machine's names with
`./collect-diagnostics.sh diagnostics.txt`, then compare the source names with
those in `apply.sh` and the WirePlumber rule. A kernel, UCM, or distribution
change can rename nodes.

### Mic2 still appears as a port

`pactl list cards` can still show a static `Mic2` card port. This is expected.
The relevant check is `pactl list short sources`: it must not contain the Mic2
source node.

### An application still lists Mic2

Close and reopen the application after applying the rule. Some applications
cache their device list for the lifetime of the process.

### The microphone distorts or hisses

300% is a strong software boost (`+28.63 dB`) and may amplify noise or clip.
Choose a lower value in `apply.sh` and `verify.sh`, apply it with `pactl`, and
update the recorded expected value so verification remains meaningful.

## Project files

| File | Purpose |
| --- | --- |
| `README.md` | Installation, use, verification, and troubleshooting |
| `RECORD.md` | Machine-specific audit record and technical evidence |
| `51-disable-internal-mic2.conf` | WirePlumber rule that suppresses Mic2 |
| `apply.sh` | Idempotent installer and Mic1 configuration |
| `verify.sh` | Read-only checks of the intended live state |
| `undo.sh` | Narrow rollback to the observed baseline |
| `collect-diagnostics.sh` | Non-recording system and audio metadata collector |
| `CHANGELOG.md` | History of configuration changes |

## Publishing

No license has been selected. Choose one before accepting outside contributions
or expecting others to reuse the project. Diagnostics reports are intentionally
not committed by the supplied `.gitignore`.
