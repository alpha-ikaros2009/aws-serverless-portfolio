"""worker Lambda — consumes contact-form jobs from SQS and persists them.

Triggered by an SQS event source mapping with ReportBatchItemFailures, so the
handler returns the messageIds of failed records only; those are retried and
eventually redriven to the DLQ (maxReceiveCount = 3).

Writes MSG#<uuid> items into the single DynamoDB table (see the access-pattern
documentation at the top of services/api/handler.py).
"""

import json
import os
import time
import uuid

TABLE_NAME = os.environ.get("TABLE_NAME", "")

_table = None


def _get_table():
    global _table
    if _table is None:
        import boto3

        _table = boto3.resource("dynamodb").Table(TABLE_NAME)
    return _table


def _log(level, event, **fields):
    print(json.dumps({"level": level, "event": event, **fields}, ensure_ascii=False))


def _process_record(record):
    body = json.loads(record["body"])
    message_id = body.get("id") or str(uuid.uuid4())
    now = int(time.time())

    item = {
        "PK": f"MSG#{message_id}",
        "SK": f"MSG#{message_id}",
        "GSI1PK": "MSG",
        "GSI1SK": str(now),
        "id": message_id,
        "name": body.get("name", ""),
        "email": body.get("email", ""),
        "message": body.get("message", ""),
        "received_at": now,
    }
    _get_table().put_item(Item=item)
    _log("info", "contact_message_stored", id=message_id)


def handler(event, context):
    failures = []
    for record in event.get("Records", []):
        try:
            _process_record(record)
        except Exception as exc:  # noqa: BLE001 — isolate per-record failures
            _log(
                "error",
                "record_failed",
                message_id=record.get("messageId"),
                error=str(exc),
            )
            failures.append({"itemIdentifier": record["messageId"]})
    return {"batchItemFailures": failures}
