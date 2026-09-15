#!/usr/bin/env bash
set -euo pipefail

MIC1='alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic1__source'
MIC2='alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic2__source'
CONFIG_NAME='51-disable-internal-mic2.conf'
CONFIG_TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/wireplumber/wireplumber.conf.d/$CONFIG_NAME"

rm -f -- "$CONFIG_TARGET"
systemctl --user restart wireplumber

for _attempt in {1..20}; do
  if pactl get-source-volume "$MIC1" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

pactl set-default-source "$MIC1"
pactl set-source-mute "$MIC1" 0
pactl set-source-volume "$MIC1" 153%

sources=$(pactl list short sources)
if [[ "$sources" == *"$MIC2"* ]]; then
  pactl set-source-volume "$MIC2" 100%
  pactl set-source-mute "$MIC2" 1
fi

printf 'Restored the observed baseline: Mic2 exposed and muted; Mic1 at 153%%.\n'
