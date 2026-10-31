def test_health_check(client):
    response = client.get("/health")

    assert response.status_code == 200
    assert response.get_json() == {"status": "ok"}


def test_metrics_endpoint(client):
    response = client.get("/metrics")

    assert response.status_code == 200
    assert b"http_requests_total" in response.data


def test_create_and_list_comment(client, comment_payload):
    create_response = client.post("/api/comment/new", json=comment_payload)

    assert create_response.status_code == 200
    assert create_response.get_json()["status"] == "SUCCESS"

    list_response = client.get("/api/comment/list/content-1")

    assert list_response.status_code == 200
    assert list_response.get_json() == [
        {"email": "user@example.com", "comment": "comentario de teste"}
    ]


def test_list_missing_comment_returns_404(client):
    response = client.get("/api/comment/list/unknown")

    assert response.status_code == 404
    assert response.get_json()["status"] == "NOT-FOUND"


def test_create_comment_without_required_fields_returns_400(client):
    response = client.post("/api/comment/new", json={"email": "user@example.com"})

    assert response.status_code == 400
    assert response.get_json()["status"] == "ERROR"


def test_create_comment_with_invalid_json_returns_400(client):
    response = client.post(
        "/api/comment/new",
        data="not-json",
        content_type="application/json",
    )

    assert response.status_code == 400
    assert response.get_json()["status"] == "ERROR"
