# Android Setup on Windows - Quick Guide

## Why Android First?

- ✅ Works perfectly on Windows
- ✅ No Mac required
- ✅ Test on your Android phone (if you have one)
- ✅ Same codebase works for iOS later
- ✅ Free to develop and test

## Step 1: Enable Developer Options on Android Phone

1. Go to **Settings** → **About phone**
2. Tap **"Build number"** 7 times
3. Go back to **Settings** → **Developer options**
4. Enable **"USB debugging"**
5. Enable **"Install via USB"** (if available)

## Step 2: Install USB Drivers

1. Connect your Android phone to Windows
2. Windows should auto-install drivers
3. If not, install drivers from your phone manufacturer's website

## Step 3: Verify Phone Connection

```bash
flutter devices
```

You should see your Android phone listed.

## Step 4: Run on Your Phone

```bash
flutter run
```

Flutter will automatically detect your Android phone and install the app!

## Step 5: Set Up Firebase for Android

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Add **Android app** to your project
3. Package name: `com.example.studymate`
4. Download `google-services.json`
5. Place in: `android/app/google-services.json`

## Step 6: Configure Android Build Files

### Update `android/build.gradle`:
Add to `buildscript` → `dependencies`:
```gradle
classpath 'com.google.gms:google-services:4.4.0'
```

### Update `android/app/build.gradle`:
Add at the bottom:
```gradle
apply plugin: 'com.google.gms.google-services'
```

## Step 7: Run Again

```bash
flutter clean
flutter pub get
flutter run
```

## Testing Without a Phone

You can also use Android Emulator:

1. Open **Android Studio**
2. Tools → **Device Manager**
3. Create a virtual device
4. Run: `flutter run`

## Benefits of Android Development

- ✅ Test all features immediately
- ✅ Debug easily on Windows
- ✅ Same code works for iOS later
- ✅ Free to develop and test
- ✅ Can publish to Google Play Store

## When Ready for iOS

Once your app is working on Android:
- Use GitHub Actions (free) to build iOS
- Or use a Mac when available
- Same code, just different build process!

## Troubleshooting

**Phone not detected:**
- Install USB drivers
- Enable USB debugging
- Try different USB cable/port

**Build errors:**
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

**Firebase errors:**
- Verify `google-services.json` is in `android/app/`
- Check package name matches Firebase
