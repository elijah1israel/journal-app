import 'package:dio/dio.dart';

import '../models/auth_user.dart';
import 'api_client.dart';
import 'token_storage.dart';

/// Auth wrapper for the Journal API: register, login, refresh, logout,
/// and the current-user lookup.
class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Dio get _dio => _client.dio;
  TokenStorage get tokens => _client.tokens;

  Future<AuthUser> login(String email, String password) async {
    try {
      final res = await _dio
          .post('/auth/token/', data: {'email': email, 'password': password});
      final data = res.data;
      if (data is Map && data['access'] != null && data['refresh'] != null) {
        await tokens.saveTokens(
          access: data['access'] as String,
          refresh: data['refresh'] as String,
        );
        return await me();
      }
      throw ApiException('Unexpected response from the server.');
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Invalid email or password.');
    }
  }

  Future<AuthUser> register({
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    required String confirmPassword,
    String? experienceLevel,
  }) async {
    try {
      await _dio.post('/traders/register/', data: {
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'password': password,
        'confirm_password': confirmPassword,
        if (experienceLevel != null) 'experience_level': experienceLevel,
      });
      // Backend doesn't auto-issue tokens on register — log straight in
      // with the credentials we just used so the user lands on the app
      // instead of a "now sign in" screen.
      return await login(email, password);
    } on DioException catch (e) {
      throw toApiException(e, fallback: 'Could not create your account.');
    }
  }

  Future<AuthUser> me() async {
    try {
      final res = await _dio.get('/traders/me/');
      return AuthUser.fromJson(Map<String, dynamic>.from(res.data as Map));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<void> logout() async {
    await tokens.clear();
  }
}
