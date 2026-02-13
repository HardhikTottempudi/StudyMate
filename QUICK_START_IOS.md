# Quick Start: Running StudyMate on Your iPhone

## ⚠️ Important: You Need a Mac

iOS development requires a **Mac computer**. If you're on Windows, you'll need:
- Access to a Mac, OR
- A cloud Mac service

## Quick Setup Steps

### 1. On Your Mac: Install Xcode
```bash
# Open App Store, search "Xcode", install it
# Then install CocoaPods:
sudo gem install cocoapods
```

### 2. Set Up Firebase

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create/select your project
3. Add iOS app with Bundle ID: `com.example.studymate`
4. Download `GoogleService-Info.plist`
5. Place it in: `ios/Runner/GoogleService-Info.plist`

### 3. On Your Mac: Install Dependencies

```bash
# In your project directory
cd ios
pod install
cd ..
```

### 4. Configure Firebase (Recommended)

```bash
flutterfire configure
```

This will generate `lib/firebase_options.dart` automatically.

### 5. Update main.dart

The file should already have Firebase initialization. After running `flutterfire configure`, update it to:

```dart
import 'firebase_options.dart'; // Add this line

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Use this
  );
  runApp(const ProviderScope(child: StudyMateApp()));
}
```

### 6. Connect Your iPhone

1. Connect iPhone to Mac via USB
2. Unlock iPhone and trust the computer
3. Open Xcode: `ios/Runner.xcworkspace`
4. Select your iPhone from device dropdown
5. Sign in with your Apple ID in Xcode (Settings → Accounts)

### 7. Run on iPhone

```bash
flutter run -d <your-iphone-name>
```

Or click the Play button in Xcode.

## Bundle ID

Your app's bundle identifier is: **`com.example.studymate`**

Use this when:
- Setting up Firebase iOS app
- Configuring code signing in Xcode

## Troubleshooting

**"No devices found"**
- Unlock iPhone
- Trust computer on iPhone
- Check USB cable

**Code signing errors**
- Sign in to Xcode with Apple ID
- Select your team in Xcode → Runner → Signing & Capabilities

**Pod install errors**
```bash
cd ios
pod deintegrate
pod install
```

## Need Help?

See `IOS_SETUP.md` for detailed instructions.
