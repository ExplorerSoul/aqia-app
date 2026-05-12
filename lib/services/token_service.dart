import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// Singleton that manages the JWT token lifecycle.
class TokenService {
  TokenService._();
  static final TokenService instance = TokenService._();

  static const _key = 'aqia_token';
  static const _nameKey = 'aqia_user_name';

  String? _cachedToken;
  String? _cachedName;

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  /// Save the user's display name separately (JWT doesn't include it).
  Future<void> saveName(String name) async {
    _cachedName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
  }

  Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_key);
    _cachedName = prefs.getString(_nameKey);
    return _cachedToken;
  }

  String? get token => _cachedToken;

  Map<String, String> get authHeader =>
      _cachedToken != null ? {'Authorization': 'Bearer $_cachedToken'} : {};

  bool get isValid {
    if (_cachedToken == null) return false;
    try {
      return !JwtDecoder.isExpired(_cachedToken!);
    } catch (_) {
      return false;
    }
  }

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

  /// Returns the stored display name, or derives one from email.
  String get displayName {
    if (_cachedName != null && _cachedName!.isNotEmpty) return _cachedName!;
    final email = userEmail ?? '';
    return email.contains('@') ? email.split('@')[0] : email;
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    _cachedName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(_nameKey);
  }
}
