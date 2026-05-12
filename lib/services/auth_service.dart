import 'api_client.dart';
import 'token_service.dart';

/// Handles registration and login against the AQIA backend JWT auth system.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Register a new account. Saves the returned JWT and name automatically.
  Future<void> register({
    required String email,
    required String password,
    String? name,
  }) async {
    final data = await ApiClient.instance.post('/api/register', {
      'email': email,
      'password': password,
      if (name != null && name.isNotEmpty) 'name': name,
    });
    final token = data['access_token'] as String?;
    if (token == null) throw const ApiException(500, 'No token in register response');
    await TokenService.instance.saveToken(token);
    if (name != null && name.isNotEmpty) {
      await TokenService.instance.saveName(name);
    }
  }

  /// Login with email + password. Saves the returned JWT and fetches name.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final data = await ApiClient.instance.post('/api/login', {
      'email': email,
      'password': password,
    });
    final token = data['access_token'] as String?;
    if (token == null) throw const ApiException(500, 'No token in login response');
    await TokenService.instance.saveToken(token);
    // Fetch name from backend so profile shows real name
    try {
      final profile = await ApiClient.instance.get('/api/me');
      final name = profile['name'] as String?;
      if (name != null && name.isNotEmpty) {
        await TokenService.instance.saveName(name);
      }
    } catch (_) {}
  }

  /// Clear the stored token and name (logout).
  Future<void> logout() async {
    await TokenService.instance.clearToken();
  }

  bool get isLoggedIn => TokenService.instance.isValid;
  String? get userEmail => TokenService.instance.userEmail;
  String? get userId => TokenService.instance.userId;
  String get displayName => TokenService.instance.displayName;
}
