import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.userEmail ?? '';
    final payload = TokenService.instance.payload;
    // Use name from JWT if available, otherwise derive from email
    final name = payload['name'] as String? ??
        (email.contains('@') ? email.split('@')[0] : email);
    final displayName = name.isNotEmpty ? name : email;
    final initials = displayName.isNotEmpty
        ? displayName.trim().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').take(2).join()
        : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Avatar card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.purplePrimary.withValues(alpha: 0.15),
                  AppTheme.gradientBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.glassBorder),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.purplePrimary, AppTheme.gradientBlue],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.purplePrimary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 28, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.whiteText),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: TextStyle(fontSize: 13, color: AppTheme.grayText),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Account section
          _sectionHeader('Account'),
          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppTheme.gradientBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.email_outlined, color: AppTheme.gradientBlue, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Email',
                          style: TextStyle(fontSize: 12, color: AppTheme.grayText)),
                      const SizedBox(height: 2),
                      Text(email,
                          style: const TextStyle(fontSize: 14, color: AppTheme.whiteText),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Danger zone
          _sectionHeader('Session'),
          const SizedBox(height: 12),

          GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _confirmLogout(context),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.logout, color: Colors.red.shade400, size: 18),
                ),
                const SizedBox(width: 14),
                Text('Log out',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppTheme.grayText, size: 20),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.grayText,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.carbonGrayDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log out', style: TextStyle(color: AppTheme.whiteText)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: AppTheme.lightGrayText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.grayText)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService.instance.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              }
            },
            child: Text('Log out', style: TextStyle(color: Colors.red.shade400)),
          ),
        ],
      ),
    );
  }
}
