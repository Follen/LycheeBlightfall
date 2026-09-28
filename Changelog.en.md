# Changelog

## 1.0.3 — 2026-09-28

- With Heart, prepare Soul Reaper with about 9 seconds remaining in both ST and AoE.
- Without Heart, retain the default 7-second ST delay; AoE adds no extra wait.
- Wait for actual Soul Reaper before issuing single-target Blightfall cues.
- Document timing rules and the selected policy's results from 279,000 simulations.

## 1.0.2 — 2026-09-28

- Renamed the in-game addon to “[荔枝]智能吞病收割提醒” to match its platform listing.
- Updated addon-list, settings, and documentation labels while preserving saved settings and reminder behavior.

## 1.0.1 — 2026-09-28

- Added a Soul Reaper countdown and voice cue, using the same approximately 7-second delay after Dark Transformation in both single-target and AoE combat; the default lead is 3 seconds.
- Successful Soul Reaper casts cancel its reminder. Dark Transformation extensions do not delay it, and Blightfall retains priority.
- Added a separate Soul Reaper toggle and independent SharedMedia sound selection and preview for both cues.
- The new Chinese voice uses the same speaker, speed, and gain as the existing cue.

## 1.0.0 — 2026-09-28

First public release.

- Dynamic Blightfall countdown and voice reminder for San'layn Unholy Death Knights.
- Cast-based burst-window estimates that update when Dark Transformation is extended.
- Automatic single-target and AoE branches using visible enemy nameplates.
- A default 3-second lead, with separate text and voice toggles and timing settings.
- Transparent text, draggable positioning, font-size controls, and SharedMedia sound selection and preview.
- Settings integrated into Blizzard's AddOns options; unlock, drag, and finish without reopening the settings panel.
- Credits and links to other Lychee addons.

Timing is advisory; all casts remain under player control. The current in-game UI and included voice are in Chinese.
