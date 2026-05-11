import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/starry_background.dart';
import '../../services/auth_service.dart';
import '../../services/dashboard_service.dart';
import '../auth/login_screen.dart';
import 'interview_setup_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'question_bank_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StarryBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    _HomeTab(),
                    AnalyticsScreen(),
                    ProfileScreen(),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  String get _appBarTitle {
    switch (_selectedIndex) {
      case 1: return 'Analytics & Growth';
      case 2: return 'Profile & Settings';
      default: return 'AQIA';
    }
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _appBarTitle,
            style: const TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: AppTheme.whiteText,
            ),
          ),
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.grayText),
              onPressed: () async {
                await AuthService.instance.logout();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.carbonGrayDark.withValues(alpha: 0.95),
        border: Border(top: BorderSide(color: AppTheme.glassBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home, 'Home', 0),
          _navItem(Icons.bar_chart, 'Analytics', 1),
          _navItem(Icons.person, 'Profile', 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: isSelected ? AppTheme.purplePrimary : AppTheme.grayText),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppTheme.purplePrimary : AppTheme.grayText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  DashboardData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDashboard();
  }

  Future<void> _fetchDashboard() async {
    try {
      final data = await DashboardService.instance.fetchDashboard();
      if (mounted) setState(() { _data = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _data = DashboardData.empty(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.userEmail ?? '';
    final displayName = email.contains('@') ? email.split('@')[0] : email;

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      color: AppTheme.purplePrimary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Welcome back, $displayName!',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.whiteText),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 4),
            Text(
              'Ready to ace your next interview?',
              style: TextStyle(fontSize: 15, color: AppTheme.lightGrayText),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),

            // Start Interview button
            _buildStartButton(context),
            const SizedBox(height: 16),

            // Question Bank button
            _buildQuestionBankButton(context),
            const SizedBox(height: 28),

            // Stats row
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.purplePrimary),
              ))
            else ...[
              _buildStatsRow(_data!),
              const SizedBox(height: 24),
              _buildRecentInterviews(_data!),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBankButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.gradientBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.gradientBlue.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.quiz_outlined, color: AppTheme.gradientBlue, size: 22),
                SizedBox(width: 10),
                Text('Question Bank',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.gradientBlue)),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: AppTheme.buttonGradientDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const InterviewSetupScreen()),
            ).then((_) => _fetchDashboard()),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch, size: 24, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Start Interview',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildStatsRow(DashboardData data) {
    return Row(
      children: [
        Expanded(child: _statCard('Total', '${data.totalInterviews}', Icons.bar_chart, AppTheme.gradientBlue)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Best', data.highestScore > 0 ? '${data.highestScore}%' : '—', Icons.emoji_events, Colors.amber)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Avg', data.avgScore > 0 ? '${data.avgScore}%' : '—', Icons.trending_up, AppTheme.purplePrimary)),
      ],
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: AppTheme.grayText)),
        ],
      ),
    );
  }

  Widget _buildRecentInterviews(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Interviews',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteText)),
        const SizedBox(height: 12),
        if (data.recentInterviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.carbonGrayDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Center(
              child: Text('No interviews yet. Start one!',
                  style: TextStyle(color: AppTheme.grayText)),
            ),
          )
        else
          ...data.recentInterviews.asMap().entries.map((e) {
            final interview = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.carbonGrayDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.glassBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.purplePrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.work_outline, color: AppTheme.purplePrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(interview.role,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.whiteText)),
                          Text(interview.date,
                              style: TextStyle(fontSize: 12, color: AppTheme.grayText)),
                        ],
                      ),
                    ),
                    if (interview.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _scoreColor(interview.score!).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${interview.score}%',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _scoreColor(interview.score!)),
                        ),
                      ),
                  ],
                ),
              ).animate(delay: (e.key * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
            );
          }),
      ],
    );
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green.shade400;
    if (score >= 60) return Colors.amber;
    return Colors.red.shade400;
  }
}
