# MyVault

A private, local-first personal productivity system built with Flutter.

Flutter: https://flutter.dev  
Dart: https://dart.dev

License: Mona-AJ  
Platform: Android | Windows

> Organize your accounts, tasks, schedules, projects, budgets, and personal values — all stored locally with AES encryption. No cloud. No tracking. Just you.

---

## Features

### Dashboard

Central hub for navigating all modules of the app in one place.

### Schedule

A structured weekly planning system to stay on top of your time.

- Add tasks to specific days with start time and duration
- Edit, delete, and mark tasks as completed

### Statistics

Visualize your productivity and study habits over time.

- Total tracked days and study hours
- Best performance day
- Activity trends from saved data

### Accounts

Store and manage account-related information securely and locally.

### Daily Tasks

Create, track, and complete your daily to-do list efficiently.

### Data Form

Structured input forms for saving and organizing personal data.

### Projects

Plan and manage your personal or professional projects.

- Track tech stack, start/end dates, and progress

### Values

Record and reflect on personal goals, habits, and principles.

### Weekly Budget

Log expenses and manage your weekly financial goals.

---

## Privacy First

| Feature    | Detail                         |
| ---------- | ------------------------------ |
| Storage    | 100% local — no cloud, no sync |
| Encryption | AES encryption on all data     |
| Tracking   | None                           |
| Internet   | Not required                   |

---

## Tech Stack

| Layer     | Technology       |
| --------- | ---------------- |
| Framework | Flutter          |
| Language  | Dart             |
| UI        | Material Design  |
| Storage   | Local JSON files |
| Security  | AES Encryption   |

---

## Getting Started

### Prerequisites

- Flutter SDK (includes Dart)
- Android Studio
- VS Code (optional)

```bash
flutter doctor
```

### Installation

```bash
git clone https://github.com/aj-aditya19/MyVault.git

cd MyVault

flutter pub get

flutter run
```

---

## Build Instructions

### Android APK

```bash
flutter build apk --release
```

Output:
build/app/outputs/flutter-apk/app-release.apk

### Windows Desktop

```bash
flutter config --enable-windows-desktop

flutter build windows
```

Output:
build/windows/x64/runner/Release/app.exe

---

## Project Structure

MyVault/
├── android/
├── ios/
├── lib/
├── windows/
├── assets/
├── pubspec.yaml
└── README.md

---

## Roadmap

- PIN lock / biometric authentication
- Dark mode UI
- Monthly and yearly scheduling views
- Advanced analytics in Statistics module
- AI-based productivity insights
- Optional cloud sync

---

## Platform Support

| Platform | Status         |
| -------- | -------------- |
| Android  | Supported      |
| Windows  | Supported      |
| iOS      | Not configured |
| Web      | Not configured |

---

## Author

Aditya Jaiswal  
GitHub: https://github.com/aj-aditya19

---

## License

Mona-AJ License

Free for learning and personal use. Commercial use requires permission.
