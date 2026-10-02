# 🏋️ GymLog

**Lift. Log. PR.** An offline-first workout tracker: log sets × reps × weight, get automatic personal-record detection, and watch your estimated 1RM and volume climb on hand-drawn charts. One local SQLite file — no account, no cloud, no API keys.

![build](https://img.shields.io/badge/build-passing-brightgreen)
![flutter](https://img.shields.io/badge/flutter-3.x-blue)
![platform](https://img.shields.io/badge/platform-android%20%7C%20ios%20%7C%20desktop-lightgrey)
![license](https://img.shields.io/badge/license-MIT-green)

![GymLog banner](docs/hero.png)

## Why GymLog?

Most workout apps want a subscription and your data on their servers. GymLog is the opposite: a fast set logger, a real PR engine (Epley estimated 1RM + heaviest-lift tracking), and progress charts — all running against a single on-device SQLite database. Airplane mode is a feature, not a bug.

## Features

- **Exercise library** — 24 bundled exercises grouped by muscle group, plus your own custom exercises (name, muscle group, equipment).
- **Workout sessions** — start a workout, log sets with quick reps/weight steppers, delete mistakes, finish when done.
- **Automatic PR detection** — every logged set is checked against your history; new heaviest lifts and best estimated 1RMs get celebrated and stored in a per-exercise PR history.
- **Progress charts** — estimated-1RM trend per exercise and volume-per-day bars, drawn with custom `CustomPainter`s (no chart package, zero network).
- **History** — every session with its sets, total volume, and timestamps; PR viewer per exercise.
- **Local-first storage** — `sqflite` on device behind a repository interface; the in-memory implementation powers tests and previews with identical behavior.

## Tech stack

| Layer | Choice |
|---|---|
| UI | Flutter + Material 3, bottom-navigation shell |
| Storage | `sqflite` (real app) behind a `WorkoutRepository` interface; `InMemoryWorkoutRepository` for tests |
| PR engine | Pure-Dart `PrCalculator` — Epley 1RM + PR detection, no I/O |
| Charts | Hand-rolled `CustomPainter` line + bar charts over aggregated `DailyPoint` series |
| Tests | `flutter test` — 27 tests: PR math, repository behavior, stats aggregation, widget flows |

## Quickstart

```bash
flutter pub get
flutter run
```

On first launch the bundled exercise library is seeded into the local database automatically.

## Testing

```bash
flutter test        # 27 tests, all offline (sqflite impl is UI-wired; tests use the in-memory repo)
flutter analyze     # clean
```

## Project structure

```
lib/
  main.dart                        # entry point, wires the sqflite repository
  models/                          # Exercise, WorkoutSet, WorkoutSession, PersonalRecord
  data/exercise_library.dart       # bundled offline exercise library
  services/
    workout_repository.dart        # storage contract
    sqflite_workout_repository.dart# on-device SQLite implementation
    in_memory_workout_repository.dart # test/demo double, identical behavior
    pr_calculator.dart             # Epley 1RM + automatic PR detection
    workout_stats.dart             # volume-per-day / best-e1rm-per-day aggregation
  ui/                              # Material 3 tabs: Log, Exercises, Progress, History
test/
  pr_calculator_test.dart          # Epley math + PR detection rules
  in_memory_repository_test.dart   # CRUD, ordering, volume math, PR storage
  workout_stats_test.dart          # aggregation edge cases
  widget_test.dart                 # tab navigation, start/log-set flow
```

## Offline-first guarantee

GymLog makes zero network calls at runtime. Exercises, sessions, sets, and PRs live in one local SQLite file. No API keys, no secrets, no analytics.
