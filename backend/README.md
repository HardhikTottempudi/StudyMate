# StudyMate AI Backend (Safe Key Handling)

This backend keeps `GEMINI_API_KEY` server-side and verifies Firebase ID tokens from the app.

## Endpoints

- `POST /generateContent/flashcards`
- `POST /generateContent/mindmap`
- `GET /health`

## Request Format

Headers:

- `Authorization: Bearer <firebase_id_token>`
- `Content-Type: application/json`

Body:

```json
{
  "topic": "Photosynthesis",
  "notes": "optional"
}
```

## Local Run

1. Create a venv and install deps:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\activate
pip install -r requirements.txt
```

2. Set env vars:

```powershell
$env:GEMINI_API_KEY="YOUR_KEY"
```

3. Run:

```powershell
uvicorn main:app --host 0.0.0.0 --port 8080
```

For Firebase token verification locally, provide Application Default Credentials:

```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\path\to\service-account.json"
```

## Render Deploy (Free Plan)

1. Push repo to GitHub.
2. In Render, create a new Web Service from repo.
3. Render auto-detects `render.yaml` in project root.
4. Set environment variables in Render:
   - `GEMINI_API_KEY=...`
   - `GEMINI_MODEL=gemini-1.5-flash`
   - `FIREBASE_SERVICE_ACCOUNT_JSON=<entire service account json on one line>`
5. Deploy and copy service URL.

## Cloud Run Deploy

```powershell
gcloud run deploy studymate-ai `
  --source .\backend `
  --region us-central1 `
  --allow-unauthenticated `
  --set-env-vars GEMINI_API_KEY=YOUR_KEY,GEMINI_MODEL=gemini-1.5-flash
```

## Flutter Wiring

Run Flutter with backend URL:

```powershell
flutter run --dart-define=AI_BACKEND_BASE_URL=https://YOUR_CLOUD_RUN_URL
```
