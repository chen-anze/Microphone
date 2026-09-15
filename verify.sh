#!/usr/bin/env bash
set -euo pipefail

MIC1='alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic1__source'
MIC2='alsa_input.pci-0000_00_1f.3-platform-adl_rt5682_def.HiFi__Mic2__source'

sources=$(pactl list short sources)
default_source=$(pactl get-default-source)
volume=$(pactl get-source-volume "$MIC1")
mute=$(pactl get-source-mute "$MIC1")

printf '%s\n' "$sources"
printf 'Default source: %s\n%s\n%s\n' "$default_source" "$volume" "$mute"

if printf '%s\n' "$sources" | grep -Fq "$MIC2"; then
  printf 'ERROR: Microphone 2 is still exposed.\n' >&2
  exit 1
fi

if [[ "$default_source" != "$MIC1" ]]; then
  printf 'ERROR: Microphone 1 is not the default source.\n' >&2
  exit 1
fi

if [[ "$volume" != *'300%'* ]]; then
  printf 'ERROR: Microphone 1 is not at 300%%.\n' >&2
  exit 1
fi

if [[ "$mute" != 'Mute: no' ]]; then
  printf 'ERROR: Microphone 1 is muted.\n' >&2
  exit 1
fi

printf 'PASS: Microphone 2 is disabled; Microphone 1 is default, unmuted, and at 300%%.\n'
