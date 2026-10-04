import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/result.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

abstract class AuthRepository {
  UserModel? get currentUser;
  String? get accessToken;
  bool get isAuthenticated;

  Future<Result<UserModel>> login(String username, String password);
  Future<Result<UserModel>> loginWithOidcCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  });
  Future<bool> restoreSession();
  Future<void> logout();
}

class AuthRepositoryRemote implements AuthRepository {
  static const String _keyToken = 'splitsquad_access_token';
  static const String _keyUser = 'splitsquad_user_json';

  final OidcAuthService authService;
  UserModel? _currentUser;
  String? _accessToken;

  AuthRepositoryRemote({required this.authService});

  @override
  UserModel? get currentUser => _currentUser;

  @override
  String? get accessToken => _accessToken;

  @override
  bool get isAuthenticated => _accessToken != null && _currentUser != null;

  @override
  Future<Result<UserModel>> login(String username, String password) async {
    try {
      final response = await authService.login(username, password);
      _accessToken = response.accessToken;
      _currentUser = response.user;
      await _persistSession(_accessToken!, _currentUser!);
      return Success(_currentUser!);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<Result<UserModel>> loginWithOidcCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    try {
      final response = await authService.exchangeCodeForToken(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );
      _accessToken = response.accessToken;
      _currentUser = response.user;
      await _persistSession(_accessToken!, _currentUser!);
      return Success(_currentUser!);
    } on Exception catch (e, st) {
      return Failure(e, st);
    } catch (e, st) {
      return Failure(Exception(e.toString()), st);
    }
  }

  @override
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userStr = prefs.getString(_keyUser);
      if (token != null && token.isNotEmpty && userStr != null && userStr.isNotEmpty) {
        _accessToken = token;
        _currentUser = UserModel.fromJson(jsonDecode(userStr) as Map<String, dynamic>);
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<void> logout() async {
    _accessToken = null;
    _currentUser = null;
    try {
      await authService.logout();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
  }

  Future<void> _persistSession(String token, UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, token);
      await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }
}
