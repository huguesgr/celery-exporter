import time

from .exporter import Exporter, transform_option_value


def test_transform_option_value():
    test_cases = [
        {"input": "1423", "expected": 1423},
        {"input": '{"password": "pass"}', "expected": {"password": "pass"}},
        {
            "input": '{invalid_json: "value"}',
            "expected": '{invalid_json: "value"}',
        },
        {"input": "my_master", "expected": "my_master"},
    ]

    for case in test_cases:
        assert transform_option_value(case["input"]) == case["expected"]


def test_each_event_resets_the_time_since_the_last_event():
    exporter = Exporter()
    exporter.last_event_received = time.monotonic() - 600
    events = []
    handler = exporter.record_event_time(events.append)

    handler({"type": "worker-heartbeat"})

    assert events == [{"type": "worker-heartbeat"}]
    assert exporter.seconds_since_last_event() < 1
