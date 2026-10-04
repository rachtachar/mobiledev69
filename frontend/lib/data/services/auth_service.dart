import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../models/user_model.dart';

class AuthResponse {
  final String accessToken;
  final String? idToken;
  final UserModel user;

  const AuthResponse({
    required this.accessToken,
    this.idToken,
    required this.user,
  });
}

class OidcAuthService {
  final ApiClient apiClient;

  OidcAuthService({required this.apiClient});

  /// Authenticate with Username & Password and receive an OIDC Access Token
  Future<AuthResponse> login(String username, String password) async {
    final response = await apiClient.post(
      '/api/auth/token/',
      data: {
        'username': username,
        'password': password,
        'client_id': AppConstants.oidcClientId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'].toString();
    final rawIdToken = data['id_token'];
    final idToken = rawIdToken is String ? rawIdToken : rawIdToken?.toString();
    final userJson = data['user'] as Map<String, dynamic>;

    return AuthResponse(
      accessToken: token,
      idToken: idToken,
      user: UserModel.fromJson(userJson),
    );
  }

  /// Exchange Authorization Code with PKCE code_verifier for Access Token
  Future<AuthResponse> exchangeCodeForToken({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final response = await apiClient.post(
      '/openid/token/',
      data: {
        'client_id': AppConstants.oidcClientId,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'code_verifier': codeVerifier,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    final data = response.data as Map<String, dynamic>;
    final token = data['access_token'].toString();
    final rawIdToken = data['id_token'];
    final idToken = rawIdToken is String ? rawIdToken : rawIdToken?.toString();

    // Fetch user profile from OIDC userinfo endpoint
    final user = await fetchUserInfo(token);

    return AuthResponse(
      accessToken: token,
      idToken: idToken,
      user: user,
    );
  }

  /// Call the standard OIDC UserInfo endpoint
  Future<UserModel> fetchUserInfo(String token) async {
    final authedClient = apiClient.copyWithToken(token);
    final response = await authedClient.get('/openid/userinfo/');
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data);
  }
}
