import 'package:dio/dio.dart';
import 'dio_client.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.tokenProvider,
    this.onUnauthorized,
  });

  static const String skipAuthKey = 'skipAuth';
  static const String skipUnauthorizedHandlerKey = 'skipUnauthorizedHandler';

  final TokenProvider tokenProvider;
  final UnauthorizedHandler? onUnauthorized;
  bool _isHandlingUnauthorized = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final shouldSkipAuth = options.extra[skipAuthKey] == true;
    final token = shouldSkipAuth ? null : await tokenProvider();
    if (token != null &&
        token.isNotEmpty &&
        !options.headers.containsKey('Authorization')) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldHandleUnauthorized = err.response?.statusCode == 401 &&
        err.requestOptions.extra[skipUnauthorizedHandlerKey] != true &&
        onUnauthorized != null &&
        !_isHandlingUnauthorized;

    if (shouldHandleUnauthorized) {
      _isHandlingUnauthorized = true;
      try {
        await onUnauthorized!.call();
      } finally {
        _isHandlingUnauthorized = false;
      }
    }

    handler.next(err);
  }
}
