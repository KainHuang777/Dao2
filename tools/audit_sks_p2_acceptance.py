"""Read-only acceptance evidence audit; does not drive UI or mutate game saves."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'docs/verification/artifacts/sks-p2-acceptance'

def read(path):
    return json.loads((ROOT / path).read_text(encoding='utf-8'))

rows = [json.loads(line) for line in (OUT / 'browser-states.jsonl').read_text(encoding='utf-8').splitlines()]
manifest = read('assets/ui/skills-painted/content-p2-skills-manifest.json')
ids = [asset['id'] for asset in manifest['assets']]
costs = {skill['id']: skill['cost'] for skill in read('docs/design-data/sks-p2-proposal.json')['skills']}
events = []
for before, after in zip(rows, rows[1:]):
    if before['era'] != 6 or after['era'] != 6:
        continue
    changed = [sid for sid in ids if after['skills'].get(sid, 0) == before['skills'].get(sid, 0) + 1]
    if len(changed) != 1:
        continue
    sid = changed[0]
    delta = before['points'] - after['points']
    events.append(dict(id=sid, level_before=before['skills'].get(sid, 0), level_after=after['skills'][sid],
                       points_before=before['points'], points_after=after['points'], expected_cost=costs[sid],
                       observed_net=delta, exact_cost_isolated=abs(delta-costs[sid]) < 1e-6,
                       save_failed=after['save_failed'], age_delta=after['age']-before['age']))
last = next(row for row in reversed(rows) if row['era'] == 6)
era4 = next(row for row in rows if row['era'] == 4)
transient = [index for index, row in enumerate(rows) if not all(item['art'] for item in row['items'])]
report = dict(events=events, mouse_changed_ids=sorted({event['id'] for event in events}),
              exact_cost_ids=sorted({event['id'] for event in events if event['exact_cost_isolated']}),
              last_era6=last, failure_snapshots=[row for row in rows if row['save_failed']],
              transient_texture_observations=transient,
              transient_note='Keep reload/initialization observations; final stable rendering is checked separately.')
assert len(report['mouse_changed_ids']) == len(report['exact_cost_ids']) == 12
assert all(item['art'] for item in last['items']) and len(last['items']) == 24
assert all(item['reason'] == 'SKILL_ERA_LOCKED' for item in era4['items'][16:])
assert report['failure_snapshots']
assert all(row['viewport'] == [1280, 720] and row['skill_version'] == 4 and row['economy_version'] == 'res1-e-46-1' for row in rows)
for asset in manifest['assets']:
    assert asset['human_art_acceptance'] == 'ACCEPTED'
    assert hashlib.sha256((ROOT / asset['runtime']).read_bytes()).hexdigest() == asset['sha256']
report['checks'] = dict(all_12_mouse_changed=True, all_12_exact_cost_observed=True,
                        final_24_textures_loaded=True, viewport_1280_720=True,
                        skill_v4_economy_preserved=True, art_12_hashes_match=True)
(OUT / 'browser-audit.json').write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
files = sorted(path for path in (ROOT / 'build/sks-p2-acceptance').rglob('*') if path.is_file())
(OUT / 'web-manifest.json').write_text(json.dumps(dict(kind='L2 local test export; not milestone candidate', files=[
    dict(path=path.relative_to(ROOT).as_posix(), sha256=hashlib.sha256(path.read_bytes()).hexdigest(), bytes=path.stat().st_size)
    for path in files]), indent=2)+'\n', encoding='utf-8')
print('PASS: 12 mouse IDs; 12 exact costs; final 24 textures; 12 art hashes; versions and viewport.')
