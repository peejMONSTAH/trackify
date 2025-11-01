# Trackify - Expense Tracker App

## Project Overview

**App Title:** Trackify  
**Developer Name(s):** [Your Name Here]  
**Date:** [Submission Date]

## Description

Trackify is a comprehensive mobile expense tracking application that helps users manage their daily expenses efficiently. The app allows users to record, view, update, and delete expenses while organizing them by categories. With Firebase Authentication, users can securely register and login to access their personal expense data stored locally on their device.

## Key Features

- **User Authentication**: Secure registration and login using Firebase Authentication
- **Expense Management**: Full CRUD operations (Create, Read, Update, Delete) for expenses
- **Category Organization**: 8 predefined categories (Food, Transport, Shopping, Bills, Entertainment, Health, Education, Other)
- **Local Storage**: All expenses stored locally using SQFLite database
- **Total Tracking**: View total expenses at a glance
- **Modern UI**: Clean and intuitive Material Design 3 interface

## Technologies Used

- **Flutter SDK** (v3.32.8) - Cross-platform mobile development framework
- **Dart** (v3.8.1) - Programming language
- **Firebase Authentication** - User authentication service
- **SQFLite** - Local SQLite database for data persistence
- **Provider** - State management solution
- **Intl** - Internationalization and date formatting

## Screenshots

[Add screenshots of your app here]
1. Login Screen
2. Register Screen
3. Home Screen (Expense List)
4. Add Expense Screen
5. Edit Expense Screen

## Firebase Project Link

[Add your Firebase Console project link here]
Example: https://console.firebase.google.com/project/trackify-xxxxx

## Project Structure

```
trackify/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   └── expense.dart            # Expense data model
│   ├── screens/
│   │   ├── login_screen.dart        # Login UI
│   │   ├── register_screen.dart    # Registration UI
│   │   ├── home_screen.dart        # Main expense list screen
│   │   └── add_edit_expense_screen.dart # Add/Edit expense form
│   ├── services/
│   │   ├── auth_service.dart        # Firebase authentication
│   │   └── database_helper.dart     # SQFLite database operations
│   ├── providers/
│   │   └── expense_provider.dart    # State management
│   └── utils/
│       └── constants.dart           # App constants
├── android/                         # Android platform files
├── ios/                             # iOS platform files (optional)
└── README.md                        # Setup instructions
```

## CRUD Operations Implementation

### Create
- Users can add new expenses through the "Add Expense" screen
- All fields are validated before saving
- Expenses are immediately saved to SQFLite database

### Read
- All expenses are displayed on the home screen
- Expenses are sorted by date (newest first)
- Total expenses are calculated and displayed

### Update
- Users can edit any expense by tapping the edit icon
- All expense fields can be modified
- Changes are saved to the database immediately

### Delete
- Users can delete expenses by tapping the delete icon
- Confirmation dialog prevents accidental deletion
- Expenses are permanently removed from the database

## Setup & Installation

1. **Prerequisites**
   - Flutter SDK installed
   - Android Studio / VS Code
   - Firebase account

2. **Installation**
   ```bash
   cd trackify
   flutter pub get
   ```

3. **Firebase Setup**
   - Follow instructions in `FIREBASE_SETUP.md`
   - Run `flutterfire configure`
   - Update `main.dart` with Firebase options

4. **Run the App**
   ```bash
   flutter run
   ```

## Build APK for Submission

```bash
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-release.apk`

## Testing Checklist

- [x] User can register new account
- [x] User can login with registered credentials
- [x] User can logout
- [x] User can add new expenses
- [x] User can view all expenses
- [x] User can edit existing expenses
- [x] User can delete expenses
- [x] Expenses persist after app restart
- [x] Total expenses calculated correctly
- [x] Input validation works properly
- [x] Error handling implemented

## Future Enhancements (Optional)

- Cloud synchronization using Firestore
- Expense charts and analytics
- Export expenses to CSV/PDF
- Budget setting and alerts
- Multi-currency support
- Expense search and filters

## References

- Flutter Documentation: https://docs.flutter.dev/
- Firebase Documentation: https://firebase.google.com/docs
- SQFLite Package: https://pub.dev/packages/sqflite

---

**Note:** This project was developed as part of ITCC 116 - Application Development course requirements.

