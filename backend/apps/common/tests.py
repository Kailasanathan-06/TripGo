from django.urls import reverse
from rest_framework.test import APITestCase


class ApiRootTests(APITestCase):
    """The server root is what people open first, so it must not be a bare 404."""

    def test_root_answers_without_a_token(self):
        response = self.client.get("/")

        self.assertEqual(response.status_code, 200)
        data = response.json()["data"]
        self.assertEqual(data["status"], "running")
        self.assertIn("/api/health/", data["health"])

    def test_root_is_reachable_by_name(self):
        response = self.client.get(reverse("api_index"))

        self.assertEqual(response.status_code, 200)


class HealthTests(APITestCase):
    def test_health_reports_ok(self):
        response = self.client.get("/api/health/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"], {"status": "ok", "database": "ok"})
