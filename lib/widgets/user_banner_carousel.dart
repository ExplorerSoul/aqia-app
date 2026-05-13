import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A single user showcase card shown in the banner.
class UserBannerData {
  final String name;
  final String college;
  final String year;       // e.g. "3rd Year" or "2024 Graduate"
  final String domain;
  final int avgScore;
  final String? imagePath; // asset path e.g. 'assets/users/alice.jpg'
                           // null = show initials avatar

  const UserBannerData({
    required this.name,
    required this.college,
    required this.year,
    required this.domain,
    required this.avgScore,
    this.imagePath,
  });
}

// ─── Hardcoded sample data — replace with real user info + images ─────────────
// To add a real user:
//   1. Add their photo to assets/users/filename.jpg
//   2. Register it in pubspec.yaml under flutter > assets
//   3. Add a UserBannerData entry below with imagePath: 'assets/users/filename.jpg'

const List<UserBannerData> kSampleUsers = [
  UserBannerData(
    name: 'Priya Sharma',
    college: 'IIT Bombay',
    year: '3rd Year',
    domain: 'Software Engineering',
    avgScore: 88,
    imagePath: null, // replace with 'assets/users/priya.jpg'
  ),
  UserBannerData(
    name: 'Arjun Mehta',
    college: 'NIT Trichy',
    year: '4th Year',
    domain: 'Data Science',
    avgScore: 82,
    imagePath: null,
  ),
  UserBannerData(
    name: 'Sneha Reddy',
    college: 'BITS Pilani',
    year: '2024 Graduate',
    domain: 'Product Management',
    avgScore: 91,
    imagePath: null,
  ),
  UserBannerData(
    name: 'Rahul Verma',
    college: 'VIT Vellore',
    year: '3rd Year',
    domain: 'DevOps',
    avgScore: 79,
    imagePath: null,
  ),
  UserBannerData(
    name: 'Ananya Iyer',
    college: 'IIIT Hyderabad',
    year: '2nd Year',
    domain: 'Machine Learning',
    avgScore: 85,
    imagePath: null,
  ),
  UserBannerData(
    name: 'Karan Patel',
    college: 'DTU Delhi',
    year: '4th Year',
    domain: 'Software Engineering',
    avgScore: 76,
    imagePath: null,
  ),
];

// ─── Gradient colors per domain ───────────────────────────────────────────────
Color _domainColor(String domain) {
  switch (domain) {
    case 'Software Engineering': return const Color(0xFF7C3AED);
    case 'Data Science':         return const Color(0xFF0EA5E9);
    case 'Product Management':   return const Color(0xFFEC4899);
    case 'DevOps':               return const Color(0xFF10B981);
    case 'Machine Learning':     return const Color(0xFFF59E0B);
    default:                     return const Color(0xFF6366F1);
  }
}

Color _scoreColor(int score) {
  if (score >= 85) return const Color(0xFF22C55E);
  if (score >= 70) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

// ─── Main widget ──────────────────────────────────────────────────────────────

class UserBannerCarousel extends StatefulWidget {
  final List<UserBannerData> users;
  final Duration autoScrollInterval;

  const UserBannerCarousel({
    super.key,
    this.users = kSampleUsers,
    this.autoScrollInterval = const Duration(seconds: 3),
  });

  @override
  State<UserBannerCarousel> createState() => _UserBannerCarouselState();
}

class _UserBannerCarouselState extends State<UserBannerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _currentPage = 0;

  // We use a large virtual page count to simulate infinite scroll
  static const int _virtualMultiplier = 1000;

  int get _virtualCount => widget.users.length * _virtualMultiplier;
  int get _initialPage => widget.users.length * (_virtualMultiplier ~/ 2);

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _initialPage,
      viewportFraction: 0.82, // show peek of next card
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.autoScrollInterval, (_) {
      if (!mounted) return;
      _controller.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  void _pauseAutoScroll() {
    _timer?.cancel();
  }

  void _resumeAutoScroll() {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.purplePrimary, AppTheme.gradientBlue],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Community Spotlight',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.whiteText,
                ),
              ),
              const Spacer(),
              // Live dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade400,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carousel
        GestureDetector(
          onPanDown: (_) => _pauseAutoScroll(),
          onPanEnd: (_) => _resumeAutoScroll(),
          onPanCancel: () => _resumeAutoScroll(),
          child: SizedBox(
            height: 164,
            child: PageView.builder(
              controller: _controller,
              itemCount: _virtualCount,
              onPageChanged: (page) {
                setState(() => _currentPage = page % widget.users.length);
              },
              itemBuilder: (_, virtualIndex) {
                final user = widget.users[virtualIndex % widget.users.length];
                final isActive = (virtualIndex % widget.users.length) == _currentPage;
                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.94,
                  duration: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: _UserCard(user: user),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.users.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.purplePrimary : AppTheme.carbonGrayLight,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Individual card ──────────────────────────────────────────────────────────

class _UserCard extends StatelessWidget {
  final UserBannerData user;
  const _UserCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final domainColor = _domainColor(user.domain);
    final scoreColor = _scoreColor(user.avgScore);
    final initials = user.name.trim().split(' ')
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .take(2)
        .join();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.carbonGrayDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: domainColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: domainColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle gradient top-right accent
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    domainColor.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(initials, domainColor),
                const SizedBox(width: 14),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Name
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.whiteText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // College + year
                      Row(
                        children: [
                          Icon(Icons.school_outlined, size: 12, color: AppTheme.grayText),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${user.college} · ${user.year}',
                              style: TextStyle(fontSize: 12, color: AppTheme.grayText),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Domain chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: domainColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: domainColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          user.domain,
                          style: TextStyle(
                            fontSize: 11,
                            color: domainColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Score badge
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: scoreColor.withValues(alpha: 0.12),
                        border: Border.all(color: scoreColor.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${user.avgScore}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: scoreColor,
                              height: 1,
                            ),
                          ),
                          Text(
                            '%',
                            style: TextStyle(fontSize: 10, color: scoreColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Avg Score',
                      style: TextStyle(fontSize: 9, color: AppTheme.grayText),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initials, Color domainColor) {
    if (user.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          user.imagePath!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(initials, domainColor),
        ),
      );
    }
    return _initialsAvatar(initials, domainColor);
  }

  Widget _initialsAvatar(String initials, Color domainColor) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            domainColor,
            domainColor.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
