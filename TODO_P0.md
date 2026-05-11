# AQIA Mobile App — P0 Todo List
## Goal: Make the app work exactly like the website, using the shared backend

---

## How the web app works (reference)

| Layer | Web | Mobile (current state) |
|---|---|---|
| Auth | JWT via `/api/register` + `/api/login`, stored in `localStorage` | Firebase Auth (not initialized, not wired) |
| AI questions | Groq Llama-3.3-70b via `/api/chat` (server-side key) | OpenAI `gpt-4o-mini` called directly from client |
| STT | Whisper via `/api/transcribe` (server-side key) | `speech_to_text` package (stub, not wired) |
| TTS | Google Neural2 → Coqui → Browser fallback via `/google-tts` + `/tts` | `flutter_tts` (not called in interview screen) |
| Interview save | `POST /api/interviews` | Not implemented |
| Dashboard data | `GET /api/dashboard` | Hardcoded static values |
| Progress chart | Real data from backend | Hardcoded |
| Session history | `GET /api/interviews` | Not implemented |
| PDF resume parse | `pdfjs-dist` in browser | File path stored, text not extracted |
| Daily limit | Enforced server-side (1/day) | Not enforced |

---

## P0 Tasks

### 1. Replace Firebase auth with backend JWT auth

**Why:** The backend uses its own JWT system (`/api/register`, `/api/login`). Firebase is not initialized and will crash. All API calls require a `Bearer <token>` header.

**What to do:**
- Delete `firebase_core`, `firebase_auth`, `google_sign_in` from `pubspec.yaml`
- Delete `lib/services/auth_service.dart` and `lib/providers/auth_provider.dart`
- Create `lib/services/auth_service.dart` that calls:
  - `POST /api/register` → `{ email, password, name }` → returns `{ access_token }`
  - `POST /api/login` → `{ email, password }` → returns `{ access_token }`
- Store the JWT in `shared_preferences` (key: `token`)
- Create `lib/services/token_service.dart` — a singleton that reads/writes the token and provides an `authHeader` getter (`{ 'Authorization': 'Bearer $token' }`)
- Wire `LoginScreen` and `SignupScreen` to the new `AuthService`
- In `main.dart`: on startup, check for a stored token → if valid (not expired), go to `DashboardScreen`; otherwise go to `LoginScreen`
- Remove all Firebase imports from `main.dart`

**Files to change:** `main.dart`, `pubspec.yaml`, `lib/services/auth_service.dart` (rewrite), `lib/screens/auth/login_screen.dart`, `lib/screens/auth/signup_screen.dart`

---

### 2. Create a central `ApiClient` that talks to the backend

**Why:** Every service needs the base URL and the auth header. Currently `api_service.dart` has a placeholder URL and is unused.

**What to do:**
- Create `lib/services/api_client.dart` — a thin wrapper around `http` (or `dio`) with:
  - `baseUrl` read from `ApiConfig` (env var `API_BASE_URL`, fallback to `http://127.0.0.1:8000`)
  - `get(path)`, `post(path, body)`, `postMultipart(path, file)` — all automatically attach the Bearer token from `TokenService`
  - Throws `AuthException` on 401 (triggers logout + redirect to login)
- Replace the placeholder `api_service.dart` with this

**Files to change:** `lib/services/api_client.dart` (new), `lib/config/api_config.dart`

---

### 3. Replace OpenAI direct calls with backend `/api/chat` proxy

**Why:** The web app never calls OpenAI directly. All AI calls go through `/api/chat` which proxies to Groq Llama-3.3-70b server-side. The mobile app currently calls OpenAI directly from the client, exposing the key.

**What to do:**
- Rewrite `lib/services/openai_service.dart` → rename to `lib/services/ai_service.dart`
- `generateQuestions(domain, count, resumeContext)` → `POST /api/chat` with the same system prompt logic from `promptBuilder.js` (port to Dart)
- `evaluateAnswer(question, answer)` → `POST /api/chat`
- `generateReport(...)` → `POST /api/chat` with `response_format: { type: "json_object" }`
- Request body shape: `{ model: "llama-3.3-70b-versatile", messages: [...], temperature: 0.6, max_tokens: 1024 }`
- Remove `openai_service.dart`, `lib/config/keys.dart`, `lib/config/keys.example.dart`, `lib/config/api_config.dart` (OpenAI key logic)
- Update `InterviewService` to use the new `AiService`

