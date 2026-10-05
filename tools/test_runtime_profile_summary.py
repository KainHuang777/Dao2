import copy
import unittest
from summarize_runtime_profile import stats, summarize


class ProfileSummaryTests(unittest.TestCase):
    def fixture(self):
        return {'frameSample': {'valid': True, 'sampleSequence': 1, 'sampledAtUtc': 'test',
            'startEnvironment': {'viewport': [1280, 720]}, 'fps': 50, 'p95Ms': 25, 'maxMs': 25,
            'frameEndsMs': [25], 'frameGapsMs': [25],
            'runtimeProfile': {'dropped': 0, 'rows': [
                {'endMs': 22, 'totalUs': 18000, 'spans': {'save_total': 17000, 'save_encode': 12000}}]}}}

    def test_units_and_nearest_rank(self):
        self.assertEqual(stats([1000, 2000, 3000]),
                         {'count': 3, 'totalMs': 6, 'meanMs': 2, 'p95Ms': 3, 'maxMs': 3})

    def test_nested_spans_not_added_to_process(self):
        result = summarize(self.fixture())
        self.assertEqual(result['process']['totalMs'], 18)
        self.assertEqual(result['sections']['save_encode']['totalMs'], 12)
        self.assertEqual(result['longRafGaps'][0]['overlappingProcessMs'], 18)

    def test_reject_incomplete_or_bad_timing(self):
        for mutate in [lambda s: s.update(valid=False),
                       lambda s: s['runtimeProfile'].update(dropped=1),
                       lambda s: s.update(frameEndsMs=[]),
                       lambda s: s['runtimeProfile']['rows'][0].update(totalUs=-1),
                       lambda s: s['runtimeProfile']['rows'][0].update(totalUs=float('nan'))]:
            record = copy.deepcopy(self.fixture())
            mutate(record['frameSample'])
            with self.assertRaises(ValueError):
                summarize(record)

    def test_long_task_correlation_and_validation(self):
        record = self.fixture()
        profile = record['frameSample']['runtimeProfile']
        profile.update(longTasksSupported=True, longTasks=[{'startMs': 0, 'durationMs': 60, 'name': 'self'}])
        result = summarize(record)
        self.assertEqual(result['longRafGaps'][0]['overlappingLongTasks'], profile['longTasks'])
        self.assertEqual(result['process']['totalMs'], 18)  # Never add browser tasks to CPU spans.
        profile['longTaskDropped'] = 1
        with self.assertRaises(ValueError):
            summarize(record)
        profile['longTaskDropped'] = 0
        profile['longTasks'][0]['durationMs'] = float('nan')
        with self.assertRaises(ValueError):
            summarize(record)

    def test_animation_frame_attribution_and_validation(self):
        record = self.fixture()
        profile = record['frameSample']['runtimeProfile']
        frame = {'startMs': 0, 'durationMs': 60, 'blockingDurationMs': 10,
                 'renderStartMs': 1, 'styleAndLayoutStartMs': 59, 'scripts': [
                     {'startMs': 2, 'durationMs': 50, 'executionStartMs': 2,
                      'forcedStyleAndLayoutDurationMs': 0, 'pauseDurationMs': 0,
                      'sourceURL': 'index.js'}]}
        profile.update(longAnimationFramesSupported=True, longAnimationFrames=[frame])
        result = summarize(record)
        self.assertEqual(result['longRafGaps'][0]['overlappingLongAnimationFrames'], [frame])
        self.assertEqual(result['process']['totalMs'], 18)
        profile['longAnimationFrameDropped'] = 1
        with self.assertRaises(ValueError):
            summarize(record)
        profile['longAnimationFrameDropped'] = 0
        frame['scripts'][0]['durationMs'] = float('nan')
        with self.assertRaises(ValueError):
            summarize(record)


if __name__ == '__main__':
    unittest.main()
