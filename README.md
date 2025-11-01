# Trackify - Expense Tracker App

A comprehensive expense tracking mobile application built with Flutter, featuring Firebase Authentication and SQFLite local database.

## Features

- 🔐 **Firebase Authentication** - Secure user registration and login
- 💾 **Local Database (SQFLite)** - Store expenses offline
- ✏️ **Full CRUD Operations** - Create, Read, Update, and Delete expenses
- 📊 **Category Management** - Organize expenses by category
- 💰 **Total Expenses Tracking** - View total expenses at a glance
- 🎨 **Modern UI/UX** - Clean and intuitive Material Design interface

## Technologies Used

- **Flutter SDK** - Cross-platform mobile development framework
- **Firebase Authentication** - User authentication service
- **SQFLite** - Local SQLite database for Android/iOS
- **Provider** - State management
- **Intl** - Date and number formatting

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.8.1 or higher)
- Dart SDK (3.8.1 or higher)
- Android Studio or VS Code with Flutter extensions
- Firebase account

### 2. Install Dependencies

```bash
cd trackify
flutter pub get
```

### 3. Firebase Configuration

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)

2. Enable Email/Password authentication in Firebase Console:
   - Go to Authentication > Sign-in method
   - Enable Email/Password provider

3. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```

4. Configure Firebase for your app:
   ```bash
   flutterfire configure
   ```
   This will generate the `firebase_options.dart` file automatically.

5. Update `lib/main.dart` to use the generated options:
   ```dart
   import 'firebase_options.dart';
   
   // In main() function:
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

### 4. Run the App

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── expense.dart         # Expense data model
├── screens/
│   ├── login_screen.dart    # Login screen
│   ├── register_screen.dart # Registration screen
│   ├── home_screen.dart     # Main expense list screen
│   └── add_edit_expense_screen.dart # Add/Edit expense form
├── services/
│   ├── auth_service.dart    # Firebase authentication service
│   └── database_helper.dart # SQFLite database helper
├── providers/
│   └── expense_provider.dart # State management for expenses
└── utils/
    └── constants.dart       # App constants (categories, icons, colors)
```

## CRUD Operations

### Create
- Tap the "+" button on the home screen
- Fill in expense details (title, amount, category, date)
- Save the expense

### Read
- View all expenses on the home screen
- Expenses are sorted by date (newest first)
- Total expenses displayed at the top

### Update
- Tap the edit icon on any expense card
- Modify the expense details
- Save changes

### Delete
- Tap the delete icon on any expense card
- Confirm deletion in the dialog

## Categories

The app includes 8 predefined categories:
- Food
- Transport
- Shopping
- Bills
- Entertainment
- Health
- Education
- Other

## Building APK

To build the APK for submission:

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

## Notes

- All expenses are stored locally on the device using SQFLite
- User authentication is handled by Firebase
- Each user's expenses are isolated by their Firebase user ID
- The app requires internet connection only for authentication
- Expenses persist between app restarts

## Developer

[Your Name Here]

## License

This project is created for educational purposes as part of ITCC 116 - Application Development course.
