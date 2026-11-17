import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_background.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_loader.dart';
import '../../core/widgets/page_header.dart';
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
    final list = items.maybeWhen(
      data: (l) => l,
      orElse: () => const <ShoppingItem>[],
    );
    final pendingCount = list.where((i) => !i.isPurchased).length;
    final doneCount = list.length - pendingCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: RefreshIndicator(
            color: Brand.forest,
            onRefresh: () => ref.refresh(shoppingItemsProvider.future),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                PageHeader(
                  title: 'Alışveriş',
                  subtitle: 'Eksikler tek listede',
                  icon: Icons.shopping_basket_rounded,
                  chips: [
                    if (pendingCount > 0)
                      HeaderChip(
                        icon: Icons.radio_button_unchecked_rounded,
                        text: '$pendingCount alınacak',
                      ),
                    if (doneCount > 0)
                      HeaderChip(
                        icon: Icons.check_rounded,
                        text: '$doneCount alındı',
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: items.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(top: 60),
                      child: AppLoader(
                        compact: true,
                        message: 'Liste hazırlanıyor…',
                      ),
                    ),
                    error: (e, _) => Text('Liste yüklenemedi: $e'),
                    data: (list) => _Content(list: list),
                  ),
                ),
              ],
            ),
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
        if (pending.isEmpty) const _EmptyState() else _ListCard(items: pending),
        if (done.isNotEmpty) ...[
          const SizedBox(height: 28),
          Text('Son alınanlar', style: brandDisplay(19)),
          const Text(
            'Buzdolabına otomatik eklendi',
            style: TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 10),
          _ListCard(items: done),
        ],
      ],
    );
  }
}

// Satırları tek beyaz kartta toplar
class _ListCard extends StatelessWidget {
  const _ListCard({required this.items});

  final List<ShoppingItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Brand.forest.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            _ShoppingRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.line),
          ],
        ],
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 50,
              height: 50,
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: done ? AppColors.muted : Brand.forest,
                    decoration: done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  done
                      ? 'Buzdolabına eklendi ✓'
                      : formatQuantity(item.quantity, item.unit),
                  style: TextStyle(
                    fontSize: 12.5,
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
                size: 19,
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: checked ? Brand.forest : Colors.white,
          border: Border.all(
            color: checked ? Brand.forest : const Color(0xFFCFC8BA),
            width: 1.5,
          ),
        ),
        child: checked
            ? const Icon(Icons.check_rounded, size: 18, color: Brand.gold)
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
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Container(
            width: 104,
            height: 104,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Brand.forest.withValues(alpha: 0.08),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Text('🧺', style: TextStyle(fontSize: 46)),
          ),
          const SizedBox(height: 18),
          Text('Listen tertemiz', style: brandDisplay(20)),
          const SizedBox(height: 6),
          const Text(
            'Bir tarifin eksiklerini tek dokunuşla\nburaya ekleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              height: 1.4,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.go('/recipes'),
            style: FilledButton.styleFrom(
              backgroundColor: Brand.forest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            ),
            icon: const Icon(
              Icons.restaurant_menu_rounded,
              color: Brand.gold,
              size: 18,
            ),
            label: const Text(
              'Tariflere göz at',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
