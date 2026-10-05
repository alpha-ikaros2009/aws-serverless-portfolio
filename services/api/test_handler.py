"""Unit tests for the api Lambda handler.

Run from this directory:  python -m unittest discover -v
No third-party dependencies: boto3 accessors are mocked.
"""

import json
import os
import unittest
from unittest import mock

os.environ.setdefault("TABLE_NAME", "test-table")
os.environ.setdefault("QUEUE_URL", "https://sqs.example.invalid/queue")

import handler  # noqa: E402


class HealthRouteTest(unittest.TestCase):
    def test_health_returns_ok(self):
        resp = handler.handler({"routeKey": "GET /health"}, None)

        self.assertEqual(resp["statusCode"], 200)
        self.assertEqual(json.loads(resp["body"]), {"status": "ok"})


class VisitorsRouteTest(unittest.TestCase):
    def test_increments_counter_atomically(self):
        table = mock.MagicMock()
        table.update_item.return_value = {"Attributes": {"count": 42}}

        with mock.patch.object(handler, "_get_table", return_value=table):
            resp = handler.handler({"routeKey": "GET /visitors"}, None)

        self.assertEqual(resp["statusCode"], 200)
        self.assertEqual(json.loads(resp["body"]), {"count": 42})

        kwargs = table.update_item.call_args.kwargs
        self.assertEqual(kwargs["Key"], {"PK": "VISITOR#counter", "SK": "VISITOR#counter"})
        self.assertIn("if_not_exists", kwargs["UpdateExpression"])
        self.assertEqual(kwargs["ReturnValues"], "UPDATED_NEW")


class ContactRouteTest(unittest.TestCase):
    def test_valid_submission_returns_202_and_enqueues(self):
        sqs = mock.MagicMock()

        with mock.patch.object(handler, "_get_sqs", return_value=sqs):
            resp = handler.handler(
                {
                    "routeKey": "POST /contact",
                    "body": json.dumps(
                        {"name": "王小明", "email": "ming@example.com", "message": "你好"}
                    ),
                },
                None,
            )

        self.assertEqual(resp["statusCode"], 202)
        body = json.loads(resp["body"])
        self.assertEqual(body["status"], "accepted")
        self.assertTrue(body["id"])
        sqs.send_message.assert_called_once()

    def test_missing_fields_returns_400(self):
        resp = handler.handler(
            {"routeKey": "POST /contact", "body": json.dumps({"name": "", "email": "", "message": ""})},
            None,
        )

        self.assertEqual(resp["statusCode"], 400)

    def test_invalid_email_returns_400(self):
        resp = handler.handler(
            {
                "routeKey": "POST /contact",
                "body": json.dumps({"name": "A", "email": "not-an-email", "message": "hi"}),
            },
            None,
        )

        self.assertEqual(resp["statusCode"], 400)

    def test_invalid_json_returns_400(self):
        resp = handler.handler({"routeKey": "POST /contact", "body": "{not json"}, None)

        self.assertEqual(resp["statusCode"], 400)


class UnknownRouteTest(unittest.TestCase):
    def test_unknown_route_returns_404(self):
        resp = handler.handler({"routeKey": "DELETE /everything"}, None)

        self.assertEqual(resp["statusCode"], 404)


if __name__ == "__main__":
    unittest.main()
