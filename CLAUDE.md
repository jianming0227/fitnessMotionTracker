# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install / restore dependencies
flutter pub get

# Regenerate Hive adapters (run after modifying any @HiveType model)
flutter pub run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Lint
flutter analyze

# Format
dart format lib/ test/

# Tests (only a smoke test exists currently)
flutter test
```

## Architecture

This is a Flutter fitness app (**FitForm — AI Fitness Coach**) built around real-time squat form detection via Google ML Kit pose estimation.

### Layer structure

```
lib/
├── core/           # Shared constants and pure utilities (no state)
│   ├── constants/  # AppColors, AppTextStyles, AppTheme (dark Material 3 theme)
│   └── utils/      # angle_utils.dart (atan2 joint angles), date_formatters.dart
├── services/       # Data layer — no UI knowledge
│   ├── hive_service.dart       # Local-first storage (Hive NoSQL)
│   ├── supabase_service.dart   # Remote backend (auth + sync)
│   └── models/                 # Hive @HiveType models + generated adapters
└── features/       # Vertical slices: one folder per screen
    ├── dashboard/
    ├── profile/
    └── motion_tracking/        # Camera + ML Kit + squat logic
        ├── views/
        ├── controllers/        # squat_controller.dart — ChangeNotifier state machine
        └── widgets/            # pose_painter.dart — CustomPainter skeleton overlay
```

### State management

`provider` package with `MultiProvider` at the root. `SquatController` is a `ChangeNotifier` that holds the squat phase state machine and rep counter; it is provided to `PoseDetectorView`.

### Data flow

1. **Local-first**: `HiveService` stores `WorkoutSession` objects on-device immediately when a session finishes.
2. **Optional sync**: `SupabaseService` can push sessions to `workout_sessions` table and pull a profile from the `profiles` table. Supabase credentials are loaded from `.env` via `flutter_dotenv`.
3. **Dashboard aggregates** (today's reps, duration, recent sessions) are all read from Hive, not Supabase.

### Pose detection pipeline

`PoseDetectorView` feeds camera frames → `google_mlkit_pose_detection` (accurate streaming model) → `SquatController.analyse()` → `PosePainter` renders the skeleton.

`SquatController` implements a 5-state machine: `STANDING → DESCENDING → BOTTOM → ASCENDING → STANDING`. A rep is counted on the `ASCENDING → STANDING` transition. Key thresholds: standing knee ≥ 160°, squat depth ≤ 95°, form warning < 55°. Detection prefers the left leg and falls back to right.

### Code generation

`WorkoutSession` is a Hive model with `@HiveType` / `@HiveField` annotations. The generated adapter lives in `workout_session.g.dart`. Re-run build_runner whenever the model changes.

## Environment

Supabase credentials live in `.env` at the project root and are loaded before any Supabase or Hive init in `main.dart`:

```
SUPABASE_URL=...
SUPABASE_ANON_KEY=...
```

## Known issues

- `supabase_service.dart` line 7 is missing a semicolon after `_supabaseAnonKey` — the file will not compile as-is.
- The dashboard "Today's Plan" card is hardcoded to a single "Squat Mastery" 3×15 plan; there is no dynamic plan model yet.
