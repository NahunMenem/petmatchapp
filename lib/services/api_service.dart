import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isRefreshRequest =
              error.requestOptions.path == ApiConstants.refreshToken;
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (error.response?.statusCode == 401 &&
              !isRefreshRequest &&
              !alreadyRetried) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final token = await StorageService.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              error.requestOptions.extra['retried'] = true;
              final response = await _dio.fetch(error.requestOptions);
              handler.resolve(response);
              return;
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final authDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await authDio.post(
        ApiConstants.refreshToken,
        data: {'refresh_token': refreshToken},
      );

      await StorageService.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      return true;
    } catch (_) {
      await StorageService.clearAll();
      return false;
    }
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) =>
      _dio.get(path, queryParameters: queryParams);

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response> patch(String path, {dynamic data}) =>
      _dio.patch(path, data: data);

  Future<Response> delete(String path) => _dio.delete(path);

  Future<Response> uploadFile(
    String path,
    String filePath, {
    String fieldName = 'file',
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath),
    });
    return _dio.post(
      path,
      data: formData,
      options: Options(contentType: Headers.multipartFormDataContentType),
    );
  }
}
