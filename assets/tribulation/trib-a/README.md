2026-10-18: User accepted the TRIB-A material direction and authorized TRIB-B. Static art delivery is DONE; dynamic acceptance is separate. Earlier pending-acceptance notes below are historical.

# TRIB-A — layered tribulation art candidate

2026-10-18. **Asset/static delivery; pending human visual acceptance.** No runtime scene or formal world references these textures yet. See [review report](../../../docs/verification/trib-a.md).

Built-in `image_gen` produced 16 originals. Fifteen selected originals become 22 packaged PNGs: two opaque cloud/celestial plates; Buddha; paired waterfall reference; distant island; near/far mist; four actor poses; intact/cracked/shattered shield; Asura apparition; two independent waterfall regions; four pose emission masks; one analytic contact shadow. The first shattered-shield attempt is rejected (still a connected ring); preserved under verification originals, never selected.

References are the existing `assets/abode/fx3art1/sky.png` and `hero/sheet-transparent.png`. The original user concept's third-party commercial rights are **not independently established**; AI generation does not constitute legal clearance. No third-party stock, character brand, font or audio was added. Existing terrain is reused read-only with its SHA256 in the manifest. The distant island is decorative scenery, not a newly unlocked playable island.

`generation-prompts.json` contains the exact prompts for all 16 calls, including rejected work. `docs/verification/artifacts/trib-a/generation-records.json` maps prompt IDs to built-in output file IDs. Every original is copied into that directory's `originals/`. The evidence directory has `.gdignore` to keep raw/reference/review images out of engine import. Packaged files and engine `.import` files are in this directory.

## Canvas, anchors and layers

Transparent sprites preserve generated RGBA and aspect ratio inside an 896px box on a 1024px transparent canvas (at least 64px padding). No chroma key, manual alpha cleaning or painted replacement is applied. Wide sprites retain their aspect inside that square, not stretched. The two opaque backgrounds preserve original generated dimensions and are intended for aspect-fill with overscan. Two narrow water regions use 512×1024 canvases; the separate shadow is 512×256. Raw and packaged hashes, region operations, z order and transform limits are recorded in `manifest.json`.

All actor poses and their masks share 1024×1024 canvases. They intentionally have **different measured chest positions**. Use `core_packed_uv` for each pose to align the stage's fixed spirit core; do not interchange texture centers. `core_source_uv` documents the measurement before packing. The local source-to-pack transform is `(64 + source_uv * 896) / 1024`. Mask alpha is pose alpha multiplied by a radial smooth falloff around that chest; white RGB carries emission strength, not a second opaque body. Mask and pose anchors are identical. The island shadow must remain on the island when the body rises.

Buddha and water are separate. Dry tear channels in the stone are not painted water. Map the measured raw Buddha eye UVs `(0.365,0.45)` and `(0.61,0.41)` through the same packing transform, then attach the water via each region's `water_attachment_uv`. The paired `waterfalls.png` is a source reference, not a required additional drawn layer over the split regions. Don't draw all three together.

The explicit `z_order` is authoritative: cloud/stellar plates → far island → Buddha/water → far mist → terrain → shadow → apparition/rear shield → actor → emission/front shield cracks/lightning contact → near mist → separate UI. Asura is a narrative illusion behind the actor, not a boss, death state or a new mind-stat mechanic. Actor poses, shield appearance and six storyboard compositions are candidates; original formal character/background assets are untouched.

## Reproduction and limits

Run the repository Godot 4.7.2 with `--headless --path . --script res://tools/trib_a_assets.gd`, using an **absolute** `--log-file` in the evidence directory. Run `tools/trib_a_review.ps1` for labeled sheets, `tools/trib_a_verify.ps1` for source/hash/UTF-8 checks and `tools/trib_a_texture_check.gd` for imported Texture2D decoding. The packer is an offline Image tool; its direct PNG reads are not runtime export code.

Six keyframes are assembled from these exact layers: omen, ascent, celestial curtain, hit, successful return, failed return. Three aspect ratios are composed independently (1280×720, 844×390, 800×360), with per-pose core placement and no UI. The procedural bolt is a static endpoint guide, not accepted final lightning. No fish-eye, real glow rendering, dynamic timing, sound mixing, gameplay result, browser interaction or FPS is proved by these images. These belong to TRIB-B/C after visual direction acceptance.
