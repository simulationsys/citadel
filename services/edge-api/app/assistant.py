"""Small online-only RAG assistant isolated from the local control loop."""
from __future__ import annotations

import os
import re
from dataclasses import dataclass
from pathlib import Path

import httpx
from dotenv import load_dotenv

from .analytics import build_report

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

MODEL = os.getenv("CITADEL_ASSISTANT_MODEL", "gemini-2.5-flash")
ENDPOINT = "https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent"


@dataclass(frozen=True)
class Passage:
    title: str
    text: str


KNOWLEDGE = [
    Passage("Soil moisture", "Low soil moisture reduces water available to roots. Excess moisture can reduce root oxygen. Check calibration and inspect soil before irrigating."),
    Passage("Heat stress", "High temperature combined with dry soil increases water loss and crop stress. Inspect for wilting and prefer cooler irrigation hours when appropriate."),
    Passage("Humidity and disease", "Warm, humid conditions can favour crop disease. Humidity is a risk indicator, not a diagnosis. Inspect leaves before treatment."),
    Passage("Rain and flooding", "Heavy rain or high water should suppress irrigation advice. Inspect drainage, avoid standing water, and keep electrical equipment safe."),
    Passage("Crop scans", "Citadel currently analyzes close-up tomato leaves. Results are decision support, not final diagnosis. Poor images should be recaptured."),
    Passage("Pest safety", "Confirm a pest and its extent before intervention. Do not provide pesticide or chemical dosage without qualified local guidance and product labels."),
    Passage("Irrigation safety", "An advisory never activates a pump. Citadel requires farmer approval, a bounded command, and hardware acknowledgement."),
    Passage("Sensor reliability", "Missing readings stay unavailable. Check wiring, power, placement, calibration, and transmission time before acting on unusual values."),
    Passage("Offline operation", "Local monitoring and analytics work without internet. The Gemini assistant is optional and available only when internet returns."),
]


class AssistantUnavailable(RuntimeError):
    pass


def configured() -> bool:
    return bool(os.getenv("GEMINI_API_KEY"))


def _guard_reply(reply: str, language: str) -> str:
    """Block dosage or actuation claims even if the remote model disobeys."""
    unsafe_dosage = re.search(
        r"\b\d+(?:\.\d+)?\s*(?:ml|millilit(?:er|re)|g|gram|kg|kilogram)\b",
        reply, flags=re.IGNORECASE,
    )
    unsafe_action = re.search(
        r"\b(?:i|citadel|system)\s+(?:have\s+)?(?:started|activated|turned on)\s+"
        r"(?:the\s+)?(?:pump|irrigation|relay)\b", reply, flags=re.IGNORECASE,
    )
    if not (unsafe_dosage or unsafe_action):
        return reply
    safe = {
        "Hindi": "मैं रासायनिक मात्रा या सिंचाई सक्रिय नहीं कर सकता। कृपया स्थानीय कृषि विशेषज्ञ से सलाह लें और Citadel में सिंचाई को अलग से मंजूरी दें।",
        "Haryanvi": "मैं दवाई की मात्रा या सिंचाई चालू ना कर सकूं। कृषि विशेषज्ञ तै सलाह लो अर Citadel में सिंचाई अलग तै मंजूर करो।",
        "Punjabi": "ਮੈਂ ਰਸਾਇਣਕ ਮਾਤਰਾ ਜਾਂ ਸਿੰਚਾਈ ਚਾਲੂ ਨਹੀਂ ਕਰ ਸਕਦਾ। ਸਥਾਨਕ ਖੇਤੀ ਮਾਹਿਰ ਦੀ ਸਲਾਹ ਲਵੋ ਅਤੇ Citadel ਵਿੱਚ ਸਿੰਚਾਈ ਨੂੰ ਵੱਖਰੇ ਤੌਰ ਤੇ ਮਨਜ਼ੂਰ ਕਰੋ।",
    }
    return safe.get(language,
        "I cannot provide chemical dosage or activate irrigation. Consult a qualified local agricultural expert and approve irrigation separately in Citadel.")


def _tokens(value: str) -> set[str]:
    return set(re.findall(r"\w+", value.lower(), flags=re.UNICODE))


