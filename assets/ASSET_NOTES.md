# A2 placeholder asset notes

The knight and hunter are original code-authored pixel sprites, rasterized once from small canvases in `scripts/pixel_art.gd` and cached as textures. The knight has front, side and back views with four gait frames each; left-facing uses a mirror of the side view. The hunter has six shroud frames. They are development art, not a finished production sprite sheet.

Stonework, corruption, lamps, runes, glows and particles use original Godot drawing code. `icon.svg` remains the original ember icon. The local atmosphere shader is in `atmosphere.gdshader`. Text uses Godot's built-in fallback font. A3 replaces the earlier sine-wave cues with local original WAVs and adds music/fire/combat audio; see `audio/AUDIO_CREDITS.md`.

There are no downloaded asset packs, plugins or network dependencies. The supplied moodboard remains a direction reference and is not bundled as a gameplay asset. Add contributor and license records when final art/audio replaces this pass.

## Stage B1 original forest assets

Three 96×128 tree variants and one 40×64 broken pillar were authored as pixel geometry in `scripts/forest/forest_art.gd`, baked by `tools/bake_forest.gd` into the included `assets/forest/*.png`, and rendered at 2× with nearest filtering. Floor, ruins, glyphs, fog, memorial, bell and tomb are original code-native drawing. No external art downloads or image-generation service is required. The new forest images and authoring source may be modified and redistributed in EMBERBOUND's public repository (CC0). The earlier knight, hunter, shrine art and atmosphere shader remain included.

## Stage B2 original Royal Hall artwork

`assets/royal/` contains six original local PNGs: `princess_idle.png` (four 40×56 frames), `false_princess_idle.png` (four 64×80 frames), `throne.png` (192×224), `column.png` (80×168), `torn_banner.png` (64×112), and `broken_window.png` (112×152). All are authored as original pixel geometry in `scripts/royal/royal_art.gd`; `tools/bake_royal.gd` reproduces the committed images. Normal world sprites render at 2× nearest filtering; the wide arrival camera uses a 0.5× view. The PNGs and new art-authoring code are offered under CC0 for modification and public distribution with EMBERBOUND. No external image files or generated concept illustrations are needed at runtime. Flooring, carpet, mirror, royal seal, statues, moonbeams, clock and revelation effects are code-native drawing layered with the retained A3 knight/hunter art.

## B2 Mission Redesign

All existing PNGs/WAVs are preserved byte-for-byte. The royal altar, rotating silver reflector faces, traced beam packets, objective markers and freed sigil are original Godot drawing code in the Royal Hall scripts. These additional visual elements may be used/modified/distributed with the existing original CC0 placeholder assets. No external art or audio files are required.

## Stage B3 original finale artwork

Five `assets/boss/hourkeeper_*.png` sheets contain four 96×128 frames each for idle, charge, release, stagger and defeat; `scripts/boss/boss_art.gd` and `tools/bake_boss.gd` reproduce them. The imposing clock sorcerer is drawn at 2× nearest filtering. Clockwork floor, prison cage, two anchors, fire sources, barrier, attacks, final pedestal and sunrise city/window are original code-native pixel-styled drawing. Normal knight art remains inherited from the existing player; the boss-specific subclass adds only offering and non-graphic fallen poses. The real princess reuses the original pale princess sheet with prison/release/follow/kneel presentation. These new original artwork assets and authoring sources are CC0 1.0 Universal for EMBERBOUND's use, modification and redistribution. No moodboard raster, downloaded art pack or external concept image is required at runtime.
