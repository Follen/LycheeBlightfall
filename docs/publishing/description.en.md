# Lychee Blightfall

Soul Reaper and Blightfall countdowns and voice cues for Retail San'layn Unholy Death Knights. The in-game UI and bundled voices are Chinese.

## Version 1.1.1

A lychee-red Audio Volume slider (0–100%) now controls system Dialogue volume directly, with a clear note beneath the title. It stays synchronized with WoW audio settings without interrupting active reminders. Resetting addon settings leaves system volume unchanged. The louder voice cues and Dialog channel from 1.1.0 are retained; combat timing rules are unchanged.

## Soul Reaper

- With an observed Heart use: single-target and AoE both prepare Reaper with about 9 seconds left on its 20-second window, approximately 11 seconds after using the trinket.
- Without Heart, single-target keeps SimC's default: about 7 seconds after Dark Transformation.
- Without Heart, AoE adds no extra 7-second delay. Prepare Reaper early; the countdown uses the publicly readable GCD where available. Higher-priority actions and cast requirements still matter.
- Transformation extensions do not keep delaying Reaper. Successfully casting Reaper cancels its cue.

## Blightfall

- Single-target with Reaping and Soul Reaper waits for the actual Reaper cast, then aims about two GCDs before its estimated 8-second window ends. Later transformation extensions do not move that deadline.
- Without an observed Reaper, no premature single-target swallow cue. Disabling the Reaper reminder does not change this rule.
- AoE uses the earlier still-active transformation or observed Heart expiry, regardless of Reaper. After Heart expires, an active transformation can still provide a window.
- Without the required talents, use transformation. Unreadable GCD duration falls back to 1.5 seconds; recent spender GCD occupancy is considered.

## Observations and limits

Successful casts start estimates: transformation 15 seconds, Heart 20 seconds, Reaper 8 seconds. Coil, Epidemic and supported replacements extend an active inferred transformation by one second.

At least three visible, living, attackable non-player nameplates publicly known to be in combat select AoE. Otherwise use single-target. Hidden or secret states are never invented; enable enemy nameplates.

With Visceral Strength selected, a public Sudden Doom overlay followed by a spender infers five seconds of strength. Ordinary casts do not fabricate refreshes; strength does not change the established swallow deadline or add a spender prompt.

Blightfall, death, leaving combat and eligibility changes reset the cycle. Reloading loses history until the next transformation. The addon cannot guarantee availability or hits, inspect secret health, or automatically reproduce execute behavior.

## Simulation evidence

93 batches and 279,000 measured iterations across search and validation, 3000 per batch. Official prebuilt SimC 1210-01 / 4c7c736, MID2 San'layn, Heart plus Zul'jin trinket, one target, full-fight damage including pets.

The table matches this release: Heart remaining 9 seconds; default single-target timing without Heart; Blightfall margin of two GCDs.

| Duration | Default total damage | Selected policy | Gain |
|---|---:|---:|---:|
| 180 seconds | 47,921,506 | 48,302,649 | +0.80% |
| 300 seconds | 81,706,358 | 81,932,415 | +0.28% |
| 450 seconds | 116,966,430 | 117,316,259 | +0.30% |

300 seconds pools three fresh seeds, 9000 iterations per policy; other durations use 3000 each. These are complete SimC APL results, not addon-assisted gameplay gains. AoE shares the Heart cue by design but has no tested damage gain. SimC retained execute logic below 35%; the addon cannot read secret health. The model has an unverified rune proc-target assumption shared by all policies.

![Simulation count and results](https://cdn8.newbeebox.com/user_media/default/558213/b637b6ef720305b12e0dc56627576ecd.png)

Data: https://github.com/Follen/LycheeBlightfall/tree/v1.0.3/docs/simulation

## Setup

- Esc → Options → AddOns → [荔枝]智能吞病收割提醒.
- Text and voice default to a three-second lead. If less notice is available, cue immediately without adding a delay.
- Separate SharedMedia sounds, an optional Reaper cue, and movable transparent text. Blightfall takes priority; each voice plays once per cycle.
- Unlocking closes settings; click Finish after positioning.
- Core loads only for Unholy / San'layn with Blightfall. Event-driven scheduling; countdown updates only while visible.
- Install both LycheeBlightfall and LycheeBlightfall_Core. Reload after updating; restart after first installation.

## Thanks

小当家 Chef.

Source and feedback: https://github.com/Follen/LycheeBlightfall
