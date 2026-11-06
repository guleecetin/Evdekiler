import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_controller.dart';
import '../storage/token_storage.dart';
import 'api_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(tokenStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );

  // Refresh isteği için ayrı, interceptor'sız bir Dio.
  // Aynı Dio'yu kullansaydık refresh'in kendisi de bu interceptor'a girerdi.
  final refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      contentType: Headers.jsonContentType,
    ),
  );

  // O an devam eden bir refresh varsa burada tutuluyor
  Future<bool>? refreshInProgress;

  Future<bool> refreshTokens() async {
    final refreshToken = await storage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final response = await refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      await storage.save(
        accessToken: response.data!['accessToken'] as String,
        refreshToken: response.data!['refreshToken'] as String,
      );
      return true;
    } on DioException {
      return false;
    }
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      // 1. Her isteğe token ekle
      onRequest: (options, handler) async {
        final token = await storage.readAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },

      // 2. 401 gelirse token'ı yenile ve isteği tekrar gönder
      onError: (error, handler) async {
        final isUnauthorized = error.response?.statusCode == 401;
        final isAuthEndpoint = error.requestOptions.path.startsWith(
          '/api/auth/',
        );
        final alreadyRetried = error.requestOptions.extra['retried'] == true;

        if (!isUnauthorized || isAuthEndpoint || alreadyRetried) {
          return handler.next(error);
        }

        // Devam eden bir refresh varsa ona katıl, yoksa yenisini başlat
        refreshInProgress ??= refreshTokens().whenComplete(
          () => refreshInProgress = null,
        );
        final refreshed = await refreshInProgress!;

        if (!refreshed) {
          await storage.clear();
          ref.read(authControllerProvider.notifier).sessionExpired();
          return handler.next(error);
        }

        // Aynı isteği yeni token'la, "tekrar denendi" işaretiyle gönder
        final options = error.requestOptions;
        options.extra['retried'] = true;
        options.headers['Authorization'] =
            'Bearer ${await storage.readAccessToken()}';

        try {
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      },
    ),
  );

  return dio;
});
