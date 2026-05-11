import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../services/token_service.dart';
import '../../theme/app_theme.dart';

enum _Status { idle, running, pass, fail }

class _TestResult {
  final String name;
  final String description;
  _Status status;
  String detail;

  _TestResult({
    required this.name,
    required this.description,
    this.status = _Status.idle,
    this.detail = '',
  });
}

/// A screen that runs connectivity checks against the backend.
/// Access via the debug banner on the login screen (only in debug/mock mode).
class BackendTestScreen extends StatefulWidget {
  const BackendTestScreen({super.key});

  @override
  State<BackendTestScreen> createState() => _BackendTestScreenState();
}

class _BackendTestScreenState extends State<BackendTestScreen> {
  late final List<_TestResult> _tests;
  bool _running = false;

  // Test credentials — only used for connectivity testing
  static const _testEmail = 'test_aqia_check@example.com';
  static const _testPassword = 'TestAqia123!';

  @override
  void initState() {
    super.initState();
    _tests = [
      _TestResult(
        name: 'Health Check',
        description: 'GET /api/health — backend is reachable',
      ),
      _TestResult(
        name: 'Register',
        description: 'POST /api/register — create test account',
      ),
      _TestResult(
        name: 'Login',
        description: 'POST /api/login — authenticate and get JWT',
      ),
      _TestResult(
        name: 'JWT Valid',
        description: 'Token stored and not expired',
      ),
      _TestResult(
        name: 'Dashboard',
        description: 'GET /api/dashboard — authenticated request',
      ),
      _TestResult(
        name: 'Chat Proxy',
        description: 'POST /api/chat — Groq LLM reachable (1 token)',
      ),
    ];
  }

  Future<void> _runAll() async {
    if (_running) return;
    setState(() {
      _running = true;
      for (final t in _tests) {
        t.status = _Status.idle;
        t.detail = '';
      }
    });

    await _run(0, _testHealth);
    await _run(1, _testRegister);
    await _run(2, _testLogin);
    await _run(3, _testJwt);
    await _run(4, _testDashboard);
    await _run(5, _testChat);

    setState(() => _running = false);
  }

  Future<void> _run(int index, Future<String> Function() fn) async {
    setState(() => _tests[index].status = _Status.running);
    try {
      final detail = await fn();
      setState(() {
        _tests[index].status = _Status.pass;
        _tests[index].detail = detail;
      });
    } catch (e) {
      setState(() {
        _tests[index].status = _Status.fail;
        _tests[index].detail = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<String> _testHealth() async {
    final result = await ApiClient.instance.get('/api/health');
    return result['status'] as String? ?? 'ok';
  }

  Future<String> _testRegister() async {
    try {
      await AuthService.instance.register(
        email: _testEmail,
        password: _testPassword,
        name: 'Test User',
      );
      return 'Registered successfully';
    } on ApiException catch (e) {
      // 400 = already registered — that's fine
      if (e.statusCode == 400) return 'Account already exists (OK)';
      rethrow;
    }
  }

  Future<String> _testLogin() async {
    await AuthService.instance.login(
      email: _testEmail,
      password: _testPassword,
    );
    return 'JWT received';
  }

  Future<String> _testJwt() async {
    final valid = TokenService.instance.isValid;
    if (!valid) throw Exception('Token missing or expired');
    final email = TokenService.instance.userEmail ?? '';
    return 'Valid — $email';
  }

  Future<String> _testDashboard() async {
    final result = await ApiClient.instance.get('/api/dashboard');
    final total = result['total_interviews'] ?? 0;
    return 'total_interviews: $total';
  }

  Future<String> _testChat() async {
    final result = await ApiClient.instance.post('/api/chat', {
      'model': 'llama-3.3-70b-versatile',
      'messages': [
        {'role': 'user', 'content': 'Reply with exactly: OK'},
      ],
      'max_tokens': 5,
      'temperature': 0,
    });
    final reply = result['choices']?[0]?['message']?['content'] as String? ?? '';
    return 'Reply: "$reply"';
  }

  @override
  Widget build(BuildContext context) {
    final allDone = !_running && _tests.any((t) => t.status != _Status.idle);
    final passed = _tests.where((t) => t.status == _Status.pass).length;
    final failed = _tests.where((t) => t.status == _Status.fail).length;

    return Scaffold(
      backgroundColor: AppTheme.blackBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.carbonBlack,
        title: const Text('Backend Connectivity Test',
            style: TextStyle(color: AppTheme.whiteText, fontSize: 16)),
      ),
      body: Column(
        children: [
          // Backend URL banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.carbonGrayDark,
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, size: 16, color: AppTheme.grayText),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConfig.apiBaseUrl,
                    style: TextStyle(fontSize: 12, color: AppTheme.grayText),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (AppConfig.mockMode)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Text('MOCK MODE',
                        style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),

          // Results list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _tests.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _buildTestTile(_tests[i]),
            ),
          ),

          // Summary + run button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.carbonGrayDark,
              border: Border(top: BorderSide(color: AppTheme.glassBorder)),
            ),
            child: Column(
              children: [
                if (allDone)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade400, size: 18),
                        const SizedBox(width: 6),
                        Text('$passed passed',
                            style: TextStyle(color: Colors.green.shade400, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        if (failed > 0) ...[
                          Icon(Icons.cancel, color: Colors.red.shade400, size: 18),
                          const SizedBox(width: 6),
                          Text('$failed failed',
                              style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.bold)),
                        ],
                      ],
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: AppTheme.buttonGradientDecoration(),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _running ? null : _runAll,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: _running
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    ),
                                    SizedBox(width: 10),
                                    Text('Running tests...',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      allDone ? 'Run Again' : 'Run All Tests',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestTile(_TestResult test) {
    final icon = switch (test.status) {
      _Status.idle => Icon(Icons.radio_button_unchecked, color: AppTheme.grayText, size: 20),
      _Status.running => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.purplePrimary),
        ),
      _Status.pass => Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
      _Status.fail => Icon(Icons.cancel, color: Colors.red.shade400, size: 20),
    };

    final borderColor = switch (test.status) {
      _Status.pass => Colors.green.shade700.withValues(alpha: 0.4),
      _Status.fail => Colors.red.shade700.withValues(alpha: 0.4),
      _Status.running => AppTheme.purplePrimary.withValues(alpha: 0.4),
      _ => AppTheme.glassBorder,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.carbonGrayDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2), child: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(test.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.whiteText)),
                const SizedBox(height: 2),
                Text(test.description,
                    style: TextStyle(fontSize: 12, color: AppTheme.grayText)),
                if (test.detail.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    test.detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: test.status == _Status.fail
                          ? Colors.red.shade300
                          : Colors.green.shade300,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
