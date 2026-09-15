# Changelog

All changes currently occurred on 2026-09-14.

## Current

- Set Internal Microphone 1 to 300% (`+28.63 dB`).
- Updated the installer and verifier to require 300%.
- Added a project README, reproducibility guidance, troubleshooting, a
  non-recording diagnostics collector, and this changelog.
- Updated rollback to restore the observed starting state.

## Initial configuration

- Identified the working source as Internal Microphone 1.
- Selected and unmuted Microphone 1.
- Initially raised Microphone 1 from 153% to 200% (`+18.06 dB`).
- Muted and suspended Internal Microphone 2 for the live session.
- Added a WirePlumber 0.5 rule with `node.disabled = true` for the exact Mic2
  node, restarted WirePlumber, and verified that Mic2 disappeared.
- Confirmed that Mic1 remained selected, unmuted, and at 200% after that restart.
- Added the first machine record, installer, verifier, rollback script, and a
  checked-in copy of the WirePlumber rule.
