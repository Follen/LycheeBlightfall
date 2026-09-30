# Lychee Blightfall

[简体中文](README.md) · [Changelog](Changelog.en.md)

![Cover](docs/media/release-cover.png)

Soul Reaper and Blightfall countdowns and voice cues for Retail San'layn Unholy Death Knights. The in-game UI and bundled voices are Chinese.

## Version 1.1.2

All target counts now use the single-target cue timing; nameplate counting has been removed. A fresh transformation on a later wave schedules a new Reaper cue. An observed Heart expiry is a hard deadline for that Blightfall cycle. If a late Reaper leaves no GCD to cast Blightfall before Heart expires, the addon does not cue an impossible cast after Heart.

## Soul Reaper

- With an observed Heart use: prepare Reaper with about 9 seconds left on its 20-second window, approximately 11 seconds after using the trinket.
- Without Heart: prepare Reaper about 7 seconds after Dark Transformation. Target count does not change this timing; higher-priority actions and cast requirements still matter.
- Transformation extensions do not keep delaying Reaper. Successfully casting Reaper cancels its cue.

## Blightfall

- With Reaping and Soul Reaper, wait for the actual Reaper cast, then aim about two GCDs before the earlier of its estimated 8-second window or observed Heart expiry. If the post-Reaper GCD cannot fit before Heart expires, do not cue an impossible Blightfall. Later transformation extensions do not move that deadline.
- Without an observed Reaper, do not give a premature Blightfall cue. Disabling the Reaper reminder does not change this rule.
- Without Reaping, use the earlier transformation or observed Heart expiry. Heart expiry ends that cycle even if transformation remains active. Unreadable GCD duration falls back to 1.5 seconds; recent spender GCD occupancy is considered.

## Observations and limits

Successful casts start estimates: transformation 15 seconds, Heart 20 seconds, Reaper 8 seconds. Coil, Epidemic and supported replacements extend an active inferred transformation by one second.

The addon does not read enemy nameplates or switch timing by target count. A new cue cycle begins with an observed successful Dark Transformation cast; reloading mid-combat loses that history.

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

300 seconds pools three fresh seeds, 9000 iterations per policy; other durations use 3000 each. These are complete single-target SimC APL results, not addon-assisted gameplay gains or AoE evidence. SimC retained execute logic below 35%; the addon cannot read secret health. The model has an unverified rune proc-target assumption shared by all policies.

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

## In-game screenshots

These three images are the player's supplied screenshots; the cover is a promotional image.

![Combat](docs/media/combat.png)

![Settings](docs/media/settings.png)

![Positioning](docs/media/positioning.png)
