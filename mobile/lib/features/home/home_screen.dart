import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Çıkış yap',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              user.when(
                loading: () => const LinearProgressIndicator(),
                error: (error, _) => Text('Bilgilerin yüklenemedi: $error'),
                data: (profile) => Text(
                  'Merhaba ${profile.displayName.split(' ').first} 👋',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bu akşam ne pişiriyoruz?',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🧊', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 12),
                    Text(
                      'Buzdolabın henüz boş',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Yakında evdeki malzemelerini buraya ekleyebileceksin.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
