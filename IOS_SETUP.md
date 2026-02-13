# iOS Setup Guide for StudyMate

## Prerequisites

⚠️ **IMPORTANT**: Building iOS apps requires a **Mac computer** with:
- macOS installed
- Xcode (from App Store)
- CocoaPods installed
- Apple Developer account (free for testing on your own device)

If you're on Windows, you have these options:
1. Use a Mac computer
2. Use a cloud Mac service (MacStadium, MacinCloud, etc.)
3. Use GitHub Actions with macOS runners
4. Build on a friend's Mac

## Step 1: Install Xcode (on Mac)

1. Open **App Store** on your Mac
2. Search for **"Xcode"**
3. Click **"Get"** or **"Install"** (it's free, but large ~10GB+)
4. Wait for installation to complete
5. Open Xcode and accept the license agreement
6. Install additional components when prompted

## Step 2: Install CocoaPods (on Mac)

Open **Terminal** on your Mac and run:

```bash
sudo gem install cocoapods
```

Enter your Mac password when prompted.

## Step 3: Set Up Firebase for iOS

### 3.1 Create Firebase Project (if not done)
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create or select your project
3. Click the **iOS icon** to add iOS app
4. Enter **Bundle ID**: `com.example.studymate`
   - This must match your iOS app's bundle identifier
5. Enter app nickname: `StudyMate iOS`
6. Click **"Register app"**
7. Download `GoogleService-Info.plist`

### 3.2 Add GoogleService-Info.plist to Project
1. Open your project in **Xcode**: `ios/Runner.xcworkspace`
2. Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
3. Make sure **"Copy items if needed"** is checked
4. Make sure **"Runner"** target is selected
5. Click **"Finish"**

### 3.3 Enable Firebase Services
- **Authentication**: Enable Email/Password in Firebase Console
- **Firestore**: Create database in test mode

## Step 4: Install iOS Dependencies

On your Mac, in the project directory, run:

```bash
cd ios
pod install
cd ..
```

This installs all iOS dependencies including Firebase.

## Step 5: Configure FlutterFire (Optional but Recommended)

On your Mac, run:

```bash
flutterfire configure
```

This will:
- Detect your Firebase project
- Generate `lib/firebase_options.dart`
- Configure iOS automatically

## Step 6: Update main.dart

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

## Step 7: Configure Code Signing (for Physical Device)

### Option A: Free Apple Developer Account (Recommended for Testing)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** in the left sidebar
3. Go to **"Signing & Capabilities"** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** (your Apple ID)
6. Xcode will create a free provisioning profile

### Option B: Paid Apple Developer Account ($99/year)
- Required for App Store distribution
- Not needed for testing on your own device

## Step 8: Connect Your iPhone

1. Connect your iPhone to your Mac via USB
2. Unlock your iPhone
3. Trust the computer when prompted on iPhone
4. In Xcode, select your iPhone from the device dropdown (top toolbar)

## Step 9: Run on Your iPhone

### Method 1: Using Flutter Command
```bash
flutter run -d <your-iphone-name>
```

### Method 2: Using Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select your iPhone from device dropdown
3. Click the **Play** button (▶️) or press `Cmd + R`

## Troubleshooting

### "No devices found"
- Make sure iPhone is unlocked
- Trust the computer on iPhone
- Check USB cable connection
- Run `flutter devices` to see connected devices

### Code Signing Errors
- Make sure you're signed in to Xcode with your Apple ID
- Go to Xcode → Settings → Accounts
- Add your Apple ID if not already added
- Select your team in Signing & Capabilities

### Pod Install Errors
```bash
cd ios
pod deintegrate
pod install
cd ..
```

### Build Errors
```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### Firebase Not Working
- Verify `GoogleService-Info.plist` is in `ios/Runner/` folder
- Check that it's added to the Xcode project (blue icon, not red)
- Verify bundle ID matches Firebase console

## Running on Simulator (for Testing)

You can also test on iOS Simulator without a physical device:

```bash
# List available simulators
flutter devices

# Run on simulator
flutter run -d "iPhone 15 Pro"
```

## Next Steps

1. ✅ iOS project structure created
2. ⏳ Set up Firebase (on Mac)
3. ⏳ Install CocoaPods dependencies
4. ⏳ Configure code signing
5. ⏳ Run on your iPhone

## Important Notes

- **You need a Mac** to build and run iOS apps
- Free Apple Developer account works for testing on your own devices
- Paid account ($99/year) needed for App Store distribution
- First build may take 10-15 minutes (downloading dependencies)
