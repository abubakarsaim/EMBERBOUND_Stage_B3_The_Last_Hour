# EMBERBOUND — Stage B.3 implementation report

## Delivered build

`EMBERBOUND_Stage_B3_The_Last_Hour.zip` is the full importable Godot 4.7.2 GDScript project, extended from the **latest mission-redesigned Stage B.2** in a separate folder. It launches to the existing forest title screen and supports the complete campaign through the final credits. Earlier ZIPs and project directories were not overwritten.

## Connected mission progression

| Mission | Goal and narrative reason | Player mechanics | Consequence / checkpoint |
| --- | --- | --- | --- |
| Break the Time Prison | Disable two anchors feeding the real princess's cage | Dodge telegraphed attacks; E starts a stationary, interruptible 1.2s flame channel during a 12s exposed interval | Each chain breaks visibly and is saved; both break the boss shield, weaken the prison, restore 25 flame and start phase 2 |
| Defeat the Hourkeeper | Remove the clock sorcerer's control before using the royal lock | Watch the moving hand meet the gold symbol; standard Borrowed Time freezes the mechanism/projectiles; E channels 0.85s at the exposed core | One strike per freeze; two total; every strike saved; boss disintegrates and all hostile attacks stop |
| Rescue the Princess | Use the royal sigil earned in B.2 to release the actual captive | Walk to the prison and deliberately interact; watch a 1.4s release and advance/skip dialogue | Princess becomes free, follows the knight and explains the still-broken clock; rescue checkpoint saved |
| Restore the Dawn | Return the last ember so the kingdom's time can resume | Walk to the central pedestal; E reads the sacrifice cue, then a separate E confirms | 12.5s skippable cinematic: raised ember, golden transfer, forward clock motion, retreating darkness, non-graphic fallen knight/princess farewell, window pan, sunrise and final title/credits |

No unrelated inventory collection, health bar, damage-sponge boss or repeated brazier sequence was introduced. Fire powers channels and survival; Shadow attacks that flame; Time creates the clock-core opening. The ending preserves the GDD's bittersweet sacrifice: the knight dies non-graphically after returning the ember; the princess survives into dawn.

## Boss, environment and presentation

- New explorable 2560×2048 chapter with bounded collision space, readable clockwork circles, ruined stone, pillars, broken windows, rubble, enormous clock, two distinct anchors, prison and two visible sacred fires. Static floor geometry is drawn once; normal camera uses smoothing with extra northward framing for the large boss.
- Original Hourkeeper artwork: **five local PNG sheets**, four 96×128 frames each, rendered at 2× nearest filtering. Idle/movement, charge, distinct release flash/pose, stagger and defeat use dark robes, metallic fragments, cyan clock core, crimson eyes, gear crown and orbiting broken gears. Motion is restrained and frame-rate independent.
- Shared improved red-cloaked knight remains unchanged during normal play. A small inherited subclass adds raised-torch/offering and fallen poses only. The real princess reuses the existing polished pale sprite with suspended, released, following and kneeling presentation.
- Clock hands, barrier, warnings, channels, symbols, cage chains, impact particles and original pixel-window/city sunrise use local Godot drawing. The vista is an in-engine overlay during the camera pan, not a pre-rendered movie or external concept image.
- Existing corruption grid is retained (560-cell limit, 12.5 Hz maintenance), with additional clock-hall veins and small boss-motion stamps. Sacred zones repel stains. Dynamic corruption clears after defeat; static darkness fades as dawn arrives. Earlier moving Shadow Hunter trails remain unchanged.
- Prominent mission title/reason, progress, vulnerability, waypoint direction/distance, contextual E prompts, timed channel bar, cooldown/low-flame messaging and skippable dialogue. Menu spacing and close-range boss framing were corrected after rendering review. Interaction prompts disappear during the final cinematic.

## Attack fairness and flame balance

