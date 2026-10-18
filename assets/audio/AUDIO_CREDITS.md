# Original A3 audio and permissions

The 14 Stage A3 WAV files retained in this directory were composed and synthesized for EMBERBOUND using the included `tools/generate_audio.py`. No commercial tracks, downloaded samples, recordings, or third-party melodies were used.

The original generated WAV assets and their generation script are provided under CC0 1.0 Universal, so they may be included, modified and redistributed in the game's public repository without an attribution requirement. Optional credit: Original procedural audio for EMBERBOUND.

The exploration stem contains synthesized low drones, string-like harmonic pads, bell partials and plucked tones. The synchronized pursuit stem adds low percussion and a darker pulse. Both are 24 seconds long at 80 BPM, mono PCM16 / 22050 Hz. The fire ambience is a four-second circular noise/crackle loop. Fire ignition is a short filtered-noise whoosh with crackle, not a field recording. The remaining cues use related original noise and tonal envelopes.

Loop points are configured locally by `scripts/audio.gd`. `AUDIO_ANALYSIS.json` records lengths, peaks and splice steps. The generator is optional authoring tooling; Godot plays the committed WAVs without Python or NumPy.

## Stage B1 additions

`forest_ambience.wav`, `footstep.wav`, `rune.wav`, and `wrong_order.wav` are original, deterministic procedural audio made with `tools/generate_forest_audio.py`. These four assets and their generator are also provided under CC0 1.0 Universal. No recordings, commercial tracks or downloaded samples were used. The sixteen-second forest loop uses circular Fourier-noise wind and distant synthesized calls; the other sounds are short, restrained original noise/tonal envelopes. `FOREST_AUDIO_ANALYSIS.json` records their measurements. Listening quality remains a local playtest item.

## Stage B2 additions

Ten original Royal Hall WAVs were composed/synthesized with `tools/generate_royal_audio.py`: `royal_music`, `royal_revelation`, `royal_ambience`, `royal_door`, `royal_mirror`, `royal_seal`, `dialogue_tick`, `illusion_distort`, `revelation_finish`, and `royal_passage`. These WAVs and their generator are CC0 1.0 Universal. No downloaded samples, recordings or existing songs were used. The 24-second synchronized music stems use original minor/modal harmonic pads, descending bell phrases and a low revelation pulse; the 12-second ambience loop uses original spectral wind/room-tone synthesis. `ROYAL_AUDIO_ANALYSIS.json` records lengths, peaks and loop endpoints. These are procedural audio approximations; physical listening and final mix balancing remain local playtests. Godot uses the committed PCM16/22050 Hz WAVs without Python or NumPy.

## Stage B3 original boss and ending audio

Four 24-second synchronized stems (`hour_clock`, `hour_battle`, `hour_rescue`, `hour_dawn`) and ten cues (`anchor_break`, `core_expose`, `core_hit`, `clock_sweep`, `time_pulse`, `prison_open`, `flame_return`, `clock_awaken`, `boss_fall`, `clock_lock`) were composed and synthesized for this project by `tools/generate_boss_audio.py`. All fourteen WAVs and the generator are CC0 1.0 Universal. No recordings, downloaded samples, third-party melody or commercial soundtrack is used. The compositions approximate bowed strings, distant bells, clock ticks, low percussion and a warmer dawn progression using additive/noise synthesis. They are procedural instrumental prototypes, not orchestral recordings. `B3_AUDIO_ANALYSIS.json` records length, peak, RMS and splice endpoints. Runtime uses the committed local PCM16 mono / 22050 Hz WAVs; NumPy is optional authoring tooling only. Mixer loop/crossfade validation is separate from listening quality, which requires human review.
