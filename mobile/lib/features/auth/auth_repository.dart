import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/token_storage.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
  });

  final String id;
  final String email;
  final String displayName;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
  );
}

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  Future<void> login({required String email, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      );
      final data = response.data!;
      await _tokens.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post(
        '/api/auth/register',
        data: {
          'displayName': displayName,
          'email': email,
          'password': password,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
    await login(email: email, password: password);
  }

  Future<void> logout() async {
    final refreshToken = await _tokens.readRefreshToken();
    try {
      if (refreshToken != null) {
        await _dio.post(
          '/api/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } on DioException {
      // Sunucuya ulaşılamasa bile kullanıcıyı çıkarıyoruz
    } finally {
      await _tokens.clear();
    }
  }

  Future<UserProfile> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/api/users/me');
      return UserProfile.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      AuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
