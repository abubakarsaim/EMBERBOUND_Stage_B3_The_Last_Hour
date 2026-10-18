> Historical Stage A2 artwork report. Current build details are in IMPLEMENTATION_REPORT.md.

> Historical A2 report. The current A3 changes and validation are in IMPLEMENTATION_REPORT.md.

# EMBERBOUND Stage A2 polish report

This update iterates on the locally tested Stage A project. The latest uploaded ZIP matched the original delivered build byte for byte. Existing scenes, controller, flame system, Borrowed Time system, AI rules and puzzle logic were retained and extended; this is not a new game or Stage B.

## Improvements

- **Knight:** original 40×48 pixel art with dark layered armor, red cloak and crest, shield, sword, front/side/back views, four gait frames, idle breathing, torch embers, cast flare and hurt flash.
- **Shadow:** larger horned shroud, long predatory arms, six animated frames, sharp crimson eyes, smoke/aura and proximity vignette. Attack range, warning time and resource damage remain unchanged. Freeze stops both pursuit and shroud animation.
- **Corruption:** black-purple, irregular stains follow movement. They persist for the attempt, with a 560-cell limit and oldest-cell eviction. Sanctuary light, lit lamps and the completed circle resist or cleanse stains. The system stops emitting during freeze and clears on restart. It is visual-only and never adds damage, drain or movement penalties.
- **World:** smaller chipped masonry, cracks/moss/debris, a raised carved shrine, engraved lamps, clear path inlays, a readable inscription and drifting motes. Static floor art is cached rather than rebuilt each frame.
- **Feel and feedback:** 220 px/sec speed retained; acceleration is 2100 and braking 2600 px/sec². Physics interpolation, camera smoothing, flame flicker, event particles, cast shockwave, E prompts, lamp pulses, progress runes, exact-height meters, short menu fades and golden exit guidance were added.

## Revalidation

**Yes: the changed project was revalidated in Godot 4.7.2.stable.official.ed1daf0bf on Linux.**

- All **50 original integration checks passed** after the changes, including normal-movement puzzle completion, open-gate collision, success, failure, pause and checkpoint retries.
- All **28 new polish checks passed**, including trail limits, cleansing, freeze/pause behavior, restart cleanup and bounded visual effects.
- All **13 native keyboard checks passed** for Enter, WASD/arrows, Escape, Space and R.
- Rendered Compatibility/OpenGL captures were reviewed for title, full/weak flame, lure, freeze, sealed circle, success, pause and failure. This review led to improved corruption edges and slimmer meters.
- A fresh extraction of the final ZIP was imported and both automated suites rerun. Detailed results are in `tests/`.

## Placeholders and limits

These are improved original development sprites and procedural scenery, not final hand-animated production assets. The side view mirrors left/right; cast/hurt use effects rather than separate full animation sheets. The map and direct-pursuit navigation remain the existing open Stage A layout. Checkpoints remain in-memory. No new story chapters, boss, combat or Stage B content were added.

Windows export/runtime, physical audio playback, subjective smoothness and performance on your laptop still require local testing. Rendered QA used a virtual display and Mesa software OpenGL, not Windows hardware. Godot may print a harmless Camera2D warning when it selects physics processing for interpolation; the virtual display also reports unsupported V-Sync changes. Neither was a failed gameplay check.

Extract into a new folder, import `project.godot`, and run with F5. The unchanged controls and puzzle walkthrough are in `README.md`.
