# AQIA - Deployment Guide

Deploy AQIA so others can try and use it. Choose one of the options below.

---

## Option 1: Web (Easiest – Share a Link)

The app is already built. Deploy the `build/web` folder to any static host.

### Vercel (Free, Recommended)

1. Install Vercel CLI: `npm i -g vercel`
2. Build and deploy:
   ```bash
   flutter build web
   cd build/web && vercel --prod
   ```
   Or from project root: `vercel build/web --prod`
3. Follow prompts. You'll get a URL like `https://aqia-xxx.vercel.app`

### Netlify (Free)

1. Sign up at [netlify.com](https://netlify.com)
2. Drag and drop the `build/web` folder to [app.netlify.com/drop](https://app.netlify.com/drop)
3. Or use Netlify CLI:
   ```bash
   flutter build web
   netlify deploy --prod --dir=build/web
   ```

### Firebase Hosting

1. Install Firebase CLI: `npm i -g firebase-tools`
2. Login: `firebase login`
3. Initialize (if not done): `firebase init hosting`
   - Public directory: `build/web`
   - Single-page app: Yes
4. Build and deploy:
   ```bash
   flutter build web
   firebase deploy
   ```

### GitHub Pages

1. Build: `flutter build web --base-href "/your-repo-name/"`
2. Push `build/web` contents to the `gh-pages` branch
3. Enable GitHub Pages in repo Settings → Pages

---

## Option 2: Android APK (Direct Install)

Share an APK so users can install on Android without the Play Store:

```bash
flutter build apk --release
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

Share this file directly (email, Drive, etc.) or host it for download.

---

## Option 3: Google Play Store

1. Build App Bundle: `flutter build appbundle --release`
2. Output: `build/app/outputs/bundle/release/app-release.aab`
3. Create a [Google Play Developer account](https://play.google.com/console) ($25 one-time)
4. Create a new app and upload the AAB
5. Fill in store listing, screenshots, privacy policy, etc.
6. Submit for review

---

## Option 4: Apple App Store

1. Build: `flutter build ipa` (requires macOS and Xcode)
2. Use Xcode to upload to App Store Connect
3. Requires [Apple Developer account](https://developer.apple.com) ($99/year)

---

## Quick Commands Summary

| Action | Command |
|--------|---------|
| Build web | `flutter build web` |
| Build Android APK | `flutter build apk --release` |
| Build Android AAB (Play Store) | `flutter build appbundle --release` |
| Build iOS (macOS only) | `flutter build ipa` |
| Regenerate icons | `dart run flutter_launcher_icons` |

---

## Icon

The app icon is stored at `assets/aqia_app_icon.png`. To regenerate platform icons:

```bash
dart run flutter_launcher_icons
```
