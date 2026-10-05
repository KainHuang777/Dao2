from summarize_system_load import summarize


def proc(pid, cpu, name='game'):
    return {'Id': pid, 'CPU': cpu, 'ProcessName': name,
            'PrivateMemorySize64': 1048576}


cpu = [{'utc': '2026-10-04T00:00:00Z', 'logicalProcessors': 4,
        'processes': [proc(1, 10), proc(3, 10)]},
       {'utc': '2026-10-04T00:00:05Z', 'logicalProcessors': 4,
        'processes': [proc(1, 15), proc(2, 100), proc(3, 9)]}]
gpu = [{'utc': '2026-10-04T00:00:03Z', 'gpu': []},
       {'utc': '2026-10-04T00:00:06Z', 'gpu': []}]
metrics = [{'url': '/metrics.html', 'frameSample': {
    'sampledAtUtc': '2026-10-04T00:00:04Z', 'durationMs': 2000,
    'fps': 60, 'sampleSequence': 1, 'valid': True}}]
s = summarize(cpu, gpu, metrics)['samples'][0]
assert len(s['cpuIntervals']) == 1  # Partial overlap is retained, not interpolated.
i = s['cpuIntervals'][0]
assert i['top'][0]['corePercent'] == 100
assert i['totalMachineCpuPercent'] == 25
assert len(i['top']) == 1  # New processes and counter resets are excluded.
assert len(s['gpuSnapshots']) == 1
try:
    summarize([cpu[0], cpu[0]], [], [])
except ValueError:
    pass
else:
    raise AssertionError('duplicate OS timestamp accepted')
print('PASS: 6 system-load contracts (overlap/core/machine/new-reset/GPU/timestamp)')
