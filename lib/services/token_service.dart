import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Singleton that manages the JWT token lifecycle.
/// All services read the token from here — never from raw SharedPreferences.
class TokenService {
  TokenService._();
  static final TokenService instance = TokenService._();

  static const _key = 'aqia_token';

  String? _cachedToken;

  /// Save token to persistent storage and in-memory cache.
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// Load token from persistent storage (called once at startup).
  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_key);
    return _cachedToken;
  }

  /// Return cached token synchronously (after [loadToken] has been called).
  String? get token => _cachedToken;

  /// Authorization header map, ready to pass to http requests.
  Map<String, String> get authHeader =>
      _cachedToken != null ? {'Authorization': 'Bearer $_cachedToken'} : {};

  /// True if a token exists and has not expired.
  bool get isValid {
    if (_cachedToken == null) return false;
    try {
      return !JwtDecoder.isExpired(_cachedToken!);
    } catch (_) {
      return false;
    }
  }

  /// Decode the token payload (without verifying signature).
  Map<String, dynamic> get payload {
    if (_cachedToken == null) return {};
    try {
      return JwtDecoder.decode(_cachedToken!);
    } catch (_) {
      return {};
    }
  }

  String? get userEmail => payload['sub'] as String?;
  String? get userId => payload['id'] as String?;

  /// Clear token from memory and storage (logout).
  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
