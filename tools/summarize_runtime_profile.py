"""Summarize opt-in CPU timings. Correlation is not GPU/long-frame attribution."""
import argparse
import json
import math
from pathlib import Path


def stats(values):
    ordered = sorted(values)
    if not ordered:
        return {'count': 0}
    return {'count': len(values), 'totalMs': sum(values) / 1000,
            'meanMs': sum(values) / len(values) / 1000,
            'p95Ms': ordered[math.ceil(len(values) * .95) - 1] / 1000,
            'maxMs': ordered[-1] / 1000}


def summarize(record):
    sample = record['frameSample']
    profile = sample['runtimeProfile']
    rows = profile['rows']
    if not sample['valid'] or profile['dropped'] or profile.get('longTaskDropped', 0) or profile.get('longAnimationFrameDropped', 0) or not rows:
        raise ValueError('Invalid/incomplete sample')
    if any(not math.isfinite(r['totalUs']) or r['totalUs'] < 0 or
           any(not math.isfinite(v) or v < 0 for v in r['spans'].values()) for r in rows):
        raise ValueError('Invalid timing')
    sections = sorted({key for row in rows for key in row['spans']})
    ends = sample['frameEndsMs']
    gaps = sample['frameGapsMs']
    if len(ends) != len(gaps):
        raise ValueError('Unmatched rAF intervals')
    long_gaps = []
    tasks = profile.get('longTasks', [])
    animation_frames = profile.get('longAnimationFrames', [])
    for frame in animation_frames:
        for entry, fields in [(frame, ('startMs', 'durationMs', 'blockingDurationMs', 'renderStartMs', 'styleAndLayoutStartMs'))] + [
                (script, ('startMs', 'durationMs', 'executionStartMs', 'forcedStyleAndLayoutDurationMs', 'pauseDurationMs'))
                for script in frame.get('scripts', [])]:
            if any(not math.isfinite(entry[field]) or entry[field] < 0 for field in fields):
                raise ValueError('Invalid long animation frame timing')
    if any(not math.isfinite(t['startMs']) or not math.isfinite(t['durationMs']) or t['durationMs'] < 0 for t in tasks):
        raise ValueError('Invalid long task timing')
    for end, gap in zip(ends, gaps):
        if gap <= 20:
            continue
        overlapping = [r for r in rows if r['endMs'] > end-gap and r['endMs']-r['totalUs']/1000 < end]
        long_gaps.append({'endMs': end, 'gapMs': gap,
                          'overlappingLongTasks': [t for t in tasks if t['startMs'] < end and t['startMs']+t['durationMs'] > end-gap],
                          'overlappingLongAnimationFrames': [f for f in animation_frames if f['startMs'] < end and f['startMs']+f['durationMs'] > end-gap],
                          'overlappingProcessMs': sum(r['totalUs'] for r in overlapping)/1000,
                          'sections': {s: sum(r['spans'].get(s, 0) for r in overlapping)/1000 for s in sections}})
    return {'sequence': sample['sampleSequence'], 'utc': sample['sampledAtUtc'],
            'environment': sample['startEnvironment'], 'fps': sample['fps'],
            'rafP95Ms': sample['p95Ms'], 'rafMaxMs': sample['maxMs'],
            'process': stats([r['totalUs'] for r in rows]),
            'longTasksSupported': profile.get('longTasksSupported', False), 'longTasks': tasks,
            'longAnimationFramesSupported': profile.get('longAnimationFramesSupported', False),
            'longAnimationFrames': animation_frames,
            'sections': {s: stats([r['spans'][s] for r in rows if s in r['spans']]) for s in sections},
            'slowestProcessFrames': sorted(rows, key=lambda r: r['totalUs'], reverse=True)[:8],
            'longRafGaps': long_gaps}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('input', type=Path)
    parser.add_argument('--output', required=True, type=Path)
    args = parser.parse_args()
    samples = {}
    for line in args.input.read_text(encoding='utf-8').splitlines():
        record = json.loads(line)
        sample = record.get('frameSample', {})
        if 'runtimeProfile' in sample:
            samples[(record['url'], sample['sampledAtUtc'], sample['sampleSequence'])] = summarize(record)
    output = {'note': 'Profile adds overhead. Inclusive nested spans cannot be summed. '
              'rAF overlap is temporal evidence only; uninstrumented engine/render/GPU/scheduler costs remain.',
              'samples': list(samples.values())}
    args.output.write_text(json.dumps(output, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'samples': len(samples), 'output': str(args.output)}))
