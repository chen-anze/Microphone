#!/usr/bin/env bash
set -u

# Collects configuration metadata only. It does not activate or record from a
# microphone. Pass a filename to save the report; omit it to print to stdout.
OUTPUT=${1:-}

report() {
  printf '# Redrix microphone diagnostics\n'
  printf 'Collected: '
  date --iso-8601=seconds

  printf '\n## Platform\n'
  uname -a
  for field in product_name product_version board_name board_vendor bios_vendor bios_version; do
    path="/sys/class/dmi/id/$field"
    if [[ -r "$path" ]]; then
      printf '%s: ' "$field"
      tr -d '\n' < "$path"
      printf '\n'
    fi
  done

  printf '\n## Operating system\n'
  if [[ -r /etc/os-release ]]; then
    grep -E '^(NAME|VERSION|ID|VERSION_ID|VARIANT|VARIANT_ID)=' /etc/os-release
  fi

  printf '\n## Audio packages and tools\n'
  wireplumber --version 2>&1 || true
  pipewire --version 2>&1 || true
  pactl --version 2>&1 || true
  if command -v rpm >/dev/null; then
    rpm -q pipewire pipewire-pulseaudio wireplumber pulseaudio-utils \
      alsa-lib alsa-sof-firmware 2>&1 || true
  fi

  printf '\n## Kernel audio hardware\n'
  if command -v lspci >/dev/null; then
    lspci -nnk | grep -A4 -Ei 'audio|multimedia' || true
  fi
  if [[ -r /proc/asound/cards ]]; then
    cat /proc/asound/cards
  fi

  printf '\n## Audio server\n'
  pactl info 2>&1 | sed -E \
    -e 's/^(User Name|Cookie):.*/\1: [redacted]/' || true

  printf '\n## Sources\n'
  pactl list short sources 2>&1 || true

  printf '\n## Cards\n'
  pactl list cards 2>&1 || true

  printf '\n## Installed project rule\n'
  config_home=${XDG_CONFIG_HOME:-$HOME/.config}
  installed_rule="$config_home/wireplumber/wireplumber.conf.d/51-disable-internal-mic2.conf"
  if [[ -r "$installed_rule" ]]; then
    sed -n '1,160p' "$installed_rule"
  else
    printf 'Not installed: ~/.config/wireplumber/wireplumber.conf.d/%s\n' \
      '51-disable-internal-mic2.conf'
  fi
}

if [[ -n "$OUTPUT" ]]; then
  report > "$OUTPUT"
  printf 'Wrote diagnostics to %s\n' "$OUTPUT"
else
  report
fi
