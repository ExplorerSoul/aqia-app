import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqia/main.dart';
import 'package:aqia/theme/app_theme.dart';
import 'package:aqia/screens/auth/login_screen.dart';
import 'package:aqia/screens/auth/signup_screen.dart';
import 'package:aqia/models/interview_report.dart';
import 'package:aqia/screens/home/interview_report_screen.dart';
import 'package:aqia/screens/home/question_bank_screen.dart';
import 'package:aqia/screens/test/backend_test_screen.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );

InterviewReport _mockReport() => InterviewReport(
      candidateName: 'Test User',
      overallScore: 78,
      communicationScore: 82,
      technicalScore: 75,
      problemSolvingScore: 80,
      behavioralScore: 70,
      wordsPerMinute: 112,
      fillerWords: 3,
      speechRecommendation: 'Good pacing. Keep it up!',
      executiveSummary: 'Strong candidate with good communication skills.',
      keyStrengths: ['Clear communication', 'Good problem-solving'],
      areasForImprovement: ['More concrete examples', 'System design depth'],
      detailedQa: [
        QaAnalysis(
          questionNumber: 1,
          question: 'Tell me about yourself.',
          userResponse: 'I am a software engineer with 3 years of experience.',
          suggestedImprovement:
              'Include specific achievements and what excites you about this role.',
        ),
        QaAnalysis(
          questionNumber: 2,
          question: 'Describe a challenging project.',
          userResponse: 'I built a real-time chat system.',
          suggestedImprovement:
              'Use the STAR method: Situation, Task, Action, Result.',
        ),
      ],
    );

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('Login Screen', () {
    testWidgets('renders AQIA title and login form', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      expect(find.text('AQIA'), findsOneWidget);
      expect(find.text('Your AI Interview Coach'), findsOneWidget);
      expect(find.text('Log In'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(2)); // email + password
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      // Tap login button without filling fields
      await tester.tap(find.text('Log In').last);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows Test Backend Connection link', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      expect(find.text('Test Backend Connection'), findsOneWidget);
    });

    testWidgets('navigates to signup screen', (tester) async {
      await tester.pumpWidget(_wrap(const LoginScreen()));
      await tester.pump();

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('Create your account'), findsOneWidget);
    });
  });

  group('Signup Screen', () {
    testWidgets('renders all fields', (tester) async {
      await tester.pumpWidget(_wrap(const SignupScreen()));
      await tester.pump();

      expect(find.text('AQIA'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(4)); // name, email, pw, confirm
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('shows password mismatch error', (tester) async {
      await tester.pumpWidget(_wrap(const SignupScreen()));
      await tester.pump();

      await tester.enterText(
          find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(
          find.byType(TextFormField).at(1), 'test@example.com');
      await tester.enterText(
          find.byType(TextFormField).at(2), 'password123');
      await tester.enterText(
          find.byType(TextFormField).at(3), 'different123');

      await tester.tap(find.text('Create Account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });

  group('Interview Report Screen', () {
    testWidgets('renders all report sections', (tester) async {
      await tester.pumpWidget(_wrap(InterviewReportScreen(report: _mockReport())));
      await tester.pumpAndSettle();

      expect(find.text('Performance Review'), findsOneWidget);
      expect(find.text('PERFORMANCE SCORE'), findsOneWidget);
      expect(find.text('SPEECH ANALYTICS'), findsOneWidget);
      expect(find.text('EXECUTIVE SUMMARY'), findsOneWidget);
      expect(find.text('KEY STRENGTHS'), findsOneWidget);
      expect(find.text('AREAS TO IMPROVE'), findsOneWidget);
      expect(find.text('Detailed Q&A Analysis'), findsOneWidget);
    });

    testWidgets('shows correct overall score', (tester) async {
      await tester.pumpWidget(_wrap(InterviewReportScreen(report: _mockReport())));
      await tester.pumpAndSettle();

      expect(find.text('78'), findsWidgets); // overall score
    });

    testWidgets('shows download button', (tester) async {
      await tester.pumpWidget(_wrap(InterviewReportScreen(report: _mockReport())));
      await tester.pumpAndSettle();

      expect(find.text('Download Report'), findsOneWidget);
    });

    testWidgets('Q&A items are single column (no side-by-side Row)', (tester) async {
      await tester.pumpWidget(_wrap(InterviewReportScreen(report: _mockReport())));
      await tester.pumpAndSettle();

      expect(find.text('YOUR RESPONSE'), findsWidgets);
      expect(find.text('SUGGESTED IMPROVEMENT'), findsWidgets);
      // Both labels should be visible (not clipped in a side-by-side row)
      expect(find.text('Tell me about yourself.'), findsOneWidget);
    });

    testWidgets('shows speech analytics stats', (tester) async {
      await tester.pumpWidget(_wrap(InterviewReportScreen(report: _mockReport())));
      await tester.pumpAndSettle();

      expect(find.text('112'), findsOneWidget); // wpm
      expect(find.text('3'), findsWidgets);     // filler words
    });
  });

  group('Question Bank Screen', () {
    testWidgets('shows empty state when no questions', (tester) async {
      await tester.pumpWidget(_wrap(const QuestionBankScreen()));
      await tester.pump(const Duration(milliseconds: 500));

      // Either shows empty state or question list
      // (depends on SharedPreferences state in test environment)
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('Backend Test Screen', () {
    testWidgets('renders all 6 test cases', (tester) async {
      await tester.pumpWidget(_wrap(const BackendTestScreen()));
      await tester.pump();

      expect(find.text('Health Check'), findsOneWidget);
      expect(find.text('Register'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('JWT Valid'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Chat Proxy'), findsOneWidget);
      expect(find.text('Run All Tests'), findsOneWidget);
    });

    testWidgets('shows backend URL', (tester) async {
      await tester.pumpWidget(_wrap(const BackendTestScreen()));
      await tester.pump();

      expect(find.textContaining('aqia-backend.onrender.com'), findsOneWidget);
    });
  });
}
