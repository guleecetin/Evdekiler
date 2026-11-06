import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/home/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatus = ValueNotifier(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => authStatus.value = next);
  ref.onDispose(authStatus.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authStatus,
    redirect: (context, state) {
      final status = authStatus.value;
      final location = state.matchedLocation;
      final onAuthPage = location == '/login' || location == '/register';

      switch (status) {
        case AuthStatus.unknown:
          return location == '/splash' ? null : '/splash';
        case AuthStatus.unauthenticated:
          return onAuthPage ? null : '/login';
        case AuthStatus.authenticated:
          return (onAuthPage || location == '/splash') ? '/home' : null;
      }
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ],
  );
});
