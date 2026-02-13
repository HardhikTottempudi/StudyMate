# Android Emulator Setup Guide

## Quick Setup Steps

### Step 1: Open Android Studio

1. Open **Android Studio** (you can find it in Start Menu)
2. If it's your first time, let it complete the setup wizard

### Step 2: Create an Android Virtual Device (AVD)

1. In Android Studio, click **"More Actions"** → **"Virtual Device Manager"**
   - OR go to: **Tools** → **Device Manager**
2. Click **"+ Create Device"**
3. Select a device:
   - **Recommended**: Pixel 5 or Pixel 6 (good performance)
   - Or choose any phone you like
4. Click **"Next"**
5. Select a system image:
   - **Recommended**: Latest **API 34** (Android 14) or **API 33** (Android 13)
   - If you see "Download" next to it, click it to download
   - Wait for download to complete
6. Click **"Next"**
7. Review settings and click **"Finish"**

### Step 3: Start the Emulator

1. In Device Manager, click the **▶️ Play button** next to your virtual device
2. Wait for emulator to boot (first time takes 2-3 minutes)
3. You'll see an Android phone screen on your computer!

### Step 4: Run Your App

Once the emulator is running, in your project directory:

```bash
flutter devices
```

You should see your emulator listed. Then:

```bash
flutter run
```

Flutter will automatically install and run your app on the emulator!

## Alternative: Using Command Line

You can also create an emulator from command line:

```bash
# List available system images
flutter emulators

# Create emulator (if needed)
# Use Android Studio's AVD Manager for easier setup
```

## Performance Tips

- **Enable Hardware Acceleration**: 
  - In Android Studio → AVD Manager → Edit device
  - Check "Graphics: Hardware - GLES 2.0"
  
- **Allocate More RAM**:
  - Edit device → Advanced Settings
  - Increase RAM to 2048 MB or more (if you have enough)

- **Use x86_64 Images**: 
  - Faster than ARM images on Windows
  - Choose x86_64 system images when creating AVD

## Troubleshooting

### Emulator is Slow
- Enable hardware acceleration in BIOS (Intel VT-x or AMD-V)
- Allocate more RAM to emulator
- Use x86_64 system images

### Emulator Won't Start
- Check if virtualization is enabled in BIOS
- Try a different system image
- Restart Android Studio

### "No devices found"
```bash
flutter doctor
flutter devices
```
Make sure emulator is running before running `flutter run`

### Build Errors
```bash
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter run
```

## Quick Commands

```bash
# List all devices (including emulators)
flutter devices

# Run on specific device
flutter run -d <device-id>

# Hot reload (while app is running)
# Press 'r' in terminal

# Hot restart
# Press 'R' in terminal
```

## Next Steps

1. ✅ Create Android virtual device
2. ✅ Start emulator
3. ✅ Run: `flutter run`
4. ✅ Test your app!

Your app will run in the emulator just like on a real phone!
