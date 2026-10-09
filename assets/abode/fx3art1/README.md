# FX3-ART1 — sunset scene and cloaked cultivator

2026-10-06. Built-in image_gen; prompts saved alongside assets.

- User concept reference: clipboard 3364e04d-f24b-4f25-b416-8f70125a974c.png, supplied by user as a GPT-adjusted concept. Third-party commercial rights are not independently established.
- `sky.png`: scenery-only derivation; foreground island, props and person removed. Screen-space CanvasLayer with aspect-preserving shader, two bounded waterfall regions.
- `terrain.png`: existing `assets/abode/terrain.png` geometry retained as reference; separately generated transparent rock island. 1200 world-unit canvas width, existing building anchors preserved.
- `hero/sheet-transparent.png`: original anonymous gender-neutral hooded cloak figure; single static body asset, magenta keyed with generate2dsprite processor. Separate Node2D; 175 world-unit sprite canvas, feet at (0,-85), spirit core at (0,-170). Runtime motes provide continuous absorption; reduced motion removes moving motes.
- Runtime layers: screen scenery → world island → independent buildings/actor → rear/front formation and VFX → HUD. No collision added: decorative actor does not capture input.
- Source images are AI-generated references/assets, no third-party asset library or brand material introduced. Generation is not a legal commercial-license clearance.

No new gameplay, save fields, resource grants or effect RNG dependency.

2026-10-07 FX3-AMBIENCE: original project shader/GDScript revision (no new raster assets).
The two tear-fall masks now follow the actual sky plate at source x≈0.57/0.69;
downward highlight/distortion stays within the water. Six softly blended mist puffs
rise from the cloud contact zones at (0.565,0.575)/(0.693,0.644), with varied phases
and shader-local per-cycle pseudo-random offsets. Five feathered source-UV debris
patches near the Buddha's left foreground bob 2–4 source pixels over 25–37 seconds;
these remain part of the background plate, not independent playable islands.
No image extraction or generation was performed; original prompts/rights remain.
Cultivator absorption adds three inward blue ribbons and brighter blue/gold motes;
actual attained Era controls count/radius/speed/size, capped at 48 motes from Era7.
Reduced effects stop ribbons/motes and all background animation/mist. Proof and
pending art/device/performance checks: docs/verification/ambience.md.
