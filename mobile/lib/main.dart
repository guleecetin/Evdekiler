import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/theme.dart';
import 'features/auth/login_screen.dart';

void main() {
  runApp(const ProviderScope(child: EvdekilerApp()));
}

class EvdekilerApp extends StatelessWidget {
  const EvdekilerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Evdekiler',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      home: const LoginScreen(),
    );
  }
}