MULTILINGUAL_QUERY_TERMS = {
    "soil": {"मिट्टी", "माटी", "नमी", "ਮਿੱਟੀ", "ਨਮੀ"},
    "heat": {"गर्मी", "गरमी", "तापमान", "ਗਰਮੀ", "ਤਾਪਮਾਨ"},
    "humidity": {"उमस", "हवा", "ਨਮੀ", "ਹਵਾ"},
    "rain": {"बारिश", "बरसात", "ਮੀਂਹ", "ਬਾਰਿਸ਼"},
    "water": {"पानी", "पाणी", "बाढ़", "ਪਾਣੀ", "ਹੜ੍ਹ"},
    "crop": {"फसल", "पत्ता", "बीमारी", "ਫਸਲ", "ਪੱਤਾ", "ਬਿਮਾਰੀ"},
    "pest": {"कीड़ा", "कीट", "ਕੀੜਾ", "ਕੀਟ"},
    "irrigation": {"सिंचाई", "ਸਿੰਚਾਈ"},
    "sensor": {"सेंसर", "ਸੈਂਸਰ"},
    "offline": {"इंटरनेट", "ऑफलाइन", "ਇੰਟਰਨੈੱਟ", "ਆਫਲਾਈਨ"},
}


def retrieve(question: str, limit: int = 3) -> list[Passage]:
    query = _tokens(question)
    normalized_question = question.lower()
    for english, aliases in MULTILINGUAL_QUERY_TERMS.items():
        if any(alias in normalized_question for alias in aliases):
            query.add(english)
    ranked = sorted(KNOWLEDGE,
        key=lambda item: len(query & _tokens(f"{item.title} {item.text}")), reverse=True)
    matched = [item for item in ranked
               if query & _tokens(f"{item.title} {item.text}")]
    return (matched or [KNOWLEDGE[-1]])[:limit]


def _farm_context(zone_id: str) -> str:
    report = build_report(zone_id, 168)
    lines = [
        f"zone={zone_id}",
        f"reading_count={report['summary']['readingCount']}",
        f"data_completeness_pct={report['summary']['dataCompletenessPct']}",
    ]
    for name, metric in report["metrics"].items():
        lines.append(f"{name}: latest={metric['latest']}, average={metric['average']}, "
                     f"minimum={metric['minimum']}, maximum={metric['maximum']}, "
                     f"unit={metric['unit']}, trend={metric['trend']}")
    lines.append(f"risk_counts={report['risks']}")
    lines.append(f"crop_scan_labels={report['cropHealth']['labelCounts']}")
    return "\n".join(lines)


def answer(question: str, zone_id: str, language: str) -> dict:
    key = os.getenv("GEMINI_API_KEY")
    if not key:
        raise AssistantUnavailable("Online farm assistant is not configured.")
    passages = retrieve(question)
    evidence = "\n\n".join(f"[{p.title}] {p.text}" for p in passages)
    system = """You are Citadel's farmer assistant. Answer only about the farmer's
crops, farm sensors, crop scans, irrigation, farm risks, and use of Citadel.
Use only the supplied Citadel guidance and farm context. If evidence is missing,
say so and recommend a qualified local agricultural expert. Never invent a
reading or diagnosis. Never give pesticide/chemical dosage. Never activate or
claim to activate irrigation. Be cautious, practical, and under 180 words.
Respond in the requested language."""
    prompt = (f"Question: {question}\nRequested language: {language}\n\n"
              f"Retrieved Citadel guidance:\n{evidence}\n\n"
              f"Current farm context:\n{_farm_context(zone_id)}")
    try:
        response = httpx.post(
            ENDPOINT.format(model=MODEL),
            headers={"x-goog-api-key": key, "Content-Type": "application/json"},
            json={
                "system_instruction": {"parts": [{"text": system}]},
                "contents": [{"role": "user", "parts": [{"text": prompt}]}],
                "generationConfig": {"temperature": 0.2, "maxOutputTokens": 350},
            }, timeout=20.0,
        )
        response.raise_for_status()
        payload = response.json()
        reply = payload["candidates"][0]["content"]["parts"][0]["text"].strip()
    except (httpx.HTTPError, KeyError, IndexError, ValueError) as error:
        raise AssistantUnavailable(f"Online assistant request failed: {error}") from error
    return {"answer": _guard_reply(reply, language), "language": language, "model": MODEL,
            "sources": [item.title for item in passages], "onlineOnly": True}
