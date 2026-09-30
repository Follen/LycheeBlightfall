# Changelog

## 1.1.2 — 2026-09-30

- Use single-target Reaper and Blightfall timing for every target count; remove nameplate counting and its events.
- Keep the roughly seven-second no-Heart Reaper cue on a new transformation, including waves 45 seconds apart.
- Make observed Heart expiry a hard Blightfall deadline; suppress an impossible post-Heart cue when the GCD cannot fit.

## 1.1.1 — 2026-09-29

- Add a lychee-red Audio Volume slider to voice settings, adjustable from 0 to 100%.
- Explain that the slider changes system Dialogue volume and synchronize it with WoW audio settings.
- Volume changes preserve active reminders; resetting addon settings leaves system volume unchanged.
- Listen for volume changes only while the settings page is open, without polling. Reaper and Blightfall timing rules are unchanged.

## 1.1.0 — 2026-09-29

- Increase both bundled Blightfall and Soul Reaper voice cues by another 50% relative to 1.0.4.
- Route all reminders and previews through the Dialog audio channel, controlled by WoW's Dialogue volume setting.
- Custom SharedMedia sounds also follow Dialogue volume; their audio files are not amplified.
- Preserve existing Soul Reaper and Blightfall timing rules and saved settings.

## 1.0.4 — 2026-09-29

- Keep the current burst timeline when changing font size, sounds, or lead times, without replaying announced cues.
- Stop display updates at zero while keeping the action prompt visible; resume if the target moves into the future.
- Avoid redundant nameplate scans on GCD, proc-overlay, and incremental nameplate events.
- Fix missed countdown refreshes when a previously observed GCD duration becomes fresh again.
- Align package and platform versions at 1.0.4; existing Soul Reaper and Blightfall timing rules are unchanged.

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
