import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/app_theme.dart';
import '../../widgets/user_banner_carousel.dart';
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
  // Using a key forces _HomeTab to rebuild (and re-fetch) when tab is re-selected
  Key _homeKey = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _HomeTab(key: _homeKey),
                  const AnalyticsScreen(),
                  const ProfileScreen(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _appBarTitle,
            style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary, letterSpacing: -0.3,
            ),
          ),
          if (_selectedIndex == 2)
            IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.textMuted, size: 22),
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
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.home_outlined, Icons.home, 'Home', 0),
          _navItem(Icons.bar_chart_outlined, Icons.bar_chart, 'Analytics', 1),
          _navItem(Icons.person_outline, Icons.person, 'Profile', 2),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, IconData activeIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          // If tapping home tab again, force a refresh
          if (index == 0 && _selectedIndex == 0) {
            _homeKey = UniqueKey();
          } else if (index == 0) {
            _homeKey = UniqueKey(); // always refresh when switching to home
          }
          _selectedIndex = index;
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isSelected ? activeIcon : icon,
              size: 24, color: isSelected ? AppTheme.accent : AppTheme.textMuted),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? AppTheme.accent : AppTheme.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({super.key});

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
    final displayName = AuthService.instance.displayName;

    return RefreshIndicator(
      onRefresh: _fetchDashboard,
      color: AppTheme.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Welcome back, $displayName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary, letterSpacing: -0.3),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),
            const SizedBox(height: 4),
            const Text(
              'Ready to ace your next interview?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms),
            const SizedBox(height: 24),
            _buildStartButton(context),
            const SizedBox(height: 12),
            _buildQuestionBankButton(context),
            const SizedBox(height: 28),
            const UserBannerCarousel(),
            const SizedBox(height: 28),
            if (_loading)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppTheme.accent),
              ))
            else ...[
              _buildStatsRow(_data!),
              const SizedBox(height: 24),
              _buildRecentInterviews(_data!),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionBankButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuestionBankScreen()),
        ),
        icon: const Icon(Icons.quiz_outlined, size: 18),
        label: const Text('Question Bank'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: AppTheme.border),
          foregroundColor: AppTheme.textSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _buildStartButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const InterviewSetupScreen()),
        ).then((_) => _fetchDashboard()),
        icon: const Icon(Icons.rocket_launch, size: 18),
        label: const Text('New Interview'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ).animate(delay: 150.ms).fadeIn(duration: 500.ms);
  }

  Widget _buildStatsRow(DashboardData data) {
    return Row(
      children: [
        Expanded(child: _statCard('Total', '${data.totalInterviews}', Icons.bar_chart, AppTheme.accent)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Best', data.highestScore > 0 ? '${data.highestScore}%' : '—', Icons.emoji_events, AppTheme.success)),
        const SizedBox(width: 12),
        Expanded(child: _statCard('Avg', data.avgScore > 0 ? '${data.avgScore}%' : '—', Icons.trending_up, AppTheme.warning)),
      ],
    ).animate(delay: 200.ms).fadeIn(duration: 400.ms);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildRecentInterviews(DashboardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Interviews',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        if (data.recentInterviews.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Center(
              child: Text('No interviews yet. Start one!',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
          )
        else
          ...data.recentInterviews.asMap().entries.map((e) {
            final interview = e.value;
            final score = interview.score ?? 0;
            final sc = score >= 80 ? AppTheme.success : score >= 60 ? AppTheme.warning : AppTheme.danger;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.work_outline, color: AppTheme.accent, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(interview.role,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          Text(interview.date,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    ),
                    if (interview.score != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sc.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: sc.withValues(alpha: 0.3)),
                        ),
                        child: Text('${interview.score}%',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sc)),
                      ),
                  ],
                ),
              ).animate(delay: (e.key * 60).ms).fadeIn(duration: 300.ms),
            );
          }),
      ],
    );
  }
}
