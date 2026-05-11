# AQIA — AI Mock Interview Assistant

A Flutter mobile app that helps you practice interviews with AI-powered questions, real-time voice input, and detailed performance reports.

## Features

- JWT authentication (register / login)
- AI-driven interview conversations via Groq Llama-3.3-70b
- Voice input transcribed by Whisper
- AI questions spoken aloud via Google Neural2 TTS
- PDF resume upload — AI tailors questions to your background
- Per-session performance report (scores, strengths, improvements, Q&A analysis)
- Dashboard with progress chart and session history
- 9 interview domains: Software Engineering, Data Science, Product Management, UI/UX Design, Cybersecurity, Cloud Computing, DevOps, Machine Learning, AI Research

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI + Groq (Llama-3.3-70b + Whisper) + Google TTS
- **Auth**: JWT (no Firebase)

## Setup

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run (development)

```bash
flutter run --dart-define=API_BASE_URL=https://your-backend-url.com
```

### 3. Build release APK

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://your-backend-url.com
```

### 4. Build for Play Store (AAB)

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://your-backend-url.com
```

## Android Permissions

- `INTERNET` — API calls
- `RECORD_AUDIO` — voice input
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_AUDIO` — PDF resume picker

## Environment

| Variable | Description |
|---|---|
| `API_BASE_URL` | Backend base URL (e.g. `https://aqia-backend.onrender.com`) |

No API keys are stored in the app — all AI calls are proxied through the backend.
