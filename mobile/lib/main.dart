import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
  runApp(const ProviderScope(child: EvdekilerApp()));
}

class EvdekilerApp extends ConsumerWidget {
  const EvdekilerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Evdekiler',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
