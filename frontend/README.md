# Flutter Frontend
In this folder are all the [Flutter](https://docs.flutter.dev/) related files.
This folder is essentially the app and what the user sees. 
It has a dependency to the backend which ensures that there is data consistency.
You will be doing most of your work in this folder.

## Getting Started
Before you can run the app, you will need to add the Firebase options file to this project.
To do this, follow these steps:
1. Complete the [backend tutorial](../backend/README.md) to create a Firebase project which satisfies the requirements
2. Watch this [tutorial to setup Firebase for Flutter](https://youtu.be/Wa0rdbb53I8?list=PL4cUxeGkcC9j--TKIdkb3ISfRbJeJYQwC)
Once you have completed this appropriately, you can start to work with the project.

### Firebase configuration (already done in this repository)
The app is connected to the Firebase project `backend-news-symmetry` (Android only).
`lib/firebase_options.dart`, `android/app/google-services.json` and `firebase.json` were generated with:
```
flutterfire configure --project=backend-news-symmetry --platforms=android --android-package-name=com.example.news_app_clean_architecture --out=lib/firebase_options.dart
```
Firebase is initialized in `lib/injection_container.dart` (the composition root), so no presentation or domain code imports Firebase.

### Running against the real project or the local emulators
The project pins Flutter 3.27.4 with [FVM](https://fvm.app/) (`.fvmrc`).
```
fvm flutter run                                             # real Firebase project
fvm flutter run --dart-define=USE_FIREBASE_EMULATORS=true   # local Firebase Emulator Suite
```
In emulator mode, start the emulators and seed them first (see the [backend README](../backend/README.md)).
The Android emulator reaches your machine at `10.0.2.2`, which is the default. On a physical
device, forward the ports with `adb reverse tcp:8080 tcp:8080 && adb reverse tcp:9199 tcp:9199`
and add `--dart-define=FIREBASE_EMULATOR_HOST=127.0.0.1`.

### Generate files for routing, di etc.:
`flutter pub run build_runner build --delete-conflicting-outputs`
### Generate the icons:
`flutter pub run flutter_launcher_icons`
### Install the Project Dependencies (in pubsec.yaml)
`flutter pub get`

### How can I best understand this project?
In order to best understand this project and its underlying intricacies, we recommend that you watch this tutorial: [Flutter Clean Architecture Tutorial](https://www.youtube.com/watch?v=7V_P6dovixg).
This tutorial **literally builds this project from the ground up** so we really recommend you watch it before developing.

Furthermore, we will now leave the index of this project with all the documentation that must be read before contributing to the frontend.

# Index
1. [Contribution Guidelines](./docs/CONTRIBUTION_GUIDELINES.md)
2. [Architecture Violations](./docs/ARCHITECTURE_VIOLATIONS.md)
3. [Code Quality Violations](./docs/CODING_GUIDELINES.md)
4. [Our App Architecture](./docs/APP_ARCHITECTURE.md)
