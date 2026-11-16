import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../core/widgets/app_image.dart';
import '../auth/auth_controller.dart';
import '../pantry/add_item_sheet.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';
import '../receipts/receipt_reader.dart';
import '../recipes/recipe_models.dart';
import '../recipes/recipe_repository.dart';

const _categoryLabel = {
  'Vegetable': 'Sebze',
  'Fruit': 'Meyve',
  'Dairy': 'Süt & Yumurta',
  'Meat': 'Et & Tavuk',
  'Grain': 'Tahıl',
  'Legume': 'Bakliyat',
  'Spice': 'Baharat',
  'Other': 'Diğer',
};

(String, Color) expiryInfo(int days) => switch (days) {
  < 0 => ('Süresi geçti', const Color(0xFFC13515)),
  0 => ('Bugün', AppColors.tomato),
  1 => ('Yarın', AppColors.tomato),
  <= 3 => ('$days gün', AppColors.tomato),
  _ => ('$days gün', AppColors.basil),
};

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _category;

  void _openAddSheet() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => const AddItemSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final name = ref
        .watch(currentUserProvider)
        .maybeWhen(
          data: (p) => p.displayName.split(' ').first,
          orElse: () => '',
        );
    final items = ref.watch(pantryItemsProvider);
    final suggestions = ref
        .watch(recipeSuggestionsProvider)
        .maybeWhen(data: (l) => l, orElse: () => const <RecipeSuggestion>[]);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () => ref.refresh(pantryItemsProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _Header(
                    name: name,
                    onLogout: () =>
                        ref.read(authControllerProvider.notifier).logout(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AddPill(
                    onTap: _openAddSheet,
                    onScan: () => startReceiptScan(context, ref),
                  ),
                ),
                ...items.when<List<Widget>>(
                  loading: () => const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                  error: (e, _) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('$e'),
                      ),
                    ),
                  ],
                  data: (list) => _content(list, suggestions),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(
    List<PantryItem> list,
    List<RecipeSuggestion> suggestions,
  ) {
    if (list.isEmpty) {
      return [SliverToBoxAdapter(child: _EmptyFridge(onAdd: _openAddSheet))];
    }

    final urgent = list.where((i) => i.isUrgent).toList();
    final categories = list.map((i) => i.category).toSet().toList();
    final filtered = _category == null
        ? list
        : list.where((i) => i.category == _category).toList();

    return [
      if (suggestions.isNotEmpty) ...[
        SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Bu akşam ne pişirsen?',
            action: 'Tümü',
            onAction: () => context.go('/recipes'),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: min(6, suggestions.length),
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _RecipeMiniCard(recipe: suggestions[i]),
            ),
          ),
        ),
      ],
      if (urgent.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: _SectionHeader(
            title: 'Önce bunları kullan',
            subtitle: 'Bozulmadan değerlendir',
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 88,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: urgent.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _UrgentCard(item: urgent[i]),
            ),
          ),
        ),
      ],
      SliverToBoxAdapter(
        child: _SectionHeader(
          title: 'Buzdolabında',
          subtitle: '${list.length} ürün',
        ),
      ),
      SliverToBoxAdapter(
        child: _CategoryTabs(
          categories: categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _ItemCard(item: filtered[i]),
            childCount: filtered.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 20,
            childAspectRatio: 0.78,
          ),
        ),
      ),
    ];
  }
}

// ─── Üst kısım ──────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.onLogout});

  final String name;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Merhaba 👋' : 'Merhaba $name 👋',
                  style: const TextStyle(color: AppColors.muted, fontSize: 15),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Buzdolabın',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (_) => onLogout(),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Çıkış yap'),
                  ],
                ),
              ),
            ],
            child: CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.ink,
              child: Text(
                name.isEmpty ? '?' : name[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPill extends StatelessWidget {
  const _AddPill({required this.onTap, required this.onScan});

  final VoidCallback onTap;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final shadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 60,
                padding: const EdgeInsets.only(left: 20, right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: AppColors.line),
                  boxShadow: shadow,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.ink),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Malzeme ekle',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'Domates, süt, yumurta…',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.basil,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Fiş okut
          GestureDetector(
            onTap: onScan,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.line),
                boxShadow: shadow,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.basil,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tarif şeridi ───────────────────────────────────────────

class _RecipeMiniCard extends StatelessWidget {
  const _RecipeMiniCard({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    final tag = 'home-${recipe.id}';
    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}?hero=$tag'),
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 160,
                  width: 200,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(recipe.imageUrl, fallbackEmoji: recipe.emoji),
                      if (recipe.isReady)
                        const Positioned(
                          top: 10,
                          left: 10,
                          child: _Badge('Hemen yapılabilir'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              recipe.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              recipe.isReady
                  ? '${recipe.prepMinutes} dk · Malzemeler evde'
                  : '${recipe.prepMinutes} dk · ${recipe.missing.length} eksik',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ─── Acil ürünler ───────────────────────────────────────────

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.item});

  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final (label, color) = expiryInfo(item.daysLeft!);
    return Container(
      width: 240,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 66,
              height: 66,
              child: AppImage(item.imageUrl, fallbackEmoji: item.emoji),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ingredientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  formatQuantity(item.quantity, item.unit),
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Kategori sekmeleri ─────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final tabs = <(String?, String)>[
      (null, 'Tümü'),
      for (final c in categories) (c, _categoryLabel[c] ?? c),
    ];

    return Container(
      height: 42,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final (value, label) in tabs)
            GestureDetector(
              onTap: () => onSelected(value),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: selected == value
                            ? AppColors.ink
                            : AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2,
                      width: selected == value ? 28 : 0,
                      color: AppColors.ink,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Ürün kartı ─────────────────────────────────────────────

class _ItemCard extends ConsumerWidget {
  const _ItemCard({required this.item});

  final PantryItem item;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(pantryRepositoryProvider).deleteItem(item.id);
      ref.invalidate(pantryItemsProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppImage(item.imageUrl, fallbackEmoji: item.emoji),
              ),
              if (item.daysLeft != null)
                Positioned(
                  top: 8,
                  left: 8,
                  child: _ExpiryPill(days: item.daysLeft!),
                ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_horiz_rounded, size: 18),
                      onSelected: (_) => _delete(context, ref),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded),
                              SizedBox(width: 12),
                              Text('Sil'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          item.ingredientName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        Text(
          formatQuantity(item.quantity, item.unit),
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final (label, color) = expiryInfo(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _EmptyFridge extends StatelessWidget {
  const _EmptyFridge({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
      child: Column(
        children: [
          const Text('🧊', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Buzdolabın bomboş',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Evdeki malzemelerini ekle,\nsana ne pişireceğini söyleyelim.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: onAdd, child: const Text('İlk ürünü ekle')),
        ],
      ),
    );
  }
}
