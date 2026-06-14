# AI Calorie Tracker (Offline-First Flutter App)

A local-first nutrition + fitness mobile app built with Flutter, SQLite, and on-device flows.

## Features Implemented

- No auth/login/signup (fully local profiles)
- Multiple local profiles with instant switching
- Profile setup:
  - Name, gender, age, weight, height
  - Goal + activity level
  - Exercise volume inputs
- Offline AI calorie/macro calculator:
  - Mifflin-St Jeor BMR
  - TDEE and goal-based calories
  - Daily macro targets (protein/carbs/fat)
- Food scanner flow:
  - Camera capture
  - Offline heuristic AI estimate
  - Manual correction before save
- Food diary:
  - Meal logging by category
  - Daily totals vs targets
- Anatomy explorer:
  - Front/back/side selector
  - Clickable muscle list and highlight state
- Exercise library by muscle (seeded chest exercises)
- AI workout generator:
  - Beginner/intermediate/advanced
  - Goal-based sets/reps/rest and weekly split
- Progress tracking:
  - Weight/calorie/protein/measurements/workout completion
  - Local photo support
  - Trend chart (weekly/monthly style trend visualization)
- Material 3 + dark mode

## Tech Stack

- Flutter (Material Design 3)
- SQLite via `sqflite`
- State management with `provider`
- Camera/Gallery via `image_picker`
- Charts via `fl_chart`

## Project Structure

- `lib/main.dart`
  - App shell and all feature screens
  - Local data models
  - SQLite schema + repository methods
  - Nutrition calculator + offline food estimator
  - Workout generator logic

## SQLite Schema

Tables:

- `profiles`
- `meal_entries`
- `progress_entries`

All data is stored locally on device in app documents storage.

## Run Locally

1. Install Flutter SDK (3.3+).
2. From repository root:

```bash
flutter pub get
flutter run
```

## Notes

- The food scanner currently uses an offline deterministic estimator placeholder to keep the app fully offline and functional.
- You can replace the estimator with TensorFlow Lite model inference without changing the screen flow.
- The anatomy screen includes an interactive placeholder canvas and muscle selection state ready for 3D model integration.
