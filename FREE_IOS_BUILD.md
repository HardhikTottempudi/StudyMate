# Free iOS Build Guide Using GitHub Actions

## Overview

You can build your iOS app **for FREE** using GitHub Actions, which provides free macOS runners for public repositories!

## How It Works

1. Push your code to GitHub (public repo = free)
2. GitHub Actions builds your iOS app on a Mac (free)
3. Download the built `.ipa` file
4. Install on your iPhone using tools like AltStore or TestFlight

## Step 1: Create GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Make it **public** (required for free macOS runners)
3. Push your code:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git remote add origin https://github.com/YOUR_USERNAME/studymate.git
   git push -u origin main
   ```

## Step 2: Set Up GitHub Actions

I've already created the workflow file: `.github/workflows/ios-build.yml`

You just need to:
1. Push your code to GitHub
2. The workflow will automatically run
3. Download the `.ipa` file from the Actions tab

## Step 3: Configure Firebase Secrets

Add these secrets to your GitHub repository (Settings → Secrets):

- `FIREBASE_IOS_APP_ID`: Your Firebase iOS app ID
- `GOOGLE_SERVICES_INFO`: Contents of `GoogleService-Info.plist` (base64 encoded)

## Step 4: Install on iPhone

### Option A: Using AltStore (Free, No Developer Account)
1. Install AltStore on your iPhone
2. Download the `.ipa` from GitHub Actions
3. Open with AltStore
4. Install on your iPhone

### Option B: Using TestFlight (Requires Apple Developer Account)
1. Upload `.ipa` to App Store Connect
2. Add to TestFlight
3. Install via TestFlight app

### Option C: Using Xcode (If you get Mac access later)
1. Download `.ipa`
2. Use Xcode to install on device

## Limitations

- **Public repos only** for free macOS runners
- **Build time**: ~10-15 minutes per build
- **2000 minutes/month** free (usually enough for development)
- **No code signing** in free builds (need Mac for that)

## Alternative: Use Android for Development

Since you're on Windows, you can:
1. **Develop and test on Android** (works perfectly on Windows)
2. **Build iOS later** when you have Mac access or use GitHub Actions
3. **Share codebase** - same Flutter code works for both!

## Cost Comparison

| Option | Cost | Setup Time |
|--------|------|------------|
| GitHub Actions (Public Repo) | **FREE** | 10 minutes |
| Cloud Mac Service | $20-200/month | 30 minutes |
| Buy a Mac | $500-2000+ | Immediate |
| Use Android (Windows) | **FREE** | 5 minutes |

## Recommendation

**For now**: Develop on **Android** (works great on Windows)
- Test all features
- Fix bugs
- Perfect the app

**Later**: Build iOS using:
- GitHub Actions (free)
- Friend's Mac (free)
- Or cloud service when ready to publish

## Next Steps

Would you like me to:
1. ✅ Set up Android development (works on Windows now)
2. ✅ Set up GitHub Actions workflow (for free iOS builds)
3. ✅ Help you test on Android first

Let me know what you prefer!