All attacks follow a deterministic, non-overlapping sequence: **recovery → warning → one hazard → recovery**.

| Pattern | Timing and clear tell | Effect |
| --- | --- | --- |
| Shadow Flare | 1.1s locked red target/charge; one non-homing 200 px/s flare; wait for its removal, then 2.6s recovery | Existing swept projectile collision; 5 flame damage; original impact sound, torch flicker/shrink and 1.15s hit immunity |
| Clock-Hand Sweep | 1.55s red sector; 1.2s visible hand sweep; 2.6s recovery | 8 flame once; actual swept angular hit check, 115px safe hub and 520px outer range |
| Time Distortion | 1.65s cyan warning; 0.9s expanding pulse; 3s recovery | 68% movement for 1.6s; no flame damage or control lock; recovery prevents slow/projectile overlap |

Borrowed Time retains **15 flame / 3s / 8s cooldown**. It holds barrier rotation, attack timing and projectile motion/lifetime, while the boss's idle animation continues. The alignment interval is approximately 2.5 seconds each revolution; it is indicated by gold color and a sound, with clear failed-cast feedback. One frozen alignment cannot award both core strikes.

Balance additions are confined to the new chapter: two permanent safe fires restore **30 flame each / 16s recharge**; anchor completion restores 25; entry carries at least 60 flame; retry restores 100. Normal shared depletion remains 0.25/s exposed and 0.10/s protected. A channel does not add a separate flame fee. Sacred zones and 4s mission-reading grace prevent unfair interruption. Essential dialogue/cinematics suspend simulation. After defeat, passive depletion stops and casting Time is blocked to preserve the final ember. The inherited ability still cannot activate below 15; spending exactly the last 15 during combat invokes normal failure and a fair checkpoint retry.

## Integration and recovery

The Royal Hall's existing earned sigil passage now fades into `scenes/hourkeeper.tscn` during campaign play. Independent Royal Hall testing retains its chapter-completion screen; its mechanics remain testable without the finale. The title adds a fourth, explicit boss/finale development option. F6 on the boss scene also grants the sigil for isolated testing.

Permanent mission facts are separate from temporary hazards. Each anchor, core strike and rescue advances the retry state immediately. R clears projectiles, slow/freeze/channel/impact effects, camera/cinematic state and transient audio, restores the correct phase/location and read grace, and refreshes both fires. R during the ending or credits returns to the saved final-offering stage. Completion records a **session** flag, and a campaign replay begins a fresh forest. There is no persistent disk-save implementation.

The only existing gameplay scripts changed are the forest title/controller, session Journey, Royal Hall controller and its independent-test completion text. **81 existing foundation resources** (all prior PNGs/WAVs, scenes and unchanged gameplay/art scripts covered by the preservation scan) remain byte-identical. Shared player, flame, Time, hunter, projectile and corruption implementations are preserved. Original input mappings are unchanged. Previous B.2-redesign, B.2 and B.1 ZIP SHA-256 values were checked unchanged.

## Original audio

Four synchronized **24-second** original local stems add low string-like pads, ticking, distant bells, battle pulse/percussion, quiet rescue and warm dawn harmony. Phase changes crossfade rather than restart stems; dialogue ducks the mix, credits retain quiet dawn music, menus/failure fade appropriately. Ten original local cues cover anchors, core exposure/hit, sweep, distortion, prison, flame offering, clock activation, defeat and shield rejection. Existing fire ignition/crackle, flares, Time and low-flame sounds remain included, as do separate music/SFX controls and mute.

There are **42 local WAVs total**, including 14 new B.3 assets. The audio is procedural instrumental synthesis, not recorded orchestral performance or field-recorded fire. New original art/audio and optional generators are distributable as documented in `assets/ASSET_NOTES.md` and `assets/audio/AUDIO_CREDITS.md`. No commercial recordings, downloaded samples, external plugins or runtime generators are required.

## Validation performed

