import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/token_storage.dart';
import 'auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    _restoreSession();
    return AuthStatus.unknown;
  }

  Future<void> _restoreSession() async {
    final refreshToken = await ref
        .read(tokenStorageProvider)
        .readRefreshToken();
    state = refreshToken == null
        ? AuthStatus.unauthenticated
        : AuthStatus.authenticated;
  }

  Future<void> login({required String email, required String password}) async {
    await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);
    state = AuthStatus.authenticated;
  }

  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .register(displayName: displayName, email: email, password: password);
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = AuthStatus.unauthenticated;
  }

  // Refresh token da geçersizse interceptor bunu çağırır
  void sessionExpired() => state = AuthStatus.unauthenticated;
}

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

final currentUserProvider = FutureProvider<UserProfile>((ref) {
  // Oturum durumu değişince kullanıcı bilgisini baştan yükle
  ref.watch(authControllerProvider);
  return ref.watch(authRepositoryProvider).me();
});
