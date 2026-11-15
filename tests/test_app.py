import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "app"))
from app import app  # noqa: E402


def client():
    app.config.update(TESTING=True)
    return app.test_client()


def test_index_returns_service_name():
    resp = client().get("/")
    assert resp.status_code == 200
    assert resp.get_json()["service"] == "devsecops-demo"


def test_healthz():
    resp = client().get("/healthz")
    assert resp.status_code == 200
    assert resp.get_json() == {"status": "ok"}
