# Firebase Setup Guide for Trackify

## Step-by-Step Instructions

### 1. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" or "Create a project"
3. Enter project name: `trackify` (or your preferred name)
4. Follow the setup wizard (disable Google Analytics if you don't need it)
5. Click "Create project"

### 2. Add Android App to Firebase

1. In Firebase Console, click the Android icon (or "Add app")
2. Enter package name: `com.example.trackify`
   - You can find this in `android/app/build.gradle.kts` under `applicationId`
3. Enter app nickname: `Trackify Android` (optional)
4. Download `google-services.json`
5. Place the file in: `android/app/google-services.json`

### 3. Add iOS App to Firebase (Optional - if testing on iOS)

1. In Firebase Console, click the iOS icon
2. Enter bundle ID (found in Xcode project settings)
3. Download `GoogleService-Info.plist`
4. Add to `ios/Runner/GoogleService-Info.plist` in Xcode

### 4. Enable Authentication

1. In Firebase Console, go to **Authentication** > **Sign-in method**
2. Click on **Email/Password**
3. Enable it and click **Save**

### 5. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 6. Configure FlutterFire

Navigate to your project directory and run:

```bash
cd trackify
flutterfire configure
```

This will:
- Detect your Firebase projects
- Generate `lib/firebase_options.dart` automatically
- Configure Firebase for all platforms

### 7. Update main.dart

After running `flutterfire configure`, the `firebase_options.dart` file will be generated automatically. Update `lib/main.dart`:

Replace the Firebase initialization code with:

```dart
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
```

### 8. Verify Setup

1. Run the app: `flutter run`
2. Try registering a new account
3. Check Firebase Console > Authentication to see if the user appears

## Troubleshooting

### Error: "Firebase App named '[DEFAULT]' already exists"

This happens if Firebase is initialized twice. Make sure `Firebase.initializeApp()` is only called once in `main()`.

### Error: "No Firebase App '[DEFAULT]' has been created"

Make sure you've:
1. Run `flutterfire configure`
2. Added the import for `firebase_options.dart`
3. Passed `DefaultFirebaseOptions.currentPlatform` to `initializeApp()`

### Android Build Error

If you get errors about `google-services.json`:
1. Make sure the file is in `android/app/google-services.json`
2. Verify the package name matches in both Firebase Console and `build.gradle.kts`
3. Clean and rebuild: `flutter clean && flutter pub get && flutter run`

## Security Rules (Optional)

For production, set up Firebase Security Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Note: Trackify uses SQFLite for local storage, so Firestore rules are only needed if you add cloud sync features later.

