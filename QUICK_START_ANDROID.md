# Quick Start: Run StudyMate on Android Emulator

## ✅ Good News!

You already have Android emulators set up! Here's how to use them:

## Step 1: Launch Emulator

I've just launched the **Pixel 6 Pro** emulator for you. Wait 30-60 seconds for it to boot up.

If you need to launch it manually later:
```bash
flutter emulators --launch Pixel_6_Pro_API_36
```

Or use the other one:
```bash
flutter emulators --launch Medium_Phone_API_36
```

## Step 2: Check Devices

Once emulator is running, check if Flutter sees it:

```bash
flutter devices
```

You should see your emulator listed.

## Step 3: Run Your App

```bash
flutter run
```

Flutter will:
1. Build your app
2. Install it on the emulator
3. Launch it automatically!

## Step 4: Test Your App

- The app will open in the emulator
- You can interact with it like a real phone
- Use your mouse to tap, swipe, etc.

## Hot Reload (While App is Running)

- Press **`r`** in terminal = Hot reload (fast refresh)
- Press **`R`** in terminal = Hot restart (full restart)
- Press **`q`** = Quit

## Set Up Firebase (Required)

Before the app works fully, you need Firebase:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a project
3. Add **Android app** with package: `com.example.studymate`
4. Download `google-services.json`
5. Place in: `android/app/google-services.json`

Then update build files (see `ANDROID_SETUP_WINDOWS.md`)

## Your Available Emulators

- ✅ **Pixel 6 Pro API 36** (Currently launching)
- ✅ **Medium Phone API 36**

## Troubleshooting

**Emulator not showing up:**
- Wait 1-2 minutes for it to fully boot
- Check if it's running in Android Studio

**"No devices found":**
```bash
flutter devices
```
Make sure emulator window is open and booted

**Build errors:**
```bash
flutter clean
flutter pub get
flutter run
```

## Next Steps

1. ✅ Emulator launching...
2. ⏳ Wait for it to boot
3. ⏳ Run `flutter run`
4. ⏳ Set up Firebase
5. ⏳ Test your app!

Enjoy testing your StudyMate app! 🎉
