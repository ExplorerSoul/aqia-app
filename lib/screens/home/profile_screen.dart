import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = AuthService.instance.userEmail ?? '';
    final displayName = email.contains('@') ? email.split('@')[0] : email;
    final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Avatar + name
          Container(
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassDecoration(borderRadius: 20),
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
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.transparent,
                    child: Text(
                      initials,
                      style: const TextStyle(
                          fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.whiteText),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.alternate_email, size: 16, color: AppTheme.lightGrayText),
                    const SizedBox(width: 6),
                    Text(email, style: TextStyle(fontSize: 14, color: AppTheme.lightGrayText)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Settings header
          Row(
            children: [
              Icon(Icons.settings, size: 20, color: AppTheme.lightGrayText),
              const SizedBox(width: 8),
              const Text('Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.whiteText)),
            ],
          ),
          const SizedBox(height: 16),

          // Account info tile
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: AppTheme.grayText, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(email,
                      style: const TextStyle(fontSize: 15, color: AppTheme.whiteText),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Backend info tile
          GlassCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, color: AppTheme.grayText, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Backend',
                          style: TextStyle(fontSize: 15, color: AppTheme.whiteText)),
                      Text(
                        const String.fromEnvironment('API_BASE_URL', defaultValue: 'https://aqia-backend.onrender.com'),
                        style: TextStyle(fontSize: 12, color: AppTheme.grayText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Logout
          GlassCard(
            padding: const EdgeInsets.all(16),
            onTap: () => _confirmLogout(context),
            child: Row(
              children: [
                Icon(Icons.power_settings_new, color: Colors.red.shade400, size: 22),
                const SizedBox(width: 12),
                Text('Log out',
                    style: TextStyle(fontSize: 16, color: Colors.red.shade400, fontWeight: FontWeight.w500)),
                const Spacer(),
                Icon(Icons.chevron_right, color: AppTheme.lightGrayText),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.carbonGrayDark,
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
