"""Unit tests for the worker Lambda handler.

Run from this directory:  python -m unittest discover -v
No third-party dependencies: the DynamoDB accessor is mocked.
"""

import json
import os
import unittest
from unittest import mock

os.environ.setdefault("TABLE_NAME", "test-table")

import handler  # noqa: E402


def _record(body, message_id="msg-1"):
    return {"messageId": message_id, "body": json.dumps(body)}


class HappyPathTest(unittest.TestCase):
    def test_stores_message_and_reports_no_failures(self):
        table = mock.MagicMock()
        event = {
            "Records": [
                _record(
                    {
                        "id": "abc-123",
                        "name": "王小明",
                        "email": "ming@example.com",
                        "message": "你好",
                    }
                )
            ]
        }

        with mock.patch.object(handler, "_get_table", return_value=table):
            result = handler.handler(event, None)

        self.assertEqual(result, {"batchItemFailures": []})

        item = table.put_item.call_args.kwargs["Item"]
        self.assertEqual(item["PK"], "MSG#abc-123")
        self.assertEqual(item["SK"], "MSG#abc-123")
        self.assertEqual(item["GSI1PK"], "MSG")
        self.assertEqual(item["email"], "ming@example.com")
        self.assertTrue(item["GSI1SK"].isdigit())


class FailurePathTest(unittest.TestCase):
    def test_bad_record_is_reported_as_batch_item_failure(self):
        table = mock.MagicMock()
        event = {
            "Records": [
                _record({"id": "ok-1", "name": "A", "email": "a@b.co", "message": "hi"}, "msg-ok"),
                {"messageId": "msg-bad", "body": "{not json"},
            ]
        }

        with mock.patch.object(handler, "_get_table", return_value=table):
            result = handler.handler(event, None)

        # Only the malformed record is retried; the good one succeeded.
        self.assertEqual(result, {"batchItemFailures": [{"itemIdentifier": "msg-bad"}]})
        self.assertEqual(table.put_item.call_count, 1)

    def test_dynamodb_error_is_reported_as_failure(self):
        table = mock.MagicMock()
        table.put_item.side_effect = RuntimeError("throttled")
        event = {"Records": [_record({"id": "x"}, "msg-err")]}

        with mock.patch.object(handler, "_get_table", return_value=table):
            result = handler.handler(event, None)

        self.assertEqual(result, {"batchItemFailures": [{"itemIdentifier": "msg-err"}]})


if __name__ == "__main__":
    unittest.main()
