import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/oidc_helper.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

/// AuthViewModel managing authentication state and actions (Week 11 & 15 MVVM).
class AuthViewModel extends ChangeNotifier {
  static const String _prefKeyVerifier = 'splitsquad_oidc_verifier';
  static const String _prefKeyState = 'splitsquad_oidc_state';

  final AuthRepository authRepository;

  bool _isLoading = false;
  bool _isRestoring = true;
  String? _errorMessage;

  AuthViewModel({required this.authRepository}) {
    _init();
  }

  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => authRepository.currentUser;
  String? get accessToken => authRepository.accessToken;
  bool get isAuthenticated => authRepository.isAuthenticated;

  Future<void> _init() async {
    _isRestoring = true;
    notifyListeners();

    // 1. Try to handle OIDC callback if redirected back with ?code=
    final handledOidc = await handleOidcCallbackIfPresent();

    // 2. If not from OIDC callback, restore existing persistent session
    if (!handledOidc) {
      await authRepository.restoreSession();
    }

    _isRestoring = false;
    notifyListeners();
  }

  /// Checks if the current browser URL contains an authorization code from OIDC Provider
  Future<bool> handleOidcCallbackIfPresent() async {
    if (!kIsWeb) return false;

    try {
      final currentUri = Uri.base;
      final code = currentUri.queryParameters['code'];
      if (code == null || code.isEmpty) {
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final codeVerifier = prefs.getString(_prefKeyVerifier) ?? '';

      // Determine the redirect URI that was used
      final redirectUri = '${currentUri.origin}/callback';

      final result = await authRepository.loginWithOidcCode(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );

      // Clean up PKCE verifier
      await prefs.remove(_prefKeyVerifier);
      await prefs.remove(_prefKeyState);

      _isLoading = false;
      if (result.isSuccess) {
        _errorMessage = null;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ??
            'ไม่สามารถยืนยันตัวตนผ่าน OIDC Authorization Code ได้';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'OIDC Callback Error: $e';
      notifyListeners();
      return false;
    }
  }

  /// Initiates the standard Authorization Code Flow with PKCE
  Future<void> startOidcWebLogin() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final verifier = OidcHelper.generateCodeVerifier();
      final challenge = OidcHelper.generateCodeChallenge(verifier);
      final state = OidcHelper.generateCodeVerifier(16);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyVerifier, verifier);
      await prefs.setString(_prefKeyState, state);

      final redirectUri = kIsWeb
          ? '${Uri.base.origin}/callback'
          : 'http://localhost:50000/callback';

      final authUrl = OidcHelper.buildAuthorizationUrl(
        redirectUri: redirectUri,
        state: state,
        codeChallenge: challenge,
      );

      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          webOnlyWindowName: '_self', // Seamlessly navigate in same tab
        );
      } else {
        throw Exception('ไม่สามารถเปิดหน้าล็อกอิน OIDC ได้');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }

  /// Direct credentials login
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await authRepository.login(username, password);

    _isLoading = false;
    if (result.isSuccess) {
      _errorMessage = null;
      notifyListeners();
      return true;
    } else {
      _errorMessage = result.errorOrNull?.toString().replaceAll('Exception: ', '') ?? 'เข้าสู่ระบบไม่สำเร็จ';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await authRepository.logout();
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }
}
