import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    "measure_plasma", Path(__file__).resolve().parents[1] / "scripts/measure-plasma.py"
)
measure = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(measure)


class MeasurementTests(unittest.TestCase):
    def test_stat_handles_spaces_and_parentheses(self):
        fields = ["0"] * 22
        fields[0] = "S"
        fields[11], fields[12], fields[19] = "200", "100", "900"
        self.assertEqual(
            measure.parse_stat("42 (name with ) parentheses) " + " ".join(fields)),
            (300, 900),
        )

    def test_memory_uses_exact_keys_not_pss_anon(self):
        self.assertEqual(
            measure.parse_rollup("Rss: 8192 kB\nPss: 4096 kB\nPss_Anon: 999 kB"),
            {"Rss": 8192, "Pss": 4096},
        )

    def test_cpu_uses_actual_elapsed_time_and_one_core(self):
        first = {"clock": 10, "ticks": 100}
        last = {"clock": 12, "ticks": 200}
        samples = [
            {"rss_kib": 8192, "pss_kib": 4096},
            {"rss_kib": 10240, "pss_kib": None},
        ]
        result = measure.summarize(samples, first, last, 100)
        self.assertEqual(result["cpu_mean_pct_one_core"], 50)
        self.assertEqual(result["rss_kib"]["median"], 9216)
        self.assertEqual(result["pss_kib_available_samples"], 1)
        self.assertIsNone(
            measure.summarize([{"rss_kib": None, "pss_kib": None}], first, last, 100)["pss_kib"]
        )

    def test_process_restart_cancels_instead_of_mixing_samples(self):
        snapshots = [
            {"start_ticks": 1, "clock": 1, "ticks": 10},
            {"start_ticks": 2, "clock": 2, "ticks": 20},
        ]
        with patch.object(measure, "snapshot", side_effect=snapshots):
            with patch.object(measure.time, "sleep"):
                with self.assertRaisesRegex(RuntimeError, "reiniciou"):
                    measure.sample_phase(Path("/unused"), 1, 1, 100)

    def test_live_proc_read_without_kde(self):
        sample = measure.snapshot(Path("/proc/self"))
        self.assertGreater(sample["start_ticks"], 0)
        self.assertGreaterEqual(sample["ticks"], 0)


if __name__ == "__main__":
    unittest.main()
