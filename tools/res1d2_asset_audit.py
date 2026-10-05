"""Validate Danxia image provenance, layers and Godot placement; never edit pixels."""
import hashlib
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'assets/abode/res1d2'
assets = []
for layer in ('body', 'dressed_reference', 'landmark'):
    path = FOLDER / f'herb_{layer}.png'
    prompt = path.with_suffix('.prompt.txt')
    with Image.open(path) as image:
        assert image.mode == 'RGBA' and image.size == (1536, 1024), path.name
        alpha = image.getchannel('A')
        histogram = alpha.histogram()
        assert histogram[0] > image.width * image.height * .05, 'requires real transparency'
        assert sum(histogram[200:]) > image.width * image.height * .15, 'requires solid subject'
        assert prompt.read_text(encoding='utf-8').strip(), 'requires original prompt'
        assets.append({'file': path.relative_to(ROOT).as_posix(), 'prompt': prompt.name,
                       'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                       'bytes': path.stat().st_size, 'dimensions': list(image.size),
                       'alpha_range': list(alpha.getextrema()), 'fully_transparent_pixels': histogram[0],
                       'runtime': layer != 'dressed_reference', 'layer': layer,
                       'origin': 'OpenAI built-in image_gen, 2026-10-05',
                       'generation': 'Independent generated asset; reference is not sliced into runtime sprites'})
manifest = {
    'task': 'RES1-D2-R1', 'version': 1, 'date': '2026-10-05',
    'status': 'Danxia world integration; human art/playability acceptance pending',
    'pipeline': {'map_mode': 'scene_mode', 'visual_model': 'layered_raster',
                 'runtime_object_model': 'separate_props + interactive_scene_objects',
                 'collision_model': 'trigger_zones', 'engine_target': 'Godot project-native'},
    'license_provenance': 'Original AI-generated project artwork, subject to applicable account service terms. No third-party game art copied. No independent exclusivity/copyright guarantee asserted.',
    'project_references': ['assets/abode/res1c3/wood_body.png', 'assets/abode/res1c3/wood_landmark.png'],
    'runtime_controller': 'src/presentation/island_world.gd',
    'objects': [{'id': 'herb_workshop', 'type': 'composite medicinal industry landmark',
                 'classification': 'tall_or_large_object', 'asset_strategy': 'one_by_one',
                 'render_order': 1, 'collision_role': 'canonical management trigger; no walking actors'}],
    'placement': {'herb': {'world_position': [0, -1550], 'preview_era': 2, 'opening_era': 3},
                  'body': {'anchor': 'center', 'position': [0, 0], 'display_width': 780, 'render_order': 0},
                  'landmark': {'anchor': 'center', 'position': [0, -170], 'display_width': 440,
                               'render_order': 1, 'visibility': 'economy.islands.herb.opened'},
                  'interaction': {'local_rect': [-390, -210, 780, 370],
                                  'action': 'canonical outposts/herb management route',
                                  'camera': 'island_world.enter; reframe on viewport change', 'return': 'home',
                                  'actor_collision': 'not applicable: no walking actors'},
                  'transport': 'grass_home/herb_home/liquid_home only when actual economy.trips exist; no animation payouts'},
    'assets': assets,
}
(FOLDER / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print('PASS: 3 RGBA assets/prompts/hashes; 2 independent runtime layers, 1 reference-only image')
