# AQIA Mobile App — Team Setup Guide

This guide walks you through cloning and running the AQIA Flutter app on your local machine from scratch.

---

## Prerequisites

Before you start, make sure you have the following installed:

| Tool | Version | Download |
|---|---|---|
| Flutter SDK | 3.27.4 (stable) | [flutter.dev/get-started/install](https://docs.flutter.dev/get-started/install) |
| Android Studio | Latest | [developer.android.com/studio](https://developer.android.com/studio) |
| Git | Any | [git-scm.com](https://git-scm.com) |
| Java (JDK) | 11+ | Bundled with Android Studio |

> **macOS (Apple Silicon M1/M2/M3):** Download the `arm64` Flutter build.  
> **macOS (Intel):** Download the `x86_64` Flutter build.  
> **Windows/Linux:** Follow the platform-specific instructions on the Flutter site.

---

## Step 1 — Install Flutter

**macOS:**
```bash
# Download and unzip Flutter to your home folder
unzip ~/Downloads/flutter_macos_arm64_3.27.4-stable.zip -d ~/

# Add Flutter to your PATH permanently
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc
source ~/.zshrc

# Verify
flutter --version
```

**Windows (PowerShell):**
```powershell
# Extract the zip to C:\flutter
# Then add C:\flutter\bin to your System PATH via Environment Variables
flutter --version
```

---

## Step 2 — Install Android Studio

1. Download and install Android Studio from [developer.android.com/studio](https://developer.android.com/studio)
2. Open Android Studio → complete the setup wizard (it installs the Android SDK automatically)
3. Go to **More Actions → SDK Manager → SDK Tools tab**
4. Check **Android SDK Command-line Tools (latest)** → Apply → OK

**Tell Flutter where the SDK is:**
```bash
flutter config --android-sdk ~/Library/Android/sdk
```
> On Windows the SDK is usually at `C:\Users\YourName\AppData\Local\Android\Sdk`

**Accept Android licenses:**
```bash
flutter doctor --android-licenses
# Type 'y' and press Enter for each prompt
```

**Verify everything is green:**
```bash
flutter doctor
```
You should see ✓ for Flutter and ✓ for Android toolchain. Xcode/iOS warnings can be ignored if you're only building for Android.

---

## Step 3 — Install the Android system image (for emulator)

```bash
~/Library/Android/sdk/cmdline-tools/latest/bin/sdkmanager \
  "system-images;android-34;google_apis;arm64-v8a"
```
> On Windows replace the path with `%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat`

Accept the license when prompted.

---

## Step 4 — Clone the repository

```bash
git clone https://github.com/ExplorerSoul/aqia-app.git
cd aqia-app
```

---

## Step 5 — Install Flutter dependencies

```bash
flutter pub get
```

Expected output ends with `Got dependencies!`

---

## Step 6 — Run the app

### Option A — On a physical Android phone

1. On your phone: **Settings → About phone → tap Build number 7 times** to enable Developer Mode
2. Go to **Settings → Developer options → enable USB Debugging**
3. Connect your phone via USB and tap **Allow** on the USB debugging prompt
4. Verify Flutter sees it:
   ```bash
   flutter devices
   ```
5. Run:
   ```bash
   flutter run
   ```

### Option B — On the Android emulator

1. Open Android Studio → **Device Manager → Create Device**
2. Pick **Pixel 8** → select **API 34 (arm64-v8a)** → Finish
3. Press ▶ to start the emulator
4. Once booted, run:
   ```bash
   flutter run
   ```

### Option C — Mock mode (no backend needed, zero AI tokens)

Use this to test the full UI flow without consuming any API credits:
```bash
flutter run --dart-define=MOCK_MODE=true
```

---

## Step 7 — Test backend connectivity

Once the app is running, tap **"Test Backend Connection"** on the login screen.

It runs 6 checks against the live backend:
- Health check
- Register
- Login
- JWT validation
- Dashboard fetch
- Groq LLM proxy

All should show ✓ green. If any fail, the error message tells you exactly what's wrong.

---

## Project structure

```
aqia_app/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   └── app_config.dart          # API base URL, mock mode flag
│   ├── services/
│   │   ├── api_client.dart          # Central HTTP client (auth headers)
│   │   ├── auth_service.dart        # Login / register / logout
│   │   ├── token_service.dart       # JWT storage (SharedPreferences)
│   │   ├── ai_service.dart          # /api/chat proxy (Groq LLM)
│   │   ├── mock_ai_service.dart     # Zero-token mock for testing
│   │   ├── speech_service.dart      # STT (Whisper) + TTS (Google Neural2)
│   │   ├── dashboard_service.dart   # /api/dashboard + /api/interviews
│   │   └── prompt_builder.dart      # Interview system prompt builder
│   ├── screens/
│   │   ├── auth/                    # Login, Signup
│   │   ├── home/                    # Dashboard, Interview, Report, Analytics, Profile
│   │   └── test/                    # Backend connectivity test screen
│   ├── models/                      # Data classes
│   ├── widgets/                     # Reusable UI components
│   └── theme/                       # AppTheme (light, matches website)
├── android/                         # Android build config
├── ios/                             # iOS build config
├── assets/                          # App icon, user photos
├── test/                            # Widget tests
├── pubspec.yaml                     # Dependencies
├── deploy.md                        # Play Store deployment guide
└── SETUP.md                         # This file
```

---

## Environment

The app connects to the live backend by default — no configuration needed.

| Variable | Default | How to override |
|---|---|---|
| `API_BASE_URL` | `https://aqia-backend.onrender.com` | `flutter run --dart-define=API_BASE_URL=http://localhost:8000` |
| `MOCK_MODE` | `false` | `flutter run --dart-define=MOCK_MODE=true` |

To run against a local backend:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```
> `10.0.2.2` is the Android emulator's alias for `localhost` on your Mac/PC.  
> For a physical phone on the same WiFi, use your machine's local IP (e.g. `192.168.1.x`).

---

## Running tests

```bash
flutter test
```

Tests cover: login form validation, signup password mismatch, report screen layout, question bank, backend test screen rendering.

---

## Common issues

| Problem | Fix |
|---|---|
| `flutter: command not found` | Add Flutter to PATH: `echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.zshrc && source ~/.zshrc` |
| `Android SDK not found` | Run `flutter config --android-sdk ~/Library/Android/sdk` |
| `minSdkVersion` error | Already set to 23 in `build.gradle.kts` — run `flutter clean && flutter run` |
| `No devices found` | Enable USB debugging on phone, or start the emulator first |
| `Resolving dependencies failed` | Run `flutter pub get` again; check internet connection |
| App shows login but can't connect | Backend on Render may be sleeping — wait 30–60 sec and retry |
| Emulator mic doesn't work | Use **Text input** mode in the interview screen, or run with `--dart-define=MOCK_MODE=true` |

---

## Backend

The backend is a FastAPI server deployed on Render:

- **API**: `https://aqia-backend.onrender.com`
- **Docs**: `https://aqia-backend.onrender.com/api/docs`
- **Health**: `https://aqia-backend.onrender.com/api/health`

> The backend may take 30–60 seconds to wake up if it hasn't been used recently (Render free tier spins down on inactivity).

---

## Need help?

Contact the project owner or open an issue on [github.com/ExplorerSoul/aqia-app](https://github.com/ExplorerSoul/aqia-app).
