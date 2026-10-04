"""Read-only PNG QA plus reproducible provenance/placement manifest; no pixel edits."""
from pathlib import Path
import hashlib
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
folder = root / 'assets/abode/res1c3'
assets = []
for island in ('wood', 'ore'):
    for layer in ('body', 'dressed_reference', 'landmark'):
        name = f'{island}_{layer}'
        path = folder / f'{name}.png'
        prompt = folder / f'{name}.prompt.txt'
        with Image.open(path) as im:
            assert im.mode == 'RGBA', f'{name}: requires alpha'
            assert im.size == (1536, 1024), f'{name}: unexpected canvas'
            alpha = im.getchannel('A')
            histogram = alpha.histogram()
            assert histogram[0] > 0, f'{name}: no transparent pixels'
            assert sum(histogram[200:]) > im.width * im.height * .15, f'{name}: insufficient solid subject'
            assert prompt.read_text(encoding='utf-8').strip(), f'{name}: missing provenance'
            assets.append({'file': path.relative_to(root).as_posix(), 'prompt': prompt.name,
                           'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
                           'bytes': path.stat().st_size, 'dimensions': list(im.size),
                           'alpha_range': list(alpha.getextrema()),
                           'fully_transparent_pixels': histogram[0],
                           'runtime': layer != 'dressed_reference', 'layer': layer,
                           'origin': 'OpenAI built-in image_gen, 2026-10-04',
                           'generation': 'one independent image per asset; reference mockups are not sliced into sprites'})
manifest = {
    'task': 'RES1-C3', 'version': 1, 'date': '2026-10-04',
    'status': 'production art integrated; final human aesthetic acceptance pending',
    'pipeline': {'map_mode': 'scene_mode', 'visual_model': 'layered_raster',
                 'runtime_object_model': 'separate_props + interactive_scene_objects',
                 'collision_model': 'trigger_zones', 'engine_target': 'Godot project-native'},
    'license_provenance': 'Original AI-generated project artwork, subject to the service terms applicable to this account. No third-party game art copied or distributed; no independent exclusivity/copyright guarantee asserted.',
    'project_references': ['assets/abode/terrain.png', 'assets/abode/hut.png'],
    'research': 'docs/15-island-expansion-and-art-direction.md',
    'runtime_controller': 'src/presentation/island_world.gd',
    'placement': {
        'wood': {'world_position': [1450, -100]}, 'ore': {'world_position': [-1450, -100]},
        'body': {'anchor': 'center', 'position': [0, 0], 'display_width': 780, 'render_order': 0},
        'landmark': {'anchor': 'center', 'position': [0, -170], 'display_width': 440, 'render_order': 1, 'visibility': 'economy.islands[id].opened'},
        'interaction': {'local_rect': [-390, -210, 780, 370], 'action': 'canonical island management route', 'camera_focus': 'island_world.enter', 'return': 'home', 'actor_collision': 'not applicable: management world without walking actors'}
    },
    'assets': assets,
}
(folder / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'PASS: {len(assets)} RGBA assets, prompts, hashes; 4 runtime layers, 2 reference-only images')
