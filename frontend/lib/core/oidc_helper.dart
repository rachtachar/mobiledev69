import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'constants.dart';

class OidcHelper {
  static const String charset =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';

  /// Generates a cryptographically secure random string for PKCE code_verifier.
  static String generateCodeVerifier([int length = 64]) {
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Calculates the S256 code_challenge from code_verifier.
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = ascii.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  /// Constructs the OIDC Authorization URL for Authorization Code Flow with PKCE.
  static String buildAuthorizationUrl({
    required String redirectUri,
    required String state,
    required String codeChallenge,
  }) {
    final baseUrl = AppConstants.apiBaseUrl;
    final params = {
      'response_type': 'code',
      'client_id': AppConstants.oidcClientId,
      'redirect_uri': redirectUri,
      'scope': 'openid profile email',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
      'prompt': 'login',
    };

    final queryString = params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$baseUrl/openid/authorize/?$queryString';
  }
}
