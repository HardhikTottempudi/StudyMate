# StudyMate – MVP Requirements Document
Version 0.1 • January 2026

## 1. Purpose
StudyMate is a mobile app that helps learners stay consistent and study smarter through: (1) a study timer and analytics, (2) focus aids like white-noise audio and motivational quotes, and (3) AI-assisted study content such as flashcards and mindmaps.

## 2. MVP Goals
- Enable users to sign up / log in securely (Firebase Authentication).
- Let users run a study timer and automatically save study sessions.
- Show a dashboard with today's study time and simple weekly analytics.
- Provide a white-noise player that continues playing while navigating the app.
- Generate and save AI flashcards and AI mindmaps from a topic / notes.

## 3. Target Platforms & Tech
- **Client**: Flutter (iOS + Android)
- **Backend**: Firebase (Auth + Firestore + Storage as needed)
- **AI**: Gemini or equivalent via a secure backend proxy (Cloud Functions recommended).

## 4. What Exists in Your Current React Native Project (from the uploaded ZIP)
Your current project is an Expo + TypeScript app using Expo Router. It already includes:
- Firebase Authentication setup with React Native persistence (AsyncStorage).
- Login and Signup screens under `app/(auth)/`.
- Tabbed navigation under `app/(tabs)/` including screens for dashboard (index), flashcards, mindmaps, and study-session.
- Study data persistence utilities using AsyncStorage (`services/studyDataService.ts`).
- Flashcards generation that calls the Gemini API directly from the client (currently with a hardcoded API key).
- Additional screens/features like detection/drowsiness/app blocking that can be considered out-of-scope for the MVP if you want to keep it lean.

This MVP document below assumes you are moving to Flutter, while keeping the same product scope.

## 5. Functional Requirements

### 5.1 Authentication (Firebase Auth)

### 5.2 Dashboard

### 5.3 Study Timer

### 5.4 White Noise Player

### 5.5 AI Flashcards

### 5.6 AI Mindmap

## 6. Data Model (Firestore Suggested)
Suggested collections and documents (per user):
- `users/{uid}` – basic profile + settings
- `users/{uid}/studySessions/{sessionId}` – timer sessions (startTime, endTime, durationSeconds, createdAt)
- `users/{uid}/flashcardSets/{setId}` – title, sourceText (optional), cards[], createdAt
- `users/{uid}/mindmaps/{mapId}` – title, sourceText (optional), nodes[] or nested tree, createdAt

**Notes:**
- Keep durations in seconds for easy aggregation.
- Use server timestamps for createdAt when possible.

## 7. Security & Privacy Requirements
**Firebase Security Rules (minimum):**
- Users can only read/write their own subcollections.
- Deny all access when `request.auth == null`.

**AI key management:**
- Your current React Native flashcards screen calls the Gemini API directly from the client and includes an API key. For the Flutter MVP, do NOT ship API keys in the app binary. Use a backend proxy (Firebase Cloud Functions) that accepts authenticated requests and calls the AI provider server-side.

## 8. Non-Functional Requirements
- **Performance**: Dashboard loads within 2 seconds on a mid-range phone.
- **Reliability**: If offline, user can still use timer and see cached data; sync when online (optional but recommended).
- **Usability**: Core actions reachable within 1–2 taps from Dashboard.
- **Observability (optional)**: Firebase Crashlytics and Analytics for crashes and funnel tracking.

## 9. Flutter Migration Notes (React Native → Flutter)
**Suggested Flutter folder structure:**
- `lib/main.dart` (bootstrap, Firebase init, router)
- `lib/features/auth/` (login, signup, auth controller)
- `lib/features/dashboard/` (dashboard screen, widgets, charts)
- `lib/features/timer/` (timer screen, state management, models)
- `lib/features/ai_flashcards/` (generator, viewer, saved sets)
- `lib/features/ai_mindmap/` (generator, tree renderer, saved maps)
- `lib/services/` (firestore repository, ai client, audio service)
- `lib/shared/` (theme, reusable widgets)

- **State management** (pick one): Riverpod or Bloc are common choices. Keep it simple for MVP.
- **Route mapping idea**: Your Expo Router tabs map well to Flutter's bottom navigation (Dashboard, Timer, Flashcards, Mindmaps, Settings).

## 10. Build Plan & Milestones

## 11. MVP Release Checklist
- [ ] User can sign up, log in, log out.
- [ ] Timer sessions save and appear in dashboard totals.
- [ ] Dashboard shows today total + last 7 days summary.
- [ ] White noise plays reliably and continues during navigation.
- [ ] AI flashcards generate via backend proxy and can be saved/reopened.
- [ ] AI mindmap generates and can be saved/reopened.
- [ ] No API keys stored in client code.
- [ ] Firestore rules prevent cross-user data access.
