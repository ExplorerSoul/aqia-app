import 'api_client.dart';
import 'token_service.dart';

/// Handles registration and login against the AQIA backend JWT auth system.
/// No Firebase — all auth is via /api/register and /api/login.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  /// Register a new account. Saves the returned JWT automatically.
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
  }

  /// Login with email + password. Saves the returned JWT automatically.
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
  }

  /// Clear the stored token (logout).
  Future<void> logout() async {
    await TokenService.instance.clearToken();
  }

  /// True if a valid (non-expired) token is stored.
  bool get isLoggedIn => TokenService.instance.isValid;

  String? get userEmail => TokenService.instance.userEmail;
  String? get userId => TokenService.instance.userId;
}
