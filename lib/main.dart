import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/token_service.dart';
import 'services/speech_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load persisted JWT token
  await TokenService.instance.loadToken();

  // Init speech service
  await SpeechService.instance.init();

  final isLoggedIn = TokenService.instance.isValid;

  runApp(AQIAApp(isLoggedIn: isLoggedIn));
}

class AQIAApp extends StatelessWidget {
  final bool isLoggedIn;
  const AQIAApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AQIA - AI Mock Interview Assistant',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: isLoggedIn ? const DashboardScreen() : const LoginScreen(),
    );
  }
}
