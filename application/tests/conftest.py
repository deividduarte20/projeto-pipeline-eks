import sys
from pathlib import Path

import pytest

APP_DIR = Path(__file__).resolve().parents[1] / "app"
sys.path.insert(0, str(APP_DIR))

import main  # noqa: E402


@pytest.fixture
def client():
    main.comments.clear()
    main.app.config.update(TESTING=True)
    with main.app.test_client() as test_client:
        yield test_client


@pytest.fixture
def comment_payload():
    return {
        "email": "user@example.com",
        "comment": "comentario de teste",
        "content_id": "content-1",
    }
