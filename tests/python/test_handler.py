import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "src" / "python"))

from handler import lambda_handler  # noqa: E402


def test_returns_200_json():
    response = lambda_handler({"path": "/orders"}, None)

    assert response["statusCode"] == 200
    assert response["headers"]["Content-Type"] == "application/json"


def test_body_includes_message_and_path():
    body = json.loads(lambda_handler({"path": "/orders"}, None)["body"])

    assert body["message"] == "Hello from Python Lambda!"
    assert body["path"] == "/orders"


def test_uses_raw_path_for_http_api_events():
    body = json.loads(lambda_handler({"rawPath": "/orders"}, None)["body"])

    assert body["path"] == "/orders"


def test_path_is_none_when_missing():
    body = json.loads(lambda_handler({}, None)["body"])

    assert body["path"] is None
