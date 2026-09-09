"""Online RAG assistant isolation and guardrail tests."""
from __future__ import annotations

import os
import sys
from pathlib import Path
from unittest.mock import Mock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.path.insert(0, str(Path(__file__).resolve().parent))

from test_edge_api import EdgeApiTestCase  # noqa: E402


class OnlineAssistantTests(EdgeApiTestCase):
    def tearDown(self):
        os.environ.pop("GEMINI_API_KEY", None)
        super().tearDown()

    def test_missing_key_isolated_as_503(self):
        os.environ.pop("GEMINI_API_KEY", None)
        client = self.client()
        response = client.post("/v1/assistant/ask", json={"question": "Is my soil dry?"})
        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["detail"]["code"], "assistant_unavailable")
        # The local sensor loop still works after the optional assistant fails.
        self.assertEqual(client.post("/v1/readings", json={
            "eventId": "after-assistant-failure", "temperatureC": 30,
        }).status_code, 201)

    def test_question_validation_limits_prompt_size_and_language(self):
        client = self.client()
        self.assertEqual(client.post("/v1/assistant/ask", json={"question": "x"}).status_code, 422)
        self.assertEqual(client.post("/v1/assistant/ask", json={
            "question": "x" * 501,
        }).status_code, 422)
        self.assertEqual(client.post("/v1/assistant/ask", json={
            "question": "hello", "language": "Klingon",
        }).status_code, 422)

    def test_retrieval_is_small_and_relevant(self):
        from app.assistant import retrieve
        passages = retrieve("Why is low soil moisture bad for roots?")
        self.assertLessEqual(len(passages), 3)
        self.assertEqual(passages[0].title, "Soil moisture")

    def test_multilingual_retrieval_and_output_guard(self):
        from app.assistant import _guard_reply, retrieve
        self.assertEqual(retrieve("मिट्टी की नमी कम क्यों है?")[0].title, "Soil moisture")
        guarded = _guard_reply("Apply 5 ml pesticide and I started the pump.", "English")
        self.assertIn("cannot provide chemical dosage", guarded)
        self.assertIn("approve irrigation separately", guarded)

    def test_gemini_receives_retrieved_and_live_farm_context(self):
        os.environ["GEMINI_API_KEY"] = "test-only"
        client = self.client()
        client.post("/v1/readings", json={
            "eventId": "assistant-reading", "zoneId": "zone-a",
            "soilMoisturePct": 18, "temperatureC": 39,
        })
        fake = Mock()
        fake.raise_for_status.return_value = None
        fake.json.return_value = {"candidates": [{"content": {"parts": [
            {"text": "Inspect the soil before irrigating."}
        ]}}]}
        with patch("app.assistant.httpx.post", return_value=fake) as request:
            response = client.post("/v1/assistant/ask", json={
                "question": "Why is my soil dry?", "zoneId": "zone-a",
                "language": "English",
            })
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["answer"], "Inspect the soil before irrigating.")
        sent = request.call_args.kwargs["json"]
        prompt = sent["contents"][0]["parts"][0]["text"]
        self.assertIn("Soil moisture", prompt)
        self.assertIn("latest=18.0", prompt)
        system = sent["system_instruction"]["parts"][0]["text"]
        self.assertIn("Never give pesticide/chemical dosage", system)


if __name__ == "__main__":
    import unittest
    unittest.main()
