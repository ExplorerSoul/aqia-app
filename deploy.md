# AQIA — Deployment Guide

## Step 1 — Install dependencies

```bash
flutter pub get
```

---

## Step 2 — Test on a real Android device

Connect your phone via USB, enable **Developer Mode** + **USB Debugging**, then:

```bash
flutter run --dart-define=API_BASE_URL=https://aqia-backend.onrender.com
```

Test the full flow:
- [ ] App boots to login screen
- [ ] Register / login works
- [ ] Interview setup screen loads
- [ ] PDF resume upload works
- [ ] Interview runs (AI speaks question, mic records answer)
- [ ] Report screen shows scores and Q&A
- [ ] Dashboard shows stats
- [ ] Logout works

---

## Step 3 — Generate signing keystore (one-time)

```bash
keytool -genkey -v -keystore ~/aqia-release.keystore \
  -alias aqia -keyalg RSA -keysize 2048 -validity 10000
```

Remember the passwords you set. **Back this file up — losing it means you can never update the app.**

---

## Step 4 — Create key.properties

Create `android/key.properties` (this file is gitignored — never commit it):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=aqia
storeFile=/Users/YOUR_USERNAME/aqia-release.keystore
```

---

## Step 5 — Build release AAB

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://aqia-backend.onrender.com
```

Output: `build/app/outputs/bundle/release/app-release.aab`

---

## Step 6 — Play Store setup

1. Go to [play.google.com/console](https://play.google.com/console) — $25 one-time fee
2. Create new app → Android → Free → App
3. Fill in store listing:
   - **App name**: AQIA - AI Mock Interview Assistant
   - **Short description** (80 chars max): Practice job interviews with AI-powered questions and real-time feedback
   - **Full description**: see below
   - **Screenshots**: at least 2 phone screenshots (take from device during Step 2)
   - **Feature graphic**: 1024×500 PNG
   - **App icon**: use `assets/aqia_app_icon.png` (512×512)
4. Content rating questionnaire — fill it out
5. Privacy policy URL — generate one at [privacypolicygenerator.info](https://privacypolicygenerator.info)
6. App access — no special login required

### Full description (copy-paste ready)

```
AQIA is your personal AI-powered mock interview coach.

Practice interviews for Software Engineering, Data Science, Product Management, UI/UX Design, Cybersecurity, Cloud Computing, DevOps, Machine Learning, and AI Research roles.

HOW IT WORKS:
1. Upload your resume (PDF)
2. Choose your interview domain and number of questions
3. The AI asks you questions tailored to your background
4. Answer by voice or text
5. Get a detailed performance report with scores, strengths, areas to improve, and suggested answers

FEATURES:
• AI interviewer powered by Llama 3.3 (Groq)
• Voice input transcribed by Whisper AI
• Questions spoken aloud via Google Neural2 TTS
• Resume-aware questions tailored to your experience
• Detailed report: overall score, communication, technical, problem-solving, behavioral
• Speech analytics: words per minute, filler word count
• Dashboard with progress chart and session history
• 1 interview per day to keep practice focused

Practice smarter. Interview better.
```

---

## Step 7 — Upload AAB and publish

1. Play Console → **Production** → **Create new release**
2. Upload `app-release.aab`
3. Release notes: `Initial release of AQIA AI Interview Assistant`
4. Save → Review release → Start rollout to Production

Review takes a few hours to 3 days for a new app.

---

## Current status

- [x] Code pushed to GitHub
- [x] App ID set: `com.explorersoul.aqia`
- [x] Android permissions configured
- [x] Signing config wired
- [ ] `flutter pub get`
- [ ] Test on device
- [ ] Generate keystore
- [ ] Create `key.properties`
- [ ] Build AAB
- [ ] Play Store listing
- [ ] Upload and publish
