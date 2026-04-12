import 'package:dio/dio.dart';
import 'api_interceptor.dart';
import '../constants/api_constants.dart';

typedef TokenProvider = Future<String?> Function();
typedef UnauthorizedHandler = Future<void> Function();

Dio createDioClient({
  required TokenProvider tokenProvider,
  UnauthorizedHandler? onUnauthorized,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(
    AuthInterceptor(
      tokenProvider: tokenProvider,
      onUnauthorized: onUnauthorized,
    ),
  );
  return dio;
}
