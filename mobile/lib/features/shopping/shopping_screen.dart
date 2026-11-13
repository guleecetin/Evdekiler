import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import 'shopping_repository.dart';

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final items = ref.watch(shoppingItemsProvider);
    final pendingCount = items.maybeWhen(
      data: (l) => l.where((i) => !i.isPurchased).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(shoppingItemsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                'Alışveriş listem 🛒',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pendingCount == 0
                    ? 'Alınacak bir şey yok'
                    : '$pendingCount ürün alınacak',
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              items.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Liste yüklenemedi: $e'),
                data: (list) =>
                    list.isEmpty ? const _EmptyList() : _ItemList(list: list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({required this.list});

  final List<ShoppingItem> list;

  @override
  Widget build(BuildContext context) {
    final pending = list.where((i) => !i.isPurchased).toList();
    final done = list.where((i) => i.isPurchased).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final i in pending) _ShoppingTile(item: i),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(
            'Son alınanlar',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          for (final i in done) _ShoppingTile(item: i),
        ],
      ],
    );
  }
}

class _ShoppingTile extends ConsumerWidget {
  const _ShoppingTile({required this.item});

  final ShoppingItem item;

  Future<void> _purchase(BuildContext context, WidgetRef ref) async {
    // Gecikmeli yenileme için uygulama genelindeki container'ı al
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(shoppingRepositoryProvider).purchase(item.id);
      ref.invalidate(shoppingItemsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('${item.name} buzdolabına ekleniyor 🧊')),
      );
      // Pantry olayı RabbitMQ'dan birkaç yüz milisaniyede işler (eventual consistency)
      Future.delayed(
        const Duration(milliseconds: 1500),
        () => container.invalidate(pantryItemsProvider),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _delete(WidgetRef ref) async {
    await ref.read(shoppingRepositoryProvider).delete(item.id);
    ref.invalidate(shoppingItemsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = item.isPurchased;

    return GestureDetector(
      onTap: done ? null : () => _purchase(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
        decoration: BoxDecoration(
          color: done ? Colors.white.withValues(alpha: 0.6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? AppColors.basil : Colors.transparent,
                border: Border.all(color: AppColors.basil, width: 2),
              ),
              child: done
                  ? const Icon(
                      Icons.check_rounded,
                      size: 18,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: done ? Colors.grey : AppColors.ink,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    done
                        ? 'Buzdolabına eklendi'
                        : formatQuantity(item.quantity, item.unit),
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            if (!done)
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.grey),
                onPressed: () => _delete(ref),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text('🧺', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text(
            'Listen boş',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text(
            'Bir tarifin detayında "Eksikleri listeye ekle"\nbutonuna basarak başlayabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
