import 'package:dio/dio.dart';

import '../config.dart';
import 'token_storage.dart';

/// A user-facing API error with a friendly message.
class ApiException implements Exception {
  ApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps a [Dio] instance configured for the Journal API: attaches the
/// JWT access token and transparently refreshes on 401. Modelled on
/// Pable's client so the two apps share lifecycle code.
class ApiClient {
  ApiClient({TokenStorage? storage}) : tokens = storage ?? TokenStorage() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Content-Type': 'application/json'},
    ));
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onError: _onError,
    ));
  }

  late final Dio dio;
  final TokenStorage tokens;

  static const _noAuthPaths = {
    '/auth/token/',
    '/auth/token/refresh/',
    '/traders/register/',
  };

  bool _refreshing = false;

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_noAuthPaths.contains(options.path)) {
      final access = await tokens.accessToken;
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = _noAuthPaths.contains(path);
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (err.response?.statusCode == 401 &&
        !isAuthEndpoint &&
        !alreadyRetried &&
        !_refreshing) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        final opts = err.requestOptions;
        opts.extra['retried'] = true;
        try {
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
      await tokens.clear();
    }
    handler.next(err);
  }

  Future<bool> _tryRefresh() async {
    final refresh = await tokens.refreshToken;
    if (refresh == null) return false;
    _refreshing = true;
    try {
      final res =
          await dio.post('/auth/token/refresh/', data: {'refresh': refresh});
      final data = res.data;
      if (res.statusCode == 200 && data is Map && data['access'] != null) {
        await tokens.saveAccess(data['access'] as String);
        return true;
      }
      return false;
    } on DioException {
      return false;
    } finally {
      _refreshing = false;
    }
  }
}

/// Pulls a readable message out of a DRF error body.
String? messageFromDrf(dynamic data) {
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String) return detail;
    for (final value in data.values) {
      if (value is List && value.isNotEmpty) return value.first.toString();
      if (value is String) return value;
    }
  }
  return null;
}

ApiException toApiException(DioException e, {String? fallback}) {
  final message = messageFromDrf(e.response?.data);
  if (message != null) return ApiException(message);
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.connectionError:
      return ApiException(
          'Network error. Check your connection and try again.');
    default:
      return ApiException(fallback ?? 'Something went wrong. Please try again.');
  }
}
