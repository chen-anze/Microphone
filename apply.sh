#!/usr/bin/env bash
set -euo pipefail

MIC1='alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic1__source'
CONFIG_NAME='51-disable-internal-mic2.conf'
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/wireplumber/wireplumber.conf.d/$CONFIG_NAME"

command -v pactl >/dev/null
command -v systemctl >/dev/null

# Refuse to install a hardware-specific rule unless the expected working source
# exists. This also permits safe repeated runs after Mic2 is already disabled.
sources=$(pactl list short sources)
if [[ "$sources" != *"$MIC1"* ]]; then
  printf 'ERROR: expected Redrix Microphone 1 source was not found:\n%s\n' "$MIC1" >&2
  printf 'Run ./collect-diagnostics.sh and compare the detected node names.\n' >&2
  exit 1
fi

install -Dm0644 "$SCRIPT_DIR/$CONFIG_NAME" "$CONFIG_TARGET"
systemctl --user restart wireplumber

# Wait briefly for WirePlumber to publish the recreated Mic1 source.
for _attempt in {1..20}; do
  if pactl get-source-volume "$MIC1" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

pactl set-default-source "$MIC1"
pactl set-source-mute "$MIC1" 0
pactl set-source-volume "$MIC1" 300%

"$SCRIPT_DIR/verify.sh"
