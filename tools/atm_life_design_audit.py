"""Audit candidate copy provenance/reachability and a bounded archive size model.

Design-only evidence; this does not verify the game's selector or save codec.
"""
import itertools
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'docs/visual-prototype/atm-life-design/cases.json'
OUT = ROOT / 'docs/verification/artifacts/atm-life-design'
data = json.loads(SOURCE.read_text(encoding='utf-8'))
titles, facts = data['titles'], data['facts']
assert 8 <= len(titles) <= 12
assert len({x['id'] for x in titles}) == len(titles)
def select(ids):
    return next(t for t in titles if set(t['requires']) <= set(ids))['id']

copy_checks = 0
for title in titles:
    assert select(title['fixture']) == title['id'], title['id']
    assert len(title['traces']) <= 3 and set(title['traces']) <= set(title['fixture'])
    for sentence in title['sentences']:
        assert set(sentence['refs']) <= set(title['requires'])
        assert sentence['refs'] or title['id'] == 'fallback'
        copy_checks += 1
    for key in title['requires']:
        assert facts[key]['committed'] and facts[key]['life_id'] == 'fixture-life-2'
    assert len(title['title']) <= 6
assert facts['failed']['order'] < facts['later']['order']
assert facts['beast']['order'] < facts['mature']['order']

winners = {t['id']: 0 for t in titles}
keys = list(facts)
for bits in itertools.product([False, True], repeat=len(keys)):
    winners[select([key for key, bit in zip(keys, bits) if bit])] += 1
assert all(winners.values()), winners

# Synthetic maximum-width strings use Chinese + emoji to count UTF-8 bytes,
# not character count. These budgets are a proposal, not a schema commitment.
events = [{'event_id': str(i), 'text': '修行🌙' * 28} for i in range(64)]
assert all(len(json.dumps(e, ensure_ascii=False).encode('utf-8')) <= 384 for e in events)
archive = {'version': 1, 'life_id': 'fixture-life-2', 'events': events,
           'frozen_text': '修行🌙' * 400, 'coverage': 'partial', 'omitted_count': 12}
assert len(archive['frozen_text'].encode('utf-8')) <= 4096
archive_bytes = len(json.dumps(archive, ensure_ascii=False).encode('utf-8'))
assert archive_bytes <= 32768
result = {'kind': 'design audit only', 'copy_sentences': copy_checks,
          'synthetic_combinations': 2**len(keys), 'winners': winners,
          'note': 'Combinations include impossible progressions; counts are not player probabilities.',
          'synthetic_archive_bytes': archive_bytes,
          'proposed_limits': {'archive_count': 10, 'archive_bytes': 32768,
                              'current_life_bytes': 65536, 'total_bytes': 393216},
          'failures': []}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'design-audit.json').write_text(json.dumps(result, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
print(json.dumps(result, ensure_ascii=False))
