# AQIA Mobile App — Context File

## Overview

AQIA is a Flutter mobile application (also deployable to web) that helps users practice AI-powered mock interviews. It generates domain-specific questions, records spoken or typed answers, evaluates them in real time using OpenAI, and produces a detailed performance report at the end of each session.

- **App name**: `aqia` (package name in pubspec)
- **Version**: 1.0.0+1
- **Flutter SDK**: ^3.9.2
- **Dart SDK**: ^3.9.2
- **Entry point**: `lib/main.dart`

---

## Architecture

The app follows a simple layered architecture without a full state-management framework (Provider is installed but only used for `AuthProvider`). Most screens are stateful widgets that call services directly.

```
lib/
├── main.dart                    # App entry point — no Firebase init (currently bypassed)
├── config/
│   ├── api_config.dart          # Reads OpenAI key from env or keys.dart
│   ├── keys.dart                # Local secret file (gitignored) — set openAiApiKey here
│   └── keys.example.dart        # Template for keys.dart
├── models/                      # Plain Dart data classes
│   ├── user_model.dart
│   ├── interview_session.dart   # InterviewConfig + InterviewSession
│   ├── interview_feedback.dart  # Per-question scores (fluency, content, confidence, fillerWords)
│   ├── interview_report.dart    # Full session report + QaAnalysis
│   └── progress_data.dart
├── providers/
│   └── auth_provider.dart       # ChangeNotifier wrapping AuthService (not wired to main yet)
├── services/
│   ├── api_service.dart         # Legacy REST client (placeholder baseUrl, not actively used)
│   ├── auth_service.dart        # Firebase Auth — email/password + Google Sign-In
│   ├── firestore_service.dart   # Firestore CRUD for users, feedbacks, progress
│   ├── interview_service.dart   # Core interview logic — questions, evaluation, report (singleton)
│   ├── openai_service.dart      # OpenAI chat completions (gpt-4o-mini by default)
│   └── speech_service.dart      # speech_to_text + flutter_tts wrapper
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart    # Email/password + Google login
│   │   └── signup_screen.dart
│   └── home/
│       ├── dashboard_screen.dart        # Root shell with bottom nav (Home / Analytics / Profile)
│       ├── interview_setup_screen.dart  # Domain picker, question count, resume upload
│       ├── interview_screen.dart        # Active interview — Q&A loop, feedback per question
│       ├── interview_report_screen.dart # Full post-session report
│       ├── analytics_screen.dart        # Static placeholder charts (hardcoded data)
│       └── profile_screen.dart          # User info + settings (dark mode toggle, logout)
├── theme/
│   └── app_theme.dart           # All colors, ThemeData, reusable BoxDecoration helpers
└── widgets/
    ├── glass_card.dart          # Glassmorphism card wrapper
    ├── waveform_animation.dart  # Animated waveform bars (CustomPainter)
    ├── feedback_card.dart       # Score tile used in interview feedback
    ├── progress_card.dart       # Progress metric card
    ├── skill_progress_card.dart # Skill score card used on dashboard
    └── starry_background.dart   # Animated starry background widget
```

---

## Navigation Flow

```
main.dart
  └── DashboardScreen (home)
        ├── [tab 0] Home content
        │     └── → InterviewSetupScreen
        │               └── → InterviewScreen (session)
        │                         └── → InterviewReportScreen
        ├── [tab 1] AnalyticsScreen
        └── [tab 2] ProfileScreen

LoginScreen → DashboardScreen
LoginScreen → SignupScreen → (back to login)
```

> **Note**: `main.dart` currently boots directly into `DashboardScreen`, bypassing auth entirely. Firebase is not initialized in `main()`. `LoginScreen` and `AuthProvider` exist but are not wired into the app entry point.

---

## Key Services

### `InterviewService` (singleton)
The central service for the interview flow.

| Method | Description |
|---|---|
| `startInterview(config)` | Generates questions via OpenAI or falls back to built-in bank |
| `submitAnswer(question, answer)` | Evaluates a single answer; returns `InterviewFeedback` |
| `evaluateAnswerWithSuggestion(...)` | Same as above but also returns a suggested improved answer |
| `generateReport(...)` | Produces a full `InterviewReport` from all Q&A pairs |

- Falls back to built-in question banks and mock scoring when no OpenAI key is set.
- Supported domains (10): Software Engineering, Product Management, Data Science, Machine Learning, Frontend Development, Backend Development, Full Stack, DevOps, System Design, Behavioral.

### `OpenAIService`
- Model: `gpt-4o-mini` (configurable)
- Endpoint: `https://api.openai.com/v1/chat/completions`
- Three operations: `generateQuestions`, `evaluateAnswer`, `generateReport`
- All responses are expected as raw JSON (no markdown fences); the service strips fences if present.

### `AuthService`
- Firebase Auth: email/password sign-up/sign-in, Google Sign-In, sign-out.
- Returns `UserModel` from the current Firebase `User`.

### `FirestoreService`
- Collections: `users/{uid}`, `users/{uid}/feedbacks`, `users/{uid}/progress`
- Streams for real-time feedback and progress data.
- `getLast5Sessions` fetches the 5 most recent feedback documents.

### `SpeechService`
- Wraps `speech_to_text` (STT) and `flutter_tts` (TTS).
- `startListening` runs for up to 60 s with a 3 s pause timeout.
- **Note**: `InterviewScreen` currently simulates voice input with a `Future.delayed` stub instead of calling `SpeechService`.

---

## Data Models

### `InterviewConfig`
```dart
domain: String          // e.g. "Software Engineering"
numQuestions: int       // 1–20
resumePath: String?     // local file path (PDF)
resumeText: String?     // pasted/extracted resume text for AI context
```

