"""Read-only source/asset audit, plus reproducible evidence manifest."""
from pathlib import Path
import hashlib
import json
from PIL import Image
ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/content-p1-talents'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
manifest = json.loads((OUT / 'art-manifest.json').read_text(encoding='utf-8'))
checks = []
for asset in manifest['assets']:
    source, runtime = ROOT / asset['source'], ROOT / asset['runtime']
    image = Image.open(runtime)
    assert image.mode == 'RGBA' and image.getextrema()[3] == (0, 255), asset['id']
    assert source.read_bytes() == runtime.read_bytes(), asset['id']
    asset.update(sha256=sha(runtime), size=list(image.size), processing='Byte-identical generated RGBA; no repaint, crop, or resize')
    checks.append(asset['id'] + ': alpha, source, SHA256')
(OUT / 'art-manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
paths = ['src/simulation/talent_system.gd','src/simulation/production.gd','src/simulation/alchemy_system.gd','src/simulation/beast_system.gd','src/simulation/time_advancer.gd','src/simulation/offline_closed_form.gd','src/application/game_session.gd','src/domain/game_state.gd','src/persistence/save_codec.gd','src/persistence/save_manager.gd','src/presentation/reincarnation_panel.gd','src/debug/runtime_inspector.gd','tests/content_p1_talents_runner.gd','tests/content_p1_talents_ui_runner.gd','src/verification/content_p1_talents_acceptance.gd','src/verification/content_p1_talents_fixture.json','project.godot','export_presets.cfg','tools/run_all_runners.ps1']
records = []
paths += ['tests/sks_p1_runner.gd', 'tests/early_v1b_talents_runner.gd', 'assets/ui/reincarnation-painted/manifest.json']
for name in paths:
    p = ROOT / name
    text = p.read_text(encoding='utf-8')
    assert '\x00' not in text and '\ufffd' not in text, name
    records.append({'path':name,'sha256':sha(p)})
for file in ['runner.json','native-ui.json']:
    result = json.loads((OUT/file).read_text(encoding='utf-8'))
    assert result['checks'] > 0 and result['failures'] == [], file
    checks.append(file + ': passed')
frozen = ROOT / 'build/web/index.pck'
assert sha(frozen) == '7e7e619dcaa28fb05e1c397adcc24ce9071d9b53b4e8fa6379c186e0af9f9400'
result = {'task':'CONTENT-P1-TALENT','checks':checks,'sources':records,'frozen_web_sha256':sha(frozen),'failures':[]}
(OUT/'audit.json').write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':len(checks)+len(records)+1,'failures':[],'frozen_web_unchanged':True}))
