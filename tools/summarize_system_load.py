"""Correlate read-only OS samples with dated browser samples; no causal claims."""
import argparse
import json
from datetime import datetime
from pathlib import Path


def timestamp(value):
    return datetime.fromisoformat(value.replace('Z', '+00:00')).timestamp()


def read(path):
    return [json.loads(line) for line in Path(path).read_text(encoding='utf-8-sig').splitlines() if line.strip()]


def summarize(cpu, gpu, metrics):
    intervals = []
    for before, after in zip(cpu, cpu[1:]):
        start, end = timestamp(before['utc']), timestamp(after['utc'])
        if end <= start:
            raise ValueError('OS timestamps must increase')
        old = {p['Id']: p for p in before['processes']}
        processes = []
        for p in after['processes']:
            previous = old.get(p['Id'])
            if previous is None or previous['ProcessName'] != p['ProcessName']:
                continue
            delta = p['CPU'] - previous['CPU']
            if delta < 0:
                continue
            processes.append({'pid': p['Id'], 'name': p['ProcessName'],
                              'corePercent': 100 * delta / (end-start),
                              'privateMB': p['PrivateMemorySize64'] / 1048576,
                              'privateDeltaMB': (p['PrivateMemorySize64']-previous['PrivateMemorySize64']) / 1048576})
        intervals.append({'startUtc': before['utc'], 'endUtc': after['utc'],
                          'totalMachineCpuPercent': sum(p['corePercent'] for p in processes)/after['logicalProcessors'],
                          'top': sorted(processes, key=lambda p: p['corePercent'], reverse=True)[:8]})
    samples = []
    for row in metrics:
        s = row.get('frameSample')
        if not s:
            continue
        end = timestamp(s['sampledAtUtc'])
        start = end - s['durationMs']/1000
        matched = [i for i in intervals if timestamp(i['endUtc']) > start and timestamp(i['startUtc']) < end]
        samples.append({'url': row['url'], 'sampleSequence': s['sampleSequence'], 'sampledAtUtc': s['sampledAtUtc'],
                        'fps': s['fps'], 'valid': s['valid'], 'cpuIntervals': matched,
                        'gpuSnapshots': [g for g in gpu if start <= timestamp(g['utc']) <= end]})
    return {'note': 'CPU corePercent: 100 = one logical core. Machine CPU excludes new/inaccessible processes. GPU per-engine snapshots must not be summed across engines. Shared app GPU process is not per-tab attribution. Correlation does not prove causation. OS wall clock alignment is approximate.',
            'cpuSnapshotCount': len(cpu), 'gpuSnapshotCount': len(gpu), 'samples': samples}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('cpu')
    parser.add_argument('gpu')
    parser.add_argument('metrics')
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = summarize(read(args.cpu), read(args.gpu), read(args.metrics))
    Path(args.output).write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'cpuSnapshots': result['cpuSnapshotCount'], 'gpuSnapshots': result['gpuSnapshotCount'],
                      'samples': [{'fps': s['fps'], 'valid': s['valid'], 'cpuIntervals': len(s['cpuIntervals']), 'gpuSnapshots': len(s['gpuSnapshots'])} for s in result['samples']]}, indent=2))
