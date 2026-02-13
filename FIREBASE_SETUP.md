# Firebase Setup Guide for StudyMate

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `studymate` (or your preferred name)
4. **Disable** Google Analytics (optional, for MVP)
5. Click **"Create project"**
6. Wait for project creation to complete

## Step 2: Add Android App to Firebase

1. In Firebase Console, click the **Android icon** (or "Add app")
2. Enter package name: `com.studymate.app`
   - This must match your Android app's package name
3. Enter app nickname: `StudyMate Android` (optional)
4. **Leave SHA-1 blank for now** (we'll add it later if needed)
5. Click **"Register app"**
6. Download `google-services.json`
7. **IMPORTANT**: Place the file in: `android/app/google-services.json`

## Step 3: Add iOS App to Firebase (if you have a Mac)

1. Click the **iOS icon** in Firebase Console
2. Enter bundle ID: `com.studymate.app`
3. Enter app nickname: `StudyMate iOS` (optional)
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Place it in: `ios/Runner/GoogleService-Info.plist`

## Step 4: Enable Firebase Services

### Enable Authentication
1. In Firebase Console, go to **Authentication**
2. Click **"Get started"**
3. Go to **Sign-in method** tab
4. Enable **Email/Password**
5. Click **Save**

### Enable Firestore Database
1. Go to **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in test mode"** (for MVP)
4. Select a location (choose closest to you)
5. Click **"Enable"**

### Set Firestore Security Rules
1. Go to **Firestore Database** → **Rules** tab
2. Copy the rules from `firestore.rules` file in this project
3. Paste and click **"Publish"**

## Step 5: Configure Flutter App with FlutterFire CLI

After completing steps 1-4, run this command in your project directory:

```bash
flutterfire configure
```

This will:
- Detect your Firebase project
- Generate `lib/firebase_options.dart`
- Configure both Android and iOS automatically

**OR** if you prefer manual setup, see the next section.

## Step 6: Update Android Configuration

### Update `android/build.gradle`
Add this to the `buildscript` dependencies:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### Update `android/app/build.gradle`
Add at the bottom of the file:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 7: Update main.dart

After FlutterFire configuration, update `lib/main.dart`:

```dart
import 'firebase_options.dart'; // Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use this
  );
  runApp(const ProviderScope(child: StudyMateApp()));
}
```

## Running on Your Phone

### For Android Phone:
1. Enable **Developer options** on your phone:
   - Go to Settings → About phone
   - Tap "Build number" 7 times
2. Enable **USB debugging**:
   - Settings → Developer options → USB debugging
3. Connect phone via USB
4. Run: `flutter devices` (should show your phone)
5. Run: `flutter run` (will install and run on your phone)

### For iOS Phone (Mac only):
1. Connect iPhone via USB
2. Trust the computer on your phone
3. Run: `flutter run -d ios`

## Troubleshooting

### Android Issues:
- **Device not detected**: Install USB drivers for your phone
- **Build errors**: Run `flutter clean` then `flutter pub get`
- **Firebase errors**: Verify `google-services.json` is in correct location

### iOS Issues:
- **Code signing**: You need an Apple Developer account (free for testing)
- **Build errors**: Run `cd ios && pod install`

## Next Steps After Setup

1. ✅ Firebase configured
2. ✅ Authentication enabled
3. ✅ Firestore database created
4. ✅ Security rules deployed
5. ⏳ Test app on phone
6. ⏳ Set up Cloud Functions (for AI features - optional)
