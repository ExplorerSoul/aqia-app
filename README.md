# AQIA - AI Mock Interview Assistant

A Flutter mobile application designed to help students practice AI-based mock interviews, get real-time feedback, and track their progress using analytics and dashboards.

## Features

- 🔐 **Authentication**: Firebase Authentication with email/password and Google Sign-In
- 🎤 **Speech Input**: Real-time speech-to-text for interview answers
- 📝 **Text Input**: Alternative text-based input method
- 🤖 **AI Feedback**: Real-time feedback on fluency, content, confidence, and filler words
- 📊 **Analytics Dashboard**: Track progress over time with interactive charts
- 📈 **Progress Tracking**: Monitor confidence score, accuracy, and fluency trends
- 👤 **User Profile**: Manage profile information and settings
- 🎨 **Modern UI**: Glassmorphism design with blue/black/white theme

## Project Structure

```
lib/
├── main.dart                 # App entry point with Firebase initialization
├── models/                   # Data models
│   ├── user_model.dart
│   ├── interview_feedback.dart
│   └── progress_data.dart
├── screens/                  # App screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── home/
│   │   └── dashboard_screen.dart
│   ├── interview/
│   │   └── interview_screen.dart
│   ├── analytics/
│   │   └── analytics_screen.dart
│   └── profile/
│       └── profile_screen.dart
├── services/                # Backend services
│   ├── api_service.dart
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── speech_service.dart
├── widgets/                 # Reusable widgets
│   ├── glass_card.dart
│   ├── progress_card.dart
│   ├── waveform_animation.dart
│   └── feedback_card.dart
├── providers/               # State management
│   └── auth_provider.dart
└── theme/                   # App theme
    └── app_theme.dart
```

## Setup Instructions

### 1. Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Firebase account

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Setup

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Authentication:
   - Email/Password
   - Google Sign-In
3. Create a Firestore database
4. Run FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
5. This will generate `firebase_options.dart` file

### 4. Backend API Configuration

Update the `baseUrl` in `lib/services/api_service.dart` with your backend URL:

```dart
static const String baseUrl = 'https://your-aqia-backend.com/api';
```

### 5. Permissions

#### Android (`android/app/src/main/AndroidManifest.xml`)

Add permissions for microphone and internet:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

#### iOS (`ios/Runner/Info.plist`)

Add microphone usage description:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for speech-to-text during interviews.</string>
```

### 6. Run the App

```bash
flutter run
```

## Dependencies

### Core
- `firebase_core`: Firebase initialization
- `firebase_auth`: Authentication
- `cloud_firestore`: Database
- `firebase_messaging`: Push notifications

### UI & Design
- `google_fonts`: Poppins font family
- `glassmorphism`: Glass effect cards
- `fl_chart`: Charts and graphs
- `lottie`: Animations
- `flutter_animate`: Smooth animations

### Features
- `speech_to_text`: Speech recognition
- `flutter_tts`: Text-to-speech
- `http` & `dio`: API calls
- `provider`: State management

### Icons
- `font_awesome_flutter`: Additional icons

## API Endpoints

The app expects the following backend endpoints:

- `POST /api/login` - User login
- `GET /api/questions?userId={id}&category={cat}` - Get interview question
- `POST /api/feedback` - Submit answer and get feedback
- `GET /api/progress?userId={id}` - Get user progress data

## Color Scheme

- **Primary Blue**: `#007BFF`
- **Black Background**: `#0A0A0A`
- **White Text/Cards**: `#FFFFFF`
- **Dark Blue**: `#0056B3`
- **Light Blue**: `#4DA3FF`

## Features in Detail

### Authentication
- Email/password authentication
- Google Sign-In integration
- Secure session management

### Interview Screen
- Real-time speech-to-text
- Text input alternative
- Waveform animation during recording
- AI-powered feedback on:
  - Fluency (0-100%)
  - Content quality (0-100%)
  - Confidence level (0-100%)
  - Filler words count
- Overall feedback and suggestions

### Analytics Dashboard
- Line charts for overall growth
- Last 5 sessions overview
- Skill breakdown pie chart
- Metric selection (Confidence, Accuracy, Fluency)

### Profile & Settings
- Edit profile information
- Institution management
- Dark mode toggle
- Resume editor (coming soon)
- Logout functionality

## Future Enhancements

- [ ] Push notifications for feedback ready
- [ ] Resume upload and parsing
- [ ] Interview session history
- [ ] Custom interview categories
- [ ] Social sharing of progress
- [ ] Offline mode support
- [ ] Multi-language support

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and questions, please open an issue on the GitHub repository.

---

**Built with ❤️ using Flutter**