Engine: **Godot 4.7.2.stable.official.ed1daf0bf**, Linux, Compatibility renderer for captured views, Dummy audio driver for automated transport.

| Automated suite | Assertions | Scope |
| --- | ---: | --- |
| `test_stage_a.gd` | 50 | Shared controls, flame, Time, shrine, checkpoint and success/failure |
| `test_polish.gd` | 28 | Existing visual/game-feel and bounded corruption regressions |
| `test_combat.gd` | 39 | Existing hunter flare combat, torch damage and recovery |
| `test_audio_loop.gd` | 5 | Original real-time mixer loop/transition transport |
| `test_forest.gd` | 58 | Forest clues, braziers, checkpoint and shrine transition |
| `test_forest_audio.gd` | 6 | Forest audio transport |
| `test_royal.gd` | 70 | Redesigned four-mission hall, mirror geometry, apparition and retries |
| `test_royal_audio.gd` | 8 | Royal audio transport |
| `test_campaign.gd` | 119 | Actual-input traversal from forest through shrine/hall and all four final missions to credits |
| `test_boss.gd` | 66 | Complete 30-check actual-input boss route plus 36 explicit edge-case fixtures |
| `test_boss_audio.gd` | 9 | Four loop seams, synchronization, phase crossfades, new cue playback, mute, credits/menu |
| **Total per validation pass** | **458** | Counts include shared-route checks repeated across suites |

All eleven suites passed in the final source and again after **fresh ZIP extraction/import**. The actual-input boss route does not assign phase, boss angle, flame or player positions; it walks through collisions, waits for real attacks/alignment, channels both anchors and both core strikes, uses the earned sigil, and confirms the final offering. Explicit fixtures separately test locked aim, real projectile impact, sweep hit/dodge, slow recovery, Time holds, channel cancellation, one strike/opening, low-flame restoration, partial checkpoints, ending pause/skip and restart. These are automated simulations, not a human playthrough.

**31 native X11 keyboard/mouse checks** passed, including all eight movement keys, menu selection, dialogue, E channels, Space alignment, sliders/mute, phase retry, rescue, deliberate offering, cinematic pause/skip and credits retry. New mechanic checks use labelled position/state fixtures to isolate physical input.

**18 scripted rendered captures** were inspected: title, arrival, arena overview, anchors/channel, three warning types, aligned/frozen barrier, prison/release, rescue dialogue, offering warning, flame transfer, farewell, sunrise and credits. These use explicit fixture positioning; the overview/attack inspection zoom is not the normal camera. Static scans resolve **224 literal local resource references**, verify input preservation, all 42 PCM16 WAV headers/peaks and matching B.3 music splice endpoints. Archive validation checks CRC and every packaged file against final source bytes. Results are included under `tests/`.

## Limits and remaining work

- No Windows executable was exported or run; Windows templates and target-laptop checks remain local. No measured FPS, hardware performance or full human playthrough/pacing claim is made.
- Dummy mixer tests verify transport, not how music/fire sounds to a listener. Listen on speakers/headphones and balance before competition submission.
- Sprite/cinematic art is cohesive original development art. Kneeling, fallen knight, defeat and sunrise use small procedural/drawn animation rather than a full hand-animated production sequence. No voice acting, gamepad/touch support or accessibility remapping UI was added.
- Progress and volume preferences last only for the running session. A saved campaign across application launches remains future work.
- First-time puzzle clarity, emotional impact and final encounter difficulty still need the team's human playtests. Automated known-solution routes are much faster than a first player and do not establish chapter duration.
- Godot reports its expected Camera2D physics-interpolation mode-selection warning; virtual X11/Mesa reports unsupported VSync changes. Validation found no script errors, missing resources or test failures.

All requested final mission systems, attacks, rescue, clock restoration, ending and campaign connection are implemented. The remaining items are production polish, persistent saving and target-platform/human validation.
