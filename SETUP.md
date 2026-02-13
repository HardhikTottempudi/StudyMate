# StudyMate Flutter - Setup Guide

## Quick Start

### 1. Prerequisites
- Flutter SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase account

### 2. Install Flutter Dependencies
```bash
flutter pub get
```

### 3. Firebase Configuration

#### Option A: Using FlutterFire CLI (Recommended)
```bash
# Install FlutterFire CLI
flutter pub global activate flutterfire_cli

# Configure Firebase for your project
flutterfire configure
```

This will:
- Generate `firebase_options.dart` automatically
- Configure both Android and iOS
- Set up all necessary Firebase services

#### Option B: Manual Configuration

**For Android:**
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/google-services.json`
3. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
4. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

**For iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/GoogleService-Info.plist`
3. Open `ios/Runner.xcworkspace` in Xcode
4. Ensure the file is added to the Runner target

### 4. Update Firebase Initialization

After configuring Firebase, update `lib/main.dart`:

```dart
import 'firebase_options.dart'; // Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use this
  );
  runApp(const ProviderScope(child: StudyMateApp()));
}
```

### 5. Enable Firebase Services

In Firebase Console:
1. **Authentication**: Enable Email/Password sign-in method
2. **Firestore**: Create database in test mode (then update rules)
3. **Storage** (optional): For future file uploads

### 6. Deploy Firestore Security Rules

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init firestore

# Deploy rules
firebase deploy --only firestore:rules
```

Or copy the rules from `firestore.rules` to Firebase Console manually.

### 7. Configure AI Service (Optional for MVP)

The app includes mock data for development. For production:

1. Set up Firebase Cloud Functions
2. Create functions to proxy Gemini API calls
3. Update `lib/services/ai_service.dart` with your Cloud Function URL

Example Cloud Function structure:
```javascript
exports.generateContent = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }
  
  const { topic, notes, type } = data;
  
  // Call Gemini API server-side
  // Return flashcards or mindmap data
});
```

### 8. Add White Noise Audio (Optional)

1. Create `assets/audio/` directory
2. Add `white_noise.mp3` file
3. Update `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/audio/
```

### 9. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For a specific device
flutter devices
flutter run -d <device-id>
```

## Troubleshooting

### Firebase Not Initialized
- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
- Check that Firebase is properly configured in your project
- Verify Firebase dependencies in `pubspec.yaml`

### Build Errors
- Run `flutter clean` and `flutter pub get`
- For Android: Check `android/build.gradle` and `android/app/build.gradle`
- For iOS: Run `pod install` in `ios/` directory

### Authentication Issues
- Verify Email/Password is enabled in Firebase Console
- Check Firestore security rules allow authenticated users

### AI Generation Not Working
- The app uses mock data if Cloud Functions are not set up
- Check `lib/services/ai_service.dart` for the Cloud Function URL
- Verify your Cloud Function is deployed and accessible

## Project Structure

```
studymate/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── features/                    # Feature modules
│   │   ├── auth/                    # Authentication
│   │   ├── dashboard/               # Dashboard & analytics
│   │   ├── timer/                   # Study timer
│   │   ├── ai_flashcards/           # AI flashcards
│   │   └── ai_mindmap/              # AI mindmaps
│   ├── services/                    # Business logic
│   └── shared/                      # Shared components
├── android/                         # Android configuration
├── ios/                             # iOS configuration
├── pubspec.yaml                     # Dependencies
└── firestore.rules                  # Firestore security rules
```

## Next Steps

1. ✅ Set up Firebase
2. ✅ Configure authentication
3. ✅ Deploy Firestore rules
4. ⏳ Set up Cloud Functions (for AI features)
5. ⏳ Add white noise audio assets
6. ⏳ Test on physical devices
7. ⏳ Add error handling and offline support

## Support

For issues or questions, refer to:
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Riverpod Documentation](https://riverpod.dev)
