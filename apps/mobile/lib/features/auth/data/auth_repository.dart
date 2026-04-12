import 'package:dio/dio.dart';

import '../../../core/network/api_interceptor.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.rol,
  });

  final String id;
  final String email;
  final String rol;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _requireString(json['id'], field: 'id'),
      email: _requireString(json['email'], field: 'email'),
      rol: _requireString(json['rol'], field: 'rol'),
    );
  }
}

class AuthRepository {
  final Dio _dio;

  const AuthRepository(this._dio);

  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        options: Options(
          extra: {
            AuthInterceptor.skipAuthKey: true,
            AuthInterceptor.skipUnauthorizedHandlerKey: true,
          },
        ),
      );

      final data = _asMap(response.data);
      return _requireString(data['access_token'], field: 'access_token');
    } on DioException catch (error) {
      throw AuthException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo iniciar sesion.',
        ),
      );
    }
  }

  Future<AuthUser> getMe(String token) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return AuthUser.fromJson(_asMap(response.data));
    } on DioException catch (error) {
      throw AuthException(
        _extractErrorMessage(
          error,
          fallback: 'No se pudo recuperar la sesion.',
        ),
      );
    }
  }

  static String _extractErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      return data['detail'].toString();
    }
    if (data is String && data.trim().isNotEmpty) {
      return data;
    }
    return fallback;
  }
}

Map<String, dynamic> _asMap(Object? data) {
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  throw const AuthException('Respuesta invalida del servidor.');
}

String _requireString(Object? value, {required String field}) {
  if (value is String && value.isNotEmpty) {
    return value;
  }
  throw AuthException('Falta el campo requerido: $field.');
}
