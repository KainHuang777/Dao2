"""Recompute R2 desktop rAF evidence; controls never satisfy the game gate."""
import argparse
import json
import math
from pathlib import Path


def summarize(records):
    samples, rejected, seen = [], [], set()
    for record in records:
        sample = record.get('frameSample')
        if not sample:
            continue
        key = (record.get('url'), sample.get('sampledAtUtc'), sample.get('sampleSequence'))
        if key in seen:
            continue
        seen.add(key)
        reasons = []
        if 'runtimeProfile' in sample:
            reasons.append('instrumented_profile_not_acceptance')
        if record.get('measurementVersion') != 3:
            reasons.append('requires_v3_environment_history')
        if sample.get('valid') is not True:
            reasons.extend(sample.get('invalidReasons') or ['invalid_sample'])
        gaps = sample.get('frameGapsMs', [])
        if not gaps or any(not isinstance(g, (int, float)) or not math.isfinite(g) or g <= 0 for g in gaps):
            reasons.append('invalid_intervals')
        if sample.get('count') != len(gaps):
            reasons.append('count_mismatch')
        duration = sample.get('durationMs', 0)
        if not isinstance(duration, (int, float)) or not math.isfinite(duration) or duration < 15000:
            reasons.append('short_sample')
        if gaps and 'invalid_intervals' not in reasons:
            if not math.isclose(sum(gaps), sample.get('intervalDurationMs', -1), rel_tol=1e-9, abs_tol=1e-6):
                reasons.append('interval_duration_mismatch')
        start, end = sample.get('startEnvironment', {}), sample.get('endEnvironment', {})
        if start != end or sample.get('changes') or start.get('visible') != 'visible':
            reasons.append('unstable_environment')
        workload = sample.get('workload')
        if workload not in ('game', 'raf_control') or workload != record.get('workload'):
            reasons.append('unknown_workload')
        if workload == 'game' and (sample.get('startedBeforeReady') is not False or sample.get('endedAfterReady') is not True):
            reasons.append('game_not_ready')
        if reasons:
            rejected.append({'url': record.get('url'), 'sequence': sample.get('sampleSequence'), 'reasons': reasons})
            continue
        sorted_gaps = sorted(gaps)
        percentile = lambda p: sorted_gaps[math.ceil(len(gaps) * p) - 1]
        samples.append({'url': record['url'], 'sequence': sample['sampleSequence'], 'sampledAtUtc': sample['sampledAtUtc'],
                        'workload': workload, 'environment': start, 'userAgent': record.get('userAgent'),
                        'network': record.get('network'), 'count': len(gaps), 'intervalDurationMs': sum(gaps),
                        'fps': 1000 * len(gaps) / sum(gaps), 'medianMs': percentile(.5),
                        'p95Ms': percentile(.95), 'p99Ms': percentile(.99), 'maxMs': max(gaps),
                        'over20Ms': sum(g > 20 for g in gaps)})
    configurations = {json.dumps([s['environment'], s['userAgent'], s['network']], sort_keys=True) for s in samples}
    comparable = len(configurations) == 1
    groups = {}
    for workload in ('game', 'raf_control'):
        group = [s for s in samples if s['workload'] == workload]
        groups[workload] = {'samples': len(group), 'pooledFps': 1000 * sum(s['count'] for s in group) / sum(s['intervalDurationMs'] for s in group) if group else None,
                            'strict60PassSamples': sum(s['fps'] >= 60 for s in group),
                            'p95AtMost20PassSamples': sum(s['p95Ms'] <= 20 for s in group)}
    game = groups['game']
    # Multiple samples must all pass. No rounding, baseline normalization or best-sample selection.
    passed = comparable and not rejected and game['samples'] >= 3 and game['strict60PassSamples'] == game['samples'] and game['p95AtMost20PassSamples'] == game['samples']
    return {'method': 'R2 v3 rAF proxy; raw intervals recomputed; all comparable game samples required',
            'thresholds': {'fps': 60, 'p95Ms': 20, 'minimumGameSamples': 3},
            'comparable': comparable, 'groups': groups, 'strictDesktopGate': 'PASS' if passed else 'NOT_PASSED',
            'samples': samples, 'rejected': rejected,
            'note': 'Controls characterize browser scheduling only. No GPU, phone, high-DPR or human acceptance inferred.'}


def self_test():
    env = {'viewport': [1280, 650], 'dpr': 1, 'visible': 'visible'}
    def record(kind, seq, gap):
        count = math.floor(15000 / gap)
        return {'url': 'test/' + kind, 'measurementVersion': 3, 'workload': kind,
                'frameSample': {'sampledAtUtc': str(seq), 'sampleSequence': seq, 'workload': kind,
                                'valid': True, 'startEnvironment': env, 'endEnvironment': env, 'changes': [],
                                'durationMs': (count + 1) * gap, 'count': count,
                                'intervalDurationMs': gap * count, 'frameGapsMs': [gap] * count,
                                'startedBeforeReady': False, 'endedAfterReady': kind == 'game'}}
    control = record('raf_control', 1, 16)
    assert summarize([control])['strictDesktopGate'] == 'NOT_PASSED'
    games = [record('game', i, 16.67) for i in range(3)]
    assert summarize(games + [control])['strictDesktopGate'] == 'NOT_PASSED'
    games = [record('game', i, 16.6) for i in range(3)]
    assert summarize(games)['strictDesktopGate'] == 'PASS'
    assert summarize(games + games)['groups']['game']['samples'] == 3
    games[0]['frameSample']['changes'] = [{'type': 'visibility'}]
    assert summarize(games)['strictDesktopGate'] == 'NOT_PASSED'
    games = [record('game', i, 16.6) for i in range(3)]
    games[0]['frameSample']['intervalDurationMs'] += 100
    assert summarize(games)['rejected'][0]['reasons'] == ['interval_duration_mismatch']
    games = [record('game', i, 16.6) for i in range(3)]
    games[0]['userAgent'] = 'different browser'
    assert summarize(games)['comparable'] is False
    games = [record('game', i, 16.6) for i in range(3)]
    games[0]['frameSample']['runtimeProfile'] = {'rows': []}
    assert summarize(games)['rejected'][0]['reasons'] == ['instrumented_profile_not_acceptance']
    print('PASS: 8 frame-summary contract cases')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('input', nargs='?', type=Path)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--self-test', action='store_true')
    args = parser.parse_args()
    if args.self_test:
        self_test()
    elif args.input:
        result = summarize([json.loads(line) for line in args.input.read_text(encoding='utf-8').splitlines() if line.strip()])
        rendered = json.dumps(result, ensure_ascii=False, indent=2)
        if args.output:
            args.output.write_text(rendered + '\n', encoding='utf-8')
        print(rendered)
    else:
        parser.error('input or --self-test required')