**Files to change:** `lib/services/openai_service.dart` → `lib/services/ai_service.dart`, `lib/services/interview_service.dart`, `lib/config/api_config.dart`

---

### 4. Wire real speech-to-text via backend `/api/transcribe` (Whisper)

**Why:** The web app records audio and sends it to `/api/transcribe` (Whisper large-v3 via Groq). The mobile `InterviewScreen` currently uses a `Future.delayed` stub.

**What to do:**
- In `lib/services/speech_service.dart`, implement `stopListeningAndTranscribe()`:
  1. Stop `speech_to_text` recording
  2. Get the recorded audio bytes (use `record` package or `flutter_sound` for raw audio capture — `speech_to_text` alone doesn't give you the audio blob)
  3. `POST /api/transcribe` as `multipart/form-data` with `file=recording.wav` and `model=whisper-large-v3`
  4. Return the `text` field from the response
- Add `record: ^5.x` (or `flutter_sound`) to `pubspec.yaml` for raw audio capture
- In `InterviewScreen`, replace the `Future.delayed` stub with a real call to `SpeechService.stopListeningAndTranscribe()`
- Keep the live `speech_to_text` transcript as the interim display (same hybrid approach as the web)

**Files to change:** `lib/services/speech_service.dart`, `lib/screens/home/interview_screen.dart`, `pubspec.yaml`

---

### 5. Wire TTS to backend `/google-tts` endpoint

**Why:** The web app uses Google Neural2 TTS via the backend, falling back to browser TTS. The mobile app has `flutter_tts` but it's not called in `InterviewScreen` — the AI question is never spoken aloud.

**What to do:**
- In `lib/services/speech_service.dart`, add `speak(text)`:
  1. Try `POST /google-tts` with `{ text, voice: "en-US-Neural2-F" }` → play the returned MP3 using `audioplayers` or `just_audio`
  2. On failure, fall back to `flutter_tts`
- Add `audioplayers: ^6.x` (or `just_audio`) to `pubspec.yaml`
- In `InterviewScreen`, after receiving each question from the AI, call `SpeechService.speak(question)` before enabling the mic

**Files to change:** `lib/services/speech_service.dart`, `lib/screens/home/interview_screen.dart`, `pubspec.yaml`

---

### 6. Implement interview save (`POST /api/interviews`)

**Why:** The web app saves every completed interview to the backend. The mobile app has no save logic at all.

**What to do:**
- After the last question is answered and the report is generated, call `POST /api/interviews` with:
  ```json
  {
    "job_category": "<domain>",
    "overall_score": <int>,
    "questions": [
      { "question_asked": "...", "user_answer": "...", "ai_feedback": "...", "score": <int> }
    ],
    "analytics_scores": {
      "Communication": <int>, "Technical": <int>,
      "Problem Solving": <int>, "Behavioral": <int>
    }
  }
  ```
- Handle the 429 response (daily limit reached) — show a dialog: "You've already completed an interview today. Come back tomorrow."
- This call is best-effort (don't block navigation to the report screen if it fails)

**Files to change:** `lib/screens/home/interview_screen.dart`, `lib/services/api_client.dart`

---

### 7. Wire Dashboard to `GET /api/dashboard`

**Why:** The web dashboard shows real stats (total interviews, highest score, avg score, progress chart, recent sessions) from the backend. The mobile `AnalyticsScreen` shows hardcoded values.

**What to do:**
- Create `lib/services/dashboard_service.dart` that calls `GET /api/dashboard` and returns a typed `DashboardData` model
- `DashboardData` fields: `totalInterviews`, `highestScore`, `avgScore`, `recentInterviews` (list), `progressData` (list of `{date, score}`)
- In `DashboardScreen` (home tab), fetch on mount and display:
  - 4 stat cards: Total Interviews, Highest Score, Avg Score (match web layout)
  - Progress line chart using `fl_chart` (already installed) — `progressData` as the data source
  - Recent interviews list (last 6) with role, date, score
- In `AnalyticsScreen`, reuse the same `DashboardService` data instead of hardcoded values

**Files to change:** `lib/services/dashboard_service.dart` (new), `lib/screens/home/dashboard_screen.dart`, `lib/screens/home/analytics_screen.dart`

---

### 8. Implement PDF resume text extraction

**Why:** The web app uses `pdfjs-dist` to extract text from the uploaded PDF and sends it as context to the AI. The mobile app stores the file path but never extracts text — so the AI gets no resume context.

**What to do:**
- Add `syncfusion_flutter_pdf: ^x.x` or `pdfx: ^2.x` to `pubspec.yaml` for PDF text extraction
- In `InterviewSetupScreen`, after the user picks a PDF:
  1. Extract all text from the PDF pages
  2. Store in `_resumeText` state
  3. Pass as `resumeText` in `InterviewConfig`
- The extracted text is then sent to `/api/chat` as part of the system prompt (same as web)

**Files to change:** `lib/screens/home/interview_setup_screen.dart`, `pubspec.yaml`

---

### 9. Wire auth flow end-to-end (login gate)

**Why:** The app currently boots directly to `DashboardScreen` with no auth check. Every API call will fail with 401.

**What to do:**
- In `main.dart`:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final token = await TokenService.instance.getToken();
    runApp(AQIAApp(isLoggedIn: token != null && !TokenService.instance.isExpired(token)));
  }
  ```
- `AQIAApp.home` = `isLoggedIn ? DashboardScreen() : LoginScreen()`
- After successful login/register, navigate to `DashboardScreen`
- On 401 from any API call, clear token and navigate to `LoginScreen`
- `ProfileScreen` logout button: clear token → navigate to `LoginScreen`

**Files to change:** `lib/main.dart`, `lib/screens/auth/login_screen.dart`, `lib/screens/auth/signup_screen.dart`, `lib/screens/home/profile_screen.dart`

---

### 10. Port the interview prompt system (PromptBuilder) to Dart

**Why:** The web's `promptBuilder.js` builds the system prompt that drives the entire interview — domain-specific focus, resume analysis, conversation phases, question count. The mobile `InterviewService` uses a simple static question bank instead.

**What to do:**
- Create `lib/services/prompt_builder.dart` — a Dart port of `promptBuilder.js`:
  - `analyzeResume(resumeText)` → extracts experience level, skills, companies, achievements
  - `getInterviewPrompt(domain, resumeText, analysis)` → returns the full system prompt string
  - `getAvailableDomains()` → returns the 9 domains (match web: Software Engineering, Data Science, Product Management, UI/UX Design, Cybersecurity, Cloud Computing, DevOps, Machine Learning, AI Research)
- Update `InterviewService.startInterview()` to use `PromptBuilder` to build the system prompt and send it as the first message to `/api/chat`
- The conversation is stateful: each `sendMessage()` appends to `conversationHistory` and sends the full history to `/api/chat` (same as web `AIservice.js`)

**Files to change:** `lib/services/prompt_builder.dart` (new), `lib/services/interview_service.dart`, `lib/services/ai_service.dart`

---

## Summary — ordered by dependency

```
1. ApiClient + TokenService          ← everything depends on this
2. Auth (register/login/JWT)         ← needed before any authenticated call
3. main.dart login gate              ← needed to reach the app
4. PromptBuilder (Dart port)         ← needed for AI calls
5. AiService → /api/chat             ← core interview AI
6. PDF text extraction               ← feeds into AiService
7. STT → /api/transcribe             ← answer capture
8. TTS → /google-tts                 ← question playback
9. Interview save → /api/interviews  ← persistence
10. Dashboard → /api/dashboard       ← analytics
```

## Packages to add to pubspec.yaml

```yaml
# Replace / add
record: ^5.2.0          # raw audio capture for Whisper upload (replaces speech_to_text stub)
audioplayers: ^6.1.0    # play MP3 from /google-tts endpoint
pdfx: ^2.6.0            # PDF text extraction
jwt_decoder: ^2.0.1     # decode JWT expiry on mobile

# Remove (no longer needed)
# firebase_core
# firebase_auth
# firebase_messaging
# google_sign_in
# glassmorphism        (unused)
# lottie               (unused)
```

## Backend env vars the app needs to know

| Variable | Where to set | Value |
|---|---|---|
| `API_BASE_URL` | `--dart-define=API_BASE_URL=https://your-backend.com` | Backend URL |

The app should never hold the Groq API key, OpenAI key, or any other secret — all AI calls go through the backend proxy.
