"""Recompute R2 desktop rAF evidence; controls never satisfy the game gate."""
import argparse
import json
import math
from pathlib import Path

POLICY = {'targetFps': 60, 'nearTargetFps': 55, 'windowMs': 5000,
          'minimumNearTargetTimeRatio': .8, 'sustainedLowMs': 10000,
          'recoveryTailMs': 10000, 'recoveryTailMinFps': 30, 'minimumSampleDurationMs': 60000}


def recovery_metrics(gaps):
    """Time-weight rAF intervals across fixed windows, including split intervals.

    These are callback-cadence estimates, not GPU presented-frame counts.
    A gap spanning windows contributes its fractional interval to each window.
    """
    windows, elapsed, count, coverage = [], 0.0, 0.0, 0.0
    for gap in gaps:
        remaining = gap
        while remaining > 1e-8:
            portion = min(remaining, POLICY['windowMs'] - coverage)
            coverage += portion
            count += portion / gap
            elapsed += portion
            remaining -= portion
            if coverage >= POLICY['windowMs'] - 1e-8:
                windows.append({'endMs': elapsed, 'durationMs': coverage, 'fps': 1000 * count / coverage})
                count, coverage = 0.0, 0.0
    if coverage > 1e-8:
        windows.append({'endMs': elapsed, 'durationMs': coverage, 'fps': 1000 * count / coverage})
    near_time, low_run, longest_low = 0.0, 0.0, 0.0
    for window in windows:
        window['nearTarget'] = window['fps'] >= POLICY['nearTargetFps']
        if window['nearTarget']:
            near_time += window['durationMs']
            low_run = 0.0
        else:
            low_run += window['durationMs']
            longest_low = max(longest_low, low_run)
    tail_start = max(0, elapsed - POLICY['recoveryTailMs'])
    # User directive 2026-10-09: tail windows (last 10s) pass if >= 30 FPS.
    tail_recovered = elapsed >= POLICY['recoveryTailMs'] and all(
        w['fps'] >= POLICY['recoveryTailMinFps'] for w in windows if w['endMs'] > tail_start + 1e-8)
    ratio = near_time / elapsed
    reasons = []
    if ratio < POLICY['minimumNearTargetTimeRatio']:
        reasons.append('normally_below_near_target')
    if not tail_recovered:
        reasons.append('not_recovered_at_sample_end')
    return {'windows': windows, 'nearTargetTimeRatio': ratio, 'longestLowMs': longest_low,
            'sustainedLowWarning': longest_low >= POLICY['sustainedLowMs'] - 1e-6,
            'tailRecovered': tail_recovered, 'recoveryPass': not reasons, 'reasons': reasons}


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
                        'over20Ms': sum(g > 20 for g in gaps),
                        'durationMs': duration,
                        'eligibleRecoverySample': duration >= POLICY['minimumSampleDurationMs'] and sum(gaps) >= 59000,
                        'recovery': recovery_metrics(gaps)})
    configurations = {json.dumps([s['environment'], s['userAgent'], s['network']], sort_keys=True) for s in samples}
    comparable = len(configurations) == 1
    groups = {}
    for workload in ('game', 'raf_control'):
        group = [s for s in samples if s['workload'] == workload]
        groups[workload] = {'samples': len(group), 'pooledFps': 1000 * sum(s['count'] for s in group) / sum(s['intervalDurationMs'] for s in group) if group else None,
                            'exact60TargetSamples': sum(s['fps'] >= 60 for s in group),
                            'p95AtMost20Samples': sum(s['p95Ms'] <= 20 for s in group),
                            'eligibleRecoverySamples': sum(s['eligibleRecoverySample'] for s in group),
                            'recoveryPassSamples': sum(s['recovery']['recoveryPass'] for s in group)}
    game = groups['game']
    # Keep every sample; short samples can expose failure but cannot prove recovery stability.
    failure = not comparable or bool(rejected) or any(not s['recovery']['recoveryPass'] for s in samples if s['workload'] == 'game')
    gate = 'NOT_PASSED' if failure else ('PASS' if game['eligibleRecoverySamples'] else 'INSUFFICIENT_EVIDENCE')
    return {'method': 'Idle recovery policy v1; v3 rAF raw intervals; all supplied samples retained',
            'policyVersion': 'idle-recovery-v1', 'thresholds': POLICY,
            'comparable': comparable, 'groups': groups, 'desktopRecoveryGate': gate,
            'samples': samples, 'rejected': rejected,
            'note': '60 is a target, not an exact-average gate. Brief 30FPS dips may pass after recovery. '
                    'p95/p99/max remain diagnostic. PASS covers supplied windows, not permanent stability; '
                    '5-minute/action/reload soak and device evidence remain separate. Controls never satisfy the game gate.'}


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
    assert summarize([control])['desktopRecoveryGate'] == 'INSUFFICIENT_EVIDENCE'
    games = [record('game', i, 16.67) for i in range(3)]
    assert summarize(games + [control])['desktopRecoveryGate'] == 'INSUFFICIENT_EVIDENCE'
    games = [record('game', i, 16.6) for i in range(3)]
    assert summarize(games)['desktopRecoveryGate'] == 'INSUFFICIENT_EVIDENCE'
    assert summarize(games + games)['groups']['game']['samples'] == 3
    games[0]['frameSample']['changes'] = [{'type': 'visibility'}]
    assert summarize(games)['desktopRecoveryGate'] == 'NOT_PASSED'
    games = [record('game', i, 16.6) for i in range(3)]
    games[0]['frameSample']['intervalDurationMs'] += 100
    assert summarize(games)['rejected'][0]['reasons'] == ['interval_duration_mismatch']
    games = [record('game', i, 16.6) for i in range(3)]
    games[0]['userAgent'] = 'different browser'
    assert summarize(games)['comparable'] is False
    games = [record('game', i, 16.6) for i in range(3)]
    games[0]['frameSample']['runtimeProfile'] = {'rows': []}
    assert summarize(games)['rejected'][0]['reasons'] == ['instrumented_profile_not_acceptance']
    def timed_record(gaps):
        result = record('game', 1, 16.67)
        result['frameSample'].update(frameGapsMs=gaps, count=len(gaps), durationMs=sum(gaps)+16.67,
                                     intervalDurationMs=sum(gaps))
        return result
    normal = [1000/59.997] * 3600
    assert summarize([timed_record(normal)])['desktopRecoveryGate'] == 'PASS'
    # Five seconds at30, normal60 before/after: slow tail percentile is diagnostic.
    recovered = [1000/60]*1200 + [1000/30]*150 + [1000/60]*2100
    result = summarize([timed_record(recovered)])
    assert result['desktopRecoveryGate'] == 'PASS' and result['samples'][0]['p99Ms'] > 20
    sustained = [1000/60]*1200 + [1000/30]*360 + [1000/60]*1680
    assert summarize([timed_record(sustained)])['desktopRecoveryGate'] == 'NOT_PASSED'
    # Tail drop below 30 FPS fails tail recovery:
    tail_drop = [1000/60]*3300 + [1000/20]*100
    assert summarize([timed_record(tail_drop)])['desktopRecoveryGate'] == 'NOT_PASSED'
    assert summarize([timed_record([1000/30]*1800)])['desktopRecoveryGate'] == 'NOT_PASSED'
    gradual = [1000/fps for fps in (60, 55, 50, 45, 40, 30) for _ in range(fps*10)]
    assert summarize([timed_record(gradual)])['desktopRecoveryGate'] == 'NOT_PASSED'
    # One long interval straddles several windows; never duplicate or hide time.
    spanning = recovery_metrics([10000] + [1000/60]*3000)
    assert spanning['sustainedLowWarning']
    assert math.isclose(sum(w['durationMs'] for w in spanning['windows']), 60000)
    recovered_ten = [1000/60]*1200 + [1000/30]*300 + [1000/60]*1800
    assert summarize([timed_record(recovered_ten)])['desktopRecoveryGate'] == 'PASS'
    print('PASS: 16 frame-summary contracts, including recovered30/persistent30/end-drop/gradual degradation/window splitting')


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