### `InterviewFeedback`
```dart
fluency: double         // 0–100
content: double         // 0–100
confidence: double      // 0–100
fillerWords: int
overallFeedback: String
suggestions: List<String>
timestamp: DateTime
averageScore: double    // computed: (fluency + content + confidence) / 3
```

### `InterviewReport`
```dart
candidateName, overallScore, communicationScore, technicalScore,
problemSolvingScore, behavioralScore, wordsPerMinute, fillerWords,
speechRecommendation, executiveSummary,
keyStrengths: List<String>, areasForImprovement: List<String>,
detailedQa: List<QaAnalysis>
```

### `QaAnalysis`
```dart
questionNumber: int
question: String
userResponse: String
suggestedImprovement: String
```

---

## Configuration & Secrets

### OpenAI API Key
Two ways to supply the key (checked in order):

1. **Dart define at build/run time** (recommended for CI/deployment):
   ```bash
   flutter run --dart-define=OPENAI_API_KEY=sk-...
   ```
2. **`lib/config/keys.dart`** (local dev, gitignored):
   ```dart
   const String openAiApiKey = 'sk-proj-...';
   ```

`ApiConfig.hasOpenAiKey` is `false` when neither is set — the app runs in offline/mock mode.

### Firebase
Firebase is configured via `firebase_options.dart` (generated by FlutterFire CLI, not committed). The app requires:
- Firebase Auth (email/password + Google Sign-In)
- Cloud Firestore
- Firebase Messaging (dependency present, not actively used in screens)

> **Current state**: `main()` does not call `Firebase.initializeApp()`, so Firebase services will throw at runtime if invoked. This needs to be fixed before auth/Firestore features work.

---

## UI & Theme

- **Design language**: Glassmorphism on a deep black background (`#080808`)
- **Font**: Poppins (via `google_fonts`)
- **Brand gradient** (buttons): purple `#7C3AED` → blue `#3B82F6` → pink `#EC4899`
- **Key color constants** (all in `AppTheme`):
  - `blackBackground` = `#080808`
  - `purplePrimary` = `#7C3AED`
  - `gradientBlue` = `#3B82F6`
  - `whiteText` = `#FDFDFD`
  - `grayText` = `#A3A3A3`
- **Reusable decorations**: `AppTheme.glassDecoration()`, `AppTheme.buttonGradientDecoration()`, `AppTheme.gradientDecoration()`
- **Animations**: `flutter_animate` for entrance animations; `WaveformAnimation` (CustomPainter) for voice recording visual.

---

## Dependencies (pubspec.yaml)

| Package | Purpose |
|---|---|
| `firebase_core` ^3.6.0 | Firebase initialization |
| `firebase_auth` ^5.3.1 | Authentication |
| `cloud_firestore` ^5.4.4 | Database |
| `firebase_messaging` ^15.1.3 | Push notifications (not yet used in UI) |
| `google_sign_in` ^6.2.1 | Google OAuth |
| `http` ^1.2.2 | HTTP client (used by OpenAIService) |
| `dio` ^5.7.0 | Advanced HTTP (installed, not actively used) |
| `provider` ^6.1.2 | State management (AuthProvider only) |
| `fl_chart` ^0.69.0 | Charts (installed, not yet used in AnalyticsScreen) |
| `speech_to_text` ^7.0.0 | STT |
| `flutter_tts` ^4.1.0 | TTS |
| `lottie` ^3.1.2 | Lottie animations (installed, not yet used) |
| `flutter_animate` ^4.5.0 | Entrance/transition animations |
| `glassmorphism` ^3.0.0 | Glass effect (installed; app uses custom `GlassCard` instead) |
| `font_awesome_flutter` ^10.7.0 | FA icons (used in LoginScreen) |
| `shared_preferences` ^2.3.2 | Local storage (installed, not yet used) |
| `file_picker` ^8.1.6 | PDF resume picker |
| `intl` ^0.19.0 | Date formatting |
| `google_fonts` ^6.2.1 | Poppins font |

---

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run (debug)
flutter run

# Run with OpenAI key
flutter run --dart-define=OPENAI_API_KEY=sk-...

# Build web
flutter build web

# Build Android APK
flutter build apk --release

# Build Android App Bundle (Play Store)
flutter build appbundle --release

# Build iOS (macOS + Xcode required)
flutter build ipa

# Regenerate app icons from assets/aqia_app_icon.png
dart run flutter_launcher_icons
```

---

## Known Issues / TODOs

| Area | Issue |
|---|---|
| Firebase init | `Firebase.initializeApp()` missing from `main()` — auth and Firestore will fail at runtime |
| Auth wiring | App boots directly to `DashboardScreen`; `LoginScreen` and `AuthProvider` are not connected |
| Voice input | `InterviewScreen` uses a `Future.delayed` stub instead of `SpeechService` |
| Analytics | `AnalyticsScreen` uses hardcoded data; not connected to Firestore |
| Profile | `ProfileScreen` shows placeholder user data ("John Doe"); not connected to auth |
| `fl_chart` | Imported but not used in any screen yet |
| `shared_preferences` | Installed but unused |
| `lottie` | Installed but unused |
| `glassmorphism` package | Installed but the app uses the custom `GlassCard` widget instead |
| `ApiService` | `baseUrl` is a placeholder; this service is not called anywhere in the current codebase |
| Resume PDF parsing | File path is stored but PDF text is not extracted automatically; user must paste text manually |

---

## Assets

```
assets/
└── aqia_app_icon.png   # App icon source (1024×1024 recommended)
```

Icon generation config is in `pubspec.yaml` under `flutter_launcher_icons`. Background color `#0F0A1E`, theme color `#7C3AED`.
