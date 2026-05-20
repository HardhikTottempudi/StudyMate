# StudyMate

A cross-platform mobile app (Flutter) that helps learners stay consistent and study smarter. It combines a study timer with analytics, AI-generated flashcards and mindmaps, a white noise player, and a social study-streaks system where you send daily "study moments" to friends.

---

## Features

### Core Study Tools
- **Study Timer** — Start/stop a session timer; sessions are automatically saved to Firestore.
- **Dashboard & Analytics** — See today's total study time and a 7-day weekly summary chart.
- **White Noise Player** — Background audio that keeps playing while you navigate the app.

### AI-Powered Content (via Gemini)
- **AI Flashcards** — Enter a topic and optional notes; the backend generates 6–10 Q&A flashcard pairs.
- **AI Mindmap** — Enter a topic; the backend returns a hierarchical mindmap tree you can browse.
- All AI calls go through a secure FastAPI backend — no API keys in the app binary.

### Study Streaks (Social Feature)
- **Snap-style streaks** — Take a photo of your study session and send it to friends as a "study moment."
- **Daily consistency** — Sending one snap per day keeps your streak alive with a friend.
- **Inbox** — Receive and view incoming study snaps from friends.
- **History** — Tap a friend's streak card to see your full snap history with them.

### Authentication
- Firebase Email/Password sign-up and sign-in.
- Auth state persists across app restarts; all Firestore data is scoped per user.

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile client | Flutter (iOS + Android) |
| State management | Riverpod |
| Auth + Database | Firebase Auth + Cloud Firestore |
| AI backend | FastAPI (Python) + Google Gemini API |
| Backend hosting | Docker / Render (see `render.yaml`) |
| Charts | fl_chart |
| Audio | audioplayers |

---

## Project Structure

```
StudyMate/
├── lib/                          # Flutter app
│   ├── main.dart                 # Entry point, Firebase init, auth router
│   ├── features/
│   │   ├── auth/                 # Sign-up / sign-in screens + providers
│   │   ├── dashboard/            # Dashboard, weekly chart, main navigation
│   │   ├── timer/                # Study timer screen + Riverpod state
│   │   ├── ai_flashcards/        # Flashcard generator + viewer screens
│   │   ├── ai_mindmap/           # Mindmap generator + viewer screens
│   │   └── study_streaks/        # Social streaks feature
│   │       ├── models/           # FriendStreak, StudySnap data models
│   │       ├── screens/          # StudyStreaksPage, CameraPage, InboxPage, SnapViewPage
│   │       ├── services/         # StudyStreaksService (Firestore + image logic)
│   │       └── widgets/          # StreakCardWidget
│   ├── services/
│   │   ├── ai_service.dart       # HTTP calls to the FastAPI backend
│   │   ├── firestore_service.dart# Study session CRUD
│   │   └── audio_service.dart    # White noise playback
│   └── shared/
│       ├── models/               # Shared data models
│       └── theme/                # App-wide theme (AppTheme)
│
├── backend/                      # FastAPI AI backend (Python)
│   ├── main.py                   # /generateContent/flashcards + /mindmap endpoints
│   ├── requirements.txt
│   └── Dockerfile
│
├── android/                      # Android-specific config
├── ios/                          # iOS-specific config
├── assets/                       # Images, audio, etc.
├── pubspec.yaml                  # Flutter dependencies
└── render.yaml                   # Render.com deploy config for backend
```

---

## Setup

### 1. Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Python 3.10+ (for the backend)
- A Firebase project with Auth (Email/Password) and Firestore enabled
- A Google Gemini API key

---

### 2. Firebase Setup

1. Create a project at [Firebase Console](https://console.firebase.google.com/).
2. Add Android and iOS apps to the project.
3. Download and place the config files:
   - Android: `google-services.json` → `android/app/`
   - iOS: `GoogleService-Info.plist` → `ios/Runner/`
4. Enable **Email/Password** under Authentication → Sign-in methods.
5. Create a **Firestore** database and apply the security rules below.

**Firestore Security Rules:**
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;

      match /studySessions/{sessionId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /flashcardSets/{setId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /mindmaps/{mapId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /streaks/{friendId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      match /snaps/{snapId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

---

### 3. Run the Flutter App

```bash
flutter pub get
flutter run
```

Point `lib/services/ai_service.dart` at your running backend URL:
```dart
static const String _backendBaseUrl = 'https://your-backend-url.com';
```

---

### 4. Run the FastAPI Backend

```bash
cd backend
pip install -r requirements.txt
```

Set environment variables:
```bash
export GEMINI_API_KEY=your_gemini_key
export FIREBASE_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'
# or
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
```

Start the server:
```bash
uvicorn main:app --host 0.0.0.0 --port 8000
```

Or with Docker:
```bash
cd backend
docker build -t studymate-backend .
docker run -p 8000:8000 \
  -e GEMINI_API_KEY=your_key \
  -e FIREBASE_SERVICE_ACCOUNT_JSON='...' \
  studymate-backend
```

**API Endpoints:**

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Health check |
| POST | `/generateContent/flashcards` | Generate flashcards for a topic |
| POST | `/generateContent/mindmap` | Generate a mindmap for a topic |

All AI endpoints require a Firebase `Authorization: Bearer <id_token>` header.

---

### 5. White Noise Audio

Add an audio file to `assets/audio/white_noise.mp3` and register it in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/audio/
```

---

## Firestore Data Model

```
users/{uid}
├── studySessions/{sessionId}     startTime, endTime, durationSeconds, createdAt
├── flashcardSets/{setId}         title, notes, cards[], createdAt
├── mindmaps/{mapId}              title, notes, root{} tree, createdAt
├── streaks/{friendId}            friendName, currentStreak, lastSnapAt
└── snaps/{snapId}                friendId, friendName, imagePath, caption, emoji, createdAt
```

---

## Next Steps

- [ ] Set up Firebase Cloud Storage for storing snap images server-side
- [ ] Add white noise audio asset
- [ ] Test camera and snap flow on physical devices
- [ ] Add offline support (cached timer data syncs on reconnect)
- [ ] Implement Firebase Crashlytics and Analytics
- [ ] Add unit and widget tests
- [ ] Expand AI features (quiz generation, study summaries)
