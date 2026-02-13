# StudyMate - Flutter MVP

A mobile app that helps learners stay consistent and study smarter through study timers, analytics, focus aids, and AI-assisted study content.

## Features

- ✅ Firebase Authentication (Sign up / Sign in)
- ✅ Study Timer with automatic session saving
- ✅ Dashboard with today's study time and weekly analytics
- ✅ White Noise Player (structure ready, needs audio assets)
- ✅ AI Flashcards generation and viewing
- ✅ AI Mindmap generation and viewing
- ✅ Firestore data persistence
- ✅ Secure backend proxy structure for AI API calls

## Setup Instructions

### 1. Install Flutter

Make sure you have Flutter installed. If not, follow the [Flutter installation guide](https://flutter.dev/docs/get-started/install).

### 2. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download configuration files:
   - For Android: `google-services.json` → place in `android/app/`
   - For iOS: `GoogleService-Info.plist` → place in `ios/Runner/`
4. Enable Firebase Authentication (Email/Password)
5. Create Firestore database
6. Set up Firestore Security Rules (see below)

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Configure Firebase

Update `lib/services/ai_service.dart` with your Cloud Functions URL:

```dart
static const String _cloudFunctionUrl =
    'https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/generateContent';
```

### 5. Firestore Security Rules

Add these rules to your Firestore database:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
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
    }
  }
}
```

### 6. Firebase Cloud Functions (Optional for MVP)

For production, set up Cloud Functions to proxy AI API calls. The app includes mock data for development.

Example Cloud Function structure:
- `generateContent/flashcards` - Generates flashcards via Gemini API
- `generateContent/mindmap` - Generates mindmaps via Gemini API

### 7. White Noise Audio

Add white noise audio file to `assets/audio/white_noise.mp3` and update `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/audio/
```

### 8. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── features/
│   ├── auth/                          # Authentication
│   │   ├── providers/
│   │   └── screens/
│   ├── dashboard/                     # Dashboard with analytics
│   │   └── screens/
│   ├── timer/                         # Study timer
│   │   ├── providers/
│   │   └── screens/
│   ├── ai_flashcards/                 # AI flashcards
│   │   └── screens/
│   └── ai_mindmap/                    # AI mindmaps
│       └── screens/
├── services/                          # Business logic
│   ├── firestore_service.dart
│   ├── ai_service.dart
│   └── audio_service.dart
└── shared/                            # Shared components
    ├── models/
    └── theme/
```

## State Management

This app uses **Riverpod** for state management, which provides:
- Type-safe dependency injection
- Reactive state updates
- Easy testing

## Technologies Used

- **Flutter** - Cross-platform mobile framework
- **Firebase Auth** - Authentication
- **Cloud Firestore** - Database
- **Riverpod** - State management
- **fl_chart** - Charts for analytics
- **audioplayers** - Audio playback
- **http** - API calls

## MVP Checklist

- [x] User can sign up, log in, log out
- [x] Timer sessions save and appear in dashboard totals
- [x] Dashboard shows today total + last 7 days summary
- [x] White noise player structure (needs audio assets)
- [x] AI flashcards generate via backend proxy structure
- [x] AI mindmap generates via backend proxy structure
- [x] No API keys stored in client code
- [x] Firestore rules structure provided

## Next Steps

1. Set up Firebase Cloud Functions for AI generation
2. Add white noise audio assets
3. Test on physical devices
4. Add error handling and offline support
5. Implement Firebase Crashlytics and Analytics
6. Add unit and widget tests

## License

This project is part of the StudyMate MVP.
