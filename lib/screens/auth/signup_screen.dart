import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../home/dashboard_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await AuthService.instance.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.purplePrimary, AppTheme.gradientBlue],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.mic, size: 44, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'AQIA',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.whiteText,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your account',
                    style: TextStyle(fontSize: 16, color: AppTheme.lightGrayText),
                  ),
                  const SizedBox(height: 40),

                  // Name
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppTheme.whiteText),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline, color: AppTheme.grayText),
                        border: InputBorder.none,
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Please enter your name' : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.whiteText),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined, color: AppTheme.grayText),
                        border: InputBorder.none,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter your email';
                        if (!v.contains('@')) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.whiteText),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.grayText),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.grayText,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        border: InputBorder.none,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please enter a password';
                        if (v.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm password
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: TextFormField(
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: AppTheme.whiteText),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.grayText),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppTheme.grayText,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: InputBorder.none,
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sign up button
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: AppTheme.buttonGradientDecoration(),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleSignup,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Already have an account? ', style: TextStyle(color: AppTheme.lightGrayText)),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Log In',
                          style: TextStyle(color: AppTheme.purplePrimary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
