import json
import os
import re
from typing import Any, Dict, Optional

import requests
from fastapi import FastAPI, Header, HTTPException
from pydantic import BaseModel

import firebase_admin
from firebase_admin import auth, credentials


class GenerateRequest(BaseModel):
    topic: str
    notes: Optional[str] = None


app = FastAPI(title="StudyMate AI Backend")


def _init_firebase() -> None:
    if firebase_admin._apps:
        return
    # Preferred: provide service account JSON directly via env var.
    service_account_json = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON")
    if service_account_json:
        try:
            parsed = json.loads(service_account_json)
            firebase_admin.initialize_app(credentials.Certificate(parsed))
            return
        except Exception:
            pass

    # Fallback: standard ADC file path.
    creds_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    if creds_path:
        firebase_admin.initialize_app(credentials.Certificate(creds_path))
        return

    # Last fallback for environments with implicit credentials.
    firebase_admin.initialize_app()


_init_firebase()


def _require_token(auth_header: Optional[str]) -> Dict[str, Any]:
    if not auth_header or not auth_header.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token")
    token = auth_header.split(" ", 1)[1].strip()
    try:
        return auth.verify_id_token(token)
    except Exception as exc:
        raise HTTPException(status_code=401, detail=f"Invalid token: {exc}") from exc


def _extract_json(text: str) -> Any:
    cleaned = text.strip()
    fenced = re.search(r"```(?:json)?\s*(\{.*\}|\[.*\])\s*```", cleaned, re.DOTALL)
    if fenced:
        cleaned = fenced.group(1).strip()
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        match = re.search(r"(\{.*\}|\[.*\])", cleaned, re.DOTALL)
        if not match:
            raise
        return json.loads(match.group(1))


def _gemini_generate(prompt: str) -> str:
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        raise HTTPException(status_code=500, detail="GEMINI_API_KEY is not set")

    preferred_model = os.getenv("GEMINI_MODEL", "gemini-2.5-flash")
    candidate_models = [
        preferred_model,
        "gemini-2.5-flash",
        "gemini-2.5-flash-lite",
        "gemini-1.5-flash-001",
    ]

    payload = {
        "contents": [
            {
                "parts": [
                    {
                        "text": prompt,
                    }
                ]
            }
        ],
        "generationConfig": {
            "responseMimeType": "application/json",
            "temperature": 0.2,
        },
    }
    last_error = None
    for model in candidate_models:
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/"
            f"{model}:generateContent?key={api_key}"
        )
        response = requests.post(url, json=payload, timeout=30)
        if response.status_code == 404:
            last_error = response.text
            continue
        if response.status_code >= 400:
            raise HTTPException(status_code=502, detail=response.text)

        data = response.json()
        try:
            return data["candidates"][0]["content"]["parts"][0]["text"]
        except Exception as exc:
            raise HTTPException(status_code=502, detail=f"Unexpected Gemini response: {data}") from exc

    raise HTTPException(
        status_code=502,
        detail=f"No supported Gemini model resolved. Last error: {last_error}",
    )


@app.get("/health")
def health() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/generateContent/flashcards")
def generate_flashcards(
    request: GenerateRequest,
    authorization: Optional[str] = Header(default=None),
) -> Dict[str, Any]:
    _require_token(authorization)

    if not request.topic.strip():
        raise HTTPException(status_code=400, detail="topic is required")

    prompt = f"""
You are an assistant that outputs strict JSON only.
Create flashcards for the topic below.
Return JSON using this schema exactly:
{{
  "cards": [
    {{
      "question": "string",
      "answer": "string"
    }}
  ]
}}
Generate 6 to 10 cards.
Topic: {request.topic}
Notes: {request.notes or ""}
"""
    raw_text = _gemini_generate(prompt)
    parsed = _extract_json(raw_text)

    cards = parsed.get("cards", []) if isinstance(parsed, dict) else []
    if not isinstance(cards, list) or not cards:
        raise HTTPException(status_code=502, detail="Invalid flashcards format from model")

    normalized = []
    for card in cards:
        question = str(card.get("question", "")).strip()
        answer = str(card.get("answer", "")).strip()
        if question and answer:
            normalized.append({"question": question, "answer": answer})

    if not normalized:
        raise HTTPException(status_code=502, detail="No valid flashcards returned")

    return {"cards": normalized}


@app.post("/generateContent/mindmap")
def generate_mindmap(
    request: GenerateRequest,
    authorization: Optional[str] = Header(default=None),
) -> Dict[str, Any]:
    _require_token(authorization)

    if not request.topic.strip():
        raise HTTPException(status_code=400, detail="topic is required")

    prompt = f"""
You are an assistant that outputs strict JSON only.
Create a hierarchical mindmap for the topic below.
Return JSON using this schema exactly:
{{
  "root": {{
    "id": "root",
    "text": "string",
    "children": [
      {{
        "id": "string",
        "text": "string",
        "children": []
      }}
    ]
  }}
}}
Use 2-4 main children and 1-3 nested children each.
Topic: {request.topic}
Notes: {request.notes or ""}
"""
    raw_text = _gemini_generate(prompt)
    parsed = _extract_json(raw_text)

    root = parsed.get("root") if isinstance(parsed, dict) else None
    if not isinstance(root, dict):
        raise HTTPException(status_code=502, detail="Invalid mindmap format from model")

    root.setdefault("id", "root")
    root.setdefault("text", request.topic)
    root.setdefault("children", [])
    return {"root": root}
