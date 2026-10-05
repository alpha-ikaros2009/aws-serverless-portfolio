"""api Lambda — REST handlers for the portfolio site (Python 3.13, stdlib + boto3).

Routes are dispatched off API Gateway HTTP API (payload v2) ``routeKey``:

  GET  /health    -> {"status": "ok"}
  GET  /visitors  -> atomically increments and returns the visitor counter
  POST /contact   -> validates {name, email, message}, enqueues a job to SQS,
                     returns 202 (the worker Lambda persists the message)

Single-table DynamoDB access patterns (infra/modules/serverless-app/dynamodb.tf):

  Entity          PK                SK                GSI1PK   GSI1SK
  --------------  ----------------  ----------------  -------  ----------------
  visitor counter VISITOR#counter   VISITOR#counter   -        -
  contact message MSG#<uuid>        MSG#<uuid>        MSG      <unix-timestamp>

  - Counter is read via atomic UpdateItem (if_not_exists + ADD semantics).
  - Messages are written by the worker; GSI1 supports "list all messages,
    newest first" queries without scanning.
"""

import json
import os
import re
import uuid

TABLE_NAME = os.environ.get("TABLE_NAME", "")
QUEUE_URL = os.environ.get("QUEUE_URL", "")

EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")

# boto3 is imported lazily inside the accessors so the module stays importable
# in environments without AWS credentials/regions (unit tests mock the
# accessors and never touch boto3).
_table = None
_sqs = None


def _get_table():
    global _table
    if _table is None:
        import boto3

        _table = boto3.resource("dynamodb").Table(TABLE_NAME)
    return _table


def _get_sqs():
    global _sqs
    if _sqs is None:
        import boto3

        _sqs = boto3.client("sqs")
    return _sqs


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, ensure_ascii=False),
    }


def _health():
    return _response(200, {"status": "ok"})


def _visitors():
    """Atomically increment the visitor counter and return the new value."""
    result = _get_table().update_item(
        Key={"PK": "VISITOR#counter", "SK": "VISITOR#counter"},
        UpdateExpression="SET #c = if_not_exists(#c, :zero) + :inc",
        ExpressionAttributeNames={"#c": "count"},
        ExpressionAttributeValues={":zero": 0, ":inc": 1},
        ReturnValues="UPDATED_NEW",
    )
    return _response(200, {"count": int(result["Attributes"]["count"])})


def _contact(event):
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return _response(400, {"error": "request body must be valid JSON"})

    name = str(body.get("name", "")).strip()
    email = str(body.get("email", "")).strip()
    message = str(body.get("message", "")).strip()

    if not name or not message or not EMAIL_RE.match(email):
        return _response(
            400, {"error": "name, a valid email and a message are required"}
        )

    job = {
        "id": str(uuid.uuid4()),
        "name": name,
        "email": email,
        "message": message,
    }
    _get_sqs().send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(job))
    return _response(202, {"status": "accepted", "id": job["id"]})


_ROUTES = {
    "GET /health": _health,
    "GET /visitors": _visitors,
}


def handler(event, context):
    route_key = event.get("routeKey", "")
    try:
        if route_key in _ROUTES:
            return _ROUTES[route_key]()
        if route_key == "POST /contact":
            return _contact(event)
        return _response(404, {"error": "route not found"})
    except Exception as exc:  # noqa: BLE001 — Lambda top-level safety net
        print(
            json.dumps(
                {"level": "error", "route": route_key, "error": str(exc)},
                ensure_ascii=False,
            )
        )
        return _response(500, {"error": "internal server error"})
