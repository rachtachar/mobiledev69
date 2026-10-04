import 'package:dio/dio.dart';
import 'constants.dart';

/// Stateless Network Client using Dio (Week 13 Data Layer Architecture).
/// Automatically injects Bearer token in headers and handles timeouts.
class ApiClient {
  ApiClient({String? baseUrl, this._authToken})
      : _baseUrl = baseUrl ?? AppConstants.apiBaseUrl {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (_authToken != null && _authToken.isNotEmpty)
            'Authorization': 'Bearer $_authToken',
        },
      ),
    );
  }

  final String _baseUrl;
  final String? _authToken;
  late final Dio _dio;

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;

  /// Creates a new copy with an updated auth token.
  ApiClient copyWithToken(String? token) {
    return ApiClient(baseUrl: _baseUrl, authToken: token);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response?.data;
      if (data is Map && data.containsKey('error')) {
        return Exception(data['error']);
      }
      if (data is Map && data.containsKey('detail')) {
        return Exception(data['detail']);
      }
      if (data is Map && data.containsKey('error_description')) {
        return Exception(data['error_description']);
      }
      return Exception('ข้อผิดพลาดจากเซิร์ฟเวอร์ (${error.response?.statusCode})');
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('การเชื่อมต่อหมดเวลา กรุณาลองใหม่อีกครั้ง');
    }
    return Exception('ไม่สามารถเชื่อมต่อเซิร์ฟเวอร์ได้: ${error.message}');
  }
}
