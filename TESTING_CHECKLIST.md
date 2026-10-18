# EMBERBOUND Stage B.3 — testing checklist

Automated evidence is in `tests/` and summarized in `IMPLEMENTATION_REPORT.md`. This list is for **your local human playtest**, especially Windows, audible mix quality, first-time clarity and performance. A checked automated assertion is not a human playtest.

## Import and launch

- [ ] Extract into a new folder; import `project.godot` in **Godot 4.7.2 standard**, not the previous working folder.
- [ ] F5 opens the forest title. All four buttons fit without overlap; music/SFX sliders are usable.
- [ ] Development: Hourkeeper / finale loads the new arena with sigil and full flame. F6 on `scenes/hourkeeper.tscn` also works.
- [ ] Shrine-only and Royal Hall development entries still work.
- [ ] Listen with normal speakers/headphones; inspect the debugger for errors.

## Movement, camera and protective flame

- [ ] Test WASD, all arrow keys, diagonals, stopping, boundary/column/rubble collisions and close movement around the prison.
- [ ] Camera follows smoothly at native 1280×720 and your intended window size. The boss and warning shapes remain readable during dodges; no distracting shimmer/jitter.
- [ ] Flame drains, changes torch radius, warns at low level and fails at zero. Combat uses flame, never a new health meter.
- [ ] Flare impact flickers/shrinks the torch temporarily; normal radius returns according to remaining flame. Repeated contact cannot drain everything instantly.
- [ ] Esc pauses flame, boss, hazards and channels; music/SFX controls and M work. R restores clean state.

## Mission 1 — Break the Time Prison

- [ ] Arrival shows the real princess inside a cyan cage, giant clock, boss and two anchor chains. Advance with E/Enter; Q skips; T replays during the anchor phase.
- [ ] Objective explains what to disable and why; progress begins at 0/2. No attacks or depletion interrupt essential dialogue.
- [ ] Wait through a clearly warned attack. Both unfinished anchors visibly expose for 12 seconds, with E prompts and audio.
- [ ] E starts a 1.2s channel; movement cancels with useful feedback. Stand still to complete. Touching the anchor alone does nothing.
- [ ] First chain breaks and progress becomes 1/2. Die or R: this anchor remains disabled with full flame and no duplicate boss/audio.
- [ ] Complete the second anchor: 2/2, weaker prison, broken shield, +25 flame and automatic phase-two objective/checkpoint.

## Mission 2 — Defeat the Hourkeeper

- [ ] The barrier rotates around the boss and crosses the royal symbol south of him. Gold alignment and sound are obvious; the hint explains Space then E.
- [ ] Space away from alignment gives explanatory feedback. Cost/cooldown remain standard; repeated input during cooldown does not spend again.
- [ ] Space at gold alignment freezes barrier and active flares for ~3s. Boss idle animation continues; the opening is temporary.
- [ ] Approach the exposed focus below the boss and E; complete 0.85s channel for one core strike. Movement or thaw cancels without false progress.
- [ ] The same opening cannot award a second strike. Next alignment after recharge permits strike 2/2.
- [ ] Die/R after the first strike: both anchors and strike 1/2 remain. Temporary flares, slow, freeze and channels reset.

### Three fair attacks

- [ ] **Flare:** locked red aim/charge is recognizable; one projectile is dodgeable; a hit removes 5 flame; sound/impact/torch feedback are clear.
- [ ] **Sweep:** 1.55s red sector warns before the large hand moves; leaving the sector, standing inside its hub or outside range avoids damage. A sweep hits at most once for 8 flame.
- [ ] **Distortion:** cyan warning precedes an expanding pulse. A hit slows for 1.6s to 68%, preserves control, causes no flame damage and recovers fully.
- [ ] Major attacks have recovery and do not overlap into an unavoidable trap. Borrowed Time holds active hazards/timers then resumes them.
- [ ] Both western/eastern gold fires remain obvious, safe and reachable. E restores 30 flame, waits 16s, then becomes available again. At low flame you can recover enough for Time.

## Mission 3 — Rescue the Princess

- [ ] Two core strikes cause stagger/disintegration, clear flares and stop all hostile attacks. The game remains player controlled afterward.
- [ ] Objective updates to RESCUE THE PRINCESS and points north. Prison still requires an E interaction with the B.2 sigil.
- [ ] E triggers visible release and short emotional dialogue. Read without attack/depletion pressure; E/Enter/Q behave correctly.
- [ ] Princess is free, follows the knight and the prison no longer blocks movement. R preserves rescue progress.

## Mission 4 — Restore the Dawn

- [ ] Objective points to the central pedestal and explains returning the last flame.
- [ ] First E presents the sacrifice cue without consuming flame. A separate E after dialogue deliberately starts the ending.
- [ ] No passive drain or needless Space spending prevents the final offering after victory.
- [ ] Watch the full ending: raised flame, gold transfer, clock restarts, corruption/darkness recedes, knight falls non-graphically, princess kneels, camera turns to windows, sunrise appears.
- [ ] Ending music changes smoothly from combat to rescue to a warmer dawn. No harsh clipping, overpowering ticking or abrupt loop seam.
- [ ] Final EMBERBOUND / THE LAST HOUR title and credits are readable. The bittersweet story is understandable without excessive exposition.
- [ ] Esc pauses/resumes the cinematic; Q skips to credits; R during ending/credits returns to the offering checkpoint with clean camera/flame state.
- [ ] Carry the light again starts a fresh campaign after a campaign run. Title returns normally; audio does not duplicate.

## Complete campaign regression

- [ ] Play a fresh forest: discover all three clues, solve the ordered braziers, retry a checkpoint, enter shrine.
- [ ] Complete the Circle of Light with the pursuing hunter and Borrowed Time; shrine exit reaches Royal Hall.
- [ ] Princess request → altar warning → two reflector light puzzle → examine mirror → seal/Time apparition encounter → sigil → eastern passage still works.
- [ ] Crossing that passage during campaign play now enters the Hourkeeper arena smoothly, carrying audio preferences, sigil and at least 60 flame.
- [ ] Complete all four final missions and reach credits from this full route.
- [ ] Confirm there are no softlocks, missing textures/audio, duplicate projectiles/enemies or repeated music after several retries.

## Performance and submission

- [ ] Measure frame rate/frame time on the actual Windows laptop during each attack, Time, effects and sunrise; record hardware and resolution before claiming 60 FPS.
- [ ] Leave combat active for several minutes; projectile/corruption/effect counts stay bounded and input remains responsive.
- [ ] Listen to several full music loops and fire ignition/crackle; rebalance at normal device volume.
- [ ] Ask a first-time player to explain each objective and observe where they hesitate. Record actual chapter length/difficulty; automated traversal does not establish human pacing.
- [ ] Replace generic team credits with actual contributor names if desired. Preserve original-asset permissions and competition disclosure requirements.
- [ ] Install matching 4.7.2 Windows export templates, create `build/`, export with the supplied preset, and test the executable on a machine without the editor.

## Re-run automated checks

Import headlessly first, then run `tests/test_campaign.gd` and `tests/test_boss.gd` with `--fixed-fps 60`; run `tests/test_boss_audio.gd` **without** that option. Commands are in README. The full set comprises eleven suites / 458 assertions per pass. Native Linux input and scripted rendering are separate from a human Windows playthrough. Checkpoints/settings are deliberately session-only; closing the application clears progress.
