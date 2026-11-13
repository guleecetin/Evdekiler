import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_image.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import 'shopping_repository.dart';

// Fotoğrafı siyah-beyaz yapan renk filtresi (alınan ürünler için)
const _greyscale = ColorFilter.matrix(<double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
]);

class ShoppingScreen extends ConsumerWidget {
  const ShoppingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingItemsProvider);
    final pendingCount = items.maybeWhen(
      data: (l) => l.where((i) => !i.isPurchased).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(shoppingItemsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              const Text(
                'Alışveriş',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                pendingCount == 0
                    ? 'Listende alınacak bir şey yok'
                    : '$pendingCount ürün alınacak',
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 12),
              items.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Liste yüklenemedi: $e'),
                data: (list) => _Content(list: list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.list});

  final List<ShoppingItem> list;

  @override
  Widget build(BuildContext context) {
    final pending = list.where((i) => !i.isPurchased).toList();
    final done = list.where((i) => i.isPurchased).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (pending.isEmpty)
          const _EmptyState()
        else ...[
          const SizedBox(height: 8),
          for (var i = 0; i < pending.length; i++) ...[
            _ShoppingRow(item: pending[i]),
            if (i < pending.length - 1) const Divider(height: 1),
          ],
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: 36),
          const Text(
            'Son alınanlar',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Buzdolabına otomatik eklendi',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < done.length; i++) ...[
            _ShoppingRow(item: done[i]),
            if (i < done.length - 1) const Divider(height: 1),
          ],
        ],
      ],
    );
  }
}

class _ShoppingRow extends ConsumerWidget {
  const _ShoppingRow({required this.item});

  final ShoppingItem item;

  Future<void> _purchase(BuildContext context, WidgetRef ref) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(shoppingRepositoryProvider).purchase(item.id);
      ref.invalidate(shoppingItemsProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('${item.name} buzdolabına ekleniyor 🧊')),
      );
      // Pantry olayı RabbitMQ'dan biraz sonra işler (eventual consistency)
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
    final photo = AppImage('/images/ingredients/${item.ingredientId}.jpg');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 58,
              height: 58,
              child: done
                  ? Opacity(
                      opacity: 0.5,
                      child: ColorFiltered(
                        colorFilter: _greyscale,
                        child: photo,
                      ),
                    )
                  : photo,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.muted : AppColors.ink,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Buzdolabına eklendi ✓'
                      : formatQuantity(item.quantity, item.unit),
                  style: TextStyle(
                    fontSize: 13,
                    color: done ? AppColors.basil : AppColors.muted,
                    fontWeight: done ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (!done)
            IconButton(
              tooltip: 'Listeden çıkar',
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.muted,
              ),
              onPressed: () => _delete(ref),
            ),
          _CheckButton(
            checked: done,
            onTap: done ? null : () => _purchase(context, ref),
          ),
        ],
      ),
    );
  }
}

class _CheckButton extends StatelessWidget {
  const _CheckButton({required this.checked, required this.onTap});

  final bool checked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? AppColors.basil : Colors.white,
          border: Border.all(
            color: checked ? AppColors.basil : const Color(0xFFCCCCCC),
            width: 1.5,
          ),
        ),
        child: checked
            ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
            : null,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: const Text('🧺', style: TextStyle(fontSize: 52)),
          ),
          const SizedBox(height: 20),
          const Text(
            'Listen tertemiz',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Bir tarifin eksiklerini tek dokunuşla\nburaya ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.go('/recipes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
              side: const BorderSide(color: AppColors.ink),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            child: const Text(
              'Tariflere göz at',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
