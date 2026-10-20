import json


def lambda_handler(event, context):
    """Basic handler compatible with API Gateway proxy integration."""
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "Hello from Python Lambda!",
                "path": event.get("path") or event.get("rawPath"),
            }
        ),
    }
