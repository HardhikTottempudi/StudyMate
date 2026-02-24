# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Technology Stack
StudyMate is a React Native mobile application built with:
- **Expo SDK 53** - Cross-platform development framework
- **TypeScript** - Type-safe JavaScript
- **Expo Router** - File-based routing system using `app/` directory
- **Firebase** - Authentication and backend services
- **React Native Reanimated** - Smooth animations and gestures
- **Expo Vector Icons** - Icon system

## Project Structure

### Core Architecture
- `app/` - File-based routing structure (Expo Router)
  - `_layout.tsx` - Root layout with AuthProvider and navigation setup
  - `(tabs)/` - Tab-based navigation group with custom tab bar
  - `+not-found.tsx` - 404 page
- `src/` - Core application logic
  - `auth-context.tsx` - Firebase authentication context provider
  - `firebaseConfig.ts` - Firebase configuration and initialization
- `components/` - Reusable UI components
  - `MyTabBar.tsx` - Custom animated tab bar implementation
  - `TabBarButton.tsx` - Individual tab button component
  - Themed components (`ThemedText.tsx`, `ThemedView.tsx`)
- `hooks/` - Custom React hooks for color scheme and theming
- `constants/` - App-wide constants including colors and icons

### Authentication Flow
The app uses Firebase Authentication with React Context:
- `AuthProvider` wraps the entire app in `_layout.tsx`
- Authentication state persisted with AsyncStorage for React Native
- Login/signup screens located in `app/(tabs)/` directory

### Navigation Structure
- Stack navigation at root level
- Tab navigation for main app screens
- Custom animated tab bar with spring animations
- File-based routing with typed routes enabled

## Common Development Commands

### Development Server
```bash
npx expo start                 # Start development server
npx expo start --android       # Start with Android emulator
npx expo start --ios          # Start with iOS simulator  
npx expo start --web          # Start web version
```

### Package Management
```bash
npm install                    # Install dependencies
npm run reset-project         # Reset to blank project (removes starter code)
```

### Code Quality
```bash
npm run lint                   # Run ESLint with Expo config
```

### Platform-Specific Testing
- Use Expo Go app for quick testing on physical devices
- Android Studio emulator for Android testing
- Xcode simulator for iOS testing
- Web browser for web version testing

## Firebase Configuration
Firebase is configured for:
- Authentication with email/password
- AsyncStorage persistence for React Native
- Configuration located in `src/firebaseConfig.ts`

**Note:** Firebase API keys are currently exposed in the codebase and should be moved to environment variables for production.

## Development Considerations

### TypeScript Configuration
- Strict mode enabled
- Path aliases configured (`@/*` maps to root directory)
- Expo TypeScript base configuration extended

### Custom Components
- Custom tab bar with React Native Reanimated animations
- Themed components that respond to system color scheme
- Hand-drawn style buttons with custom fonts (Handlee)

### Routing
- File-based routing with Expo Router
- Typed routes enabled for better TypeScript support
- Tab navigation with custom tab bar implementation
- Stack navigation for modal/overlay screens

### Animations
- React Native Reanimated v3 for smooth animations
- Spring animations for tab bar interactions
- Gesture handling with react-native-gesture-handler
