import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../auth/auth_controller.dart';
import '../pantry/add_item_sheet.dart';
import '../pantry/pantry_models.dart';
import '../pantry/pantry_repository.dart';

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

const _categoryIcon = {
  'Vegetable': '🥦',
  'Fruit': '🍎',
  'Dairy': '🥛',
  'Meat': '🍗',
  'Grain': '🌾',
  'Legume': '🫘',
  'Spice': '🧂',
  'Other': '🫙',
};

(String, Color) _expiryInfo(int days, ColorScheme c) => switch (days) {
  < 0 => ('Süresi geçti', c.error),
  0 => ('Bugün bitiyor', AppColors.tomato),
  1 => ('Yarın bitiyor', AppColors.tomato),
  <= 3 => ('$days gün kaldı', AppColors.tomato),
  _ => ('$days gün kaldı', AppColors.basil),
};

String _formatQuantity(PantryItem item) {
  final q = item.quantity == item.quantity.roundToDouble()
      ? item.quantity.toInt().toString()
      : item.quantity.toString().replaceAll('.', ',');
  return '$q ${item.unit.label}';
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _category; // null = Tümü

  void _openAddSheet() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColors.cream,
    builder: (_) => const AddItemSheet(),
  );

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(pantryItemsProvider);
    final user = ref.watch(currentUserProvider);
    final name = user.maybeWhen(
      data: (p) => p.displayName.split(' ').first,
      orElse: () => '',
    );
    final list = items.maybeWhen(
      data: (l) => l,
      orElse: () => const <PantryItem>[],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddSheet,
          backgroundColor: AppColors.tomato,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: (i) {
            if (i != 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Çok yakında geliyor 👀')),
              );
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.kitchen_outlined),
              selectedIcon: Icon(Icons.kitchen_rounded),
              label: 'Buzdolabım',
            ),
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Tarifler',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_basket_outlined),
              selectedIcon: Icon(Icons.shopping_basket_rounded),
              label: 'Alışveriş',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(pantryItemsProvider.future),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _Header(
                  name: name,
                  total: list.length,
                  urgent: list.where((i) => i.isUrgent).length,
                  onLogout: () =>
                      ref.read(authControllerProvider.notifier).logout(),
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
                      child: _ErrorBox(message: '$e'),
                    ),
                  ),
                ],
                data: _buildContent,
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildContent(List<PantryItem> list) {
    if (list.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyFridge(onAdd: _openAddSheet),
        ),
      ];
    }

    final urgent = list.where((i) => i.isUrgent).toList();
    final categories = list.map((i) => i.category).toSet().toList();
    final filtered = _category == null
        ? list
        : list.where((i) => i.category == _category).toList();

    return [
      if (urgent.isNotEmpty) ...[
        const SliverToBoxAdapter(
          child: _SectionTitle(
            title: 'Önce bunları kullan',
            subtitle: 'Bozulmadan değerlendir',
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 180,
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
        child: _SectionTitle(
          title: 'Buzdolabım',
          subtitle: '${list.length} ürün',
        ),
      ),
      SliverToBoxAdapter(
        child: _CategoryFilter(
          categories: categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
        sliver: SliverGrid(
          delegate: SliverChildBuilderDelegate(
            (_, i) => _ItemCard(item: filtered[i]),
            childCount: filtered.length,
          ),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: 180,
          ),
        ),
      ),
    ];
  }
}

// ─── Başlık alanı ───────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.total,
    required this.urgent,
    required this.onLogout,
  });

  final String name;
  final int total;
  final int urgent;
  final VoidCallback onLogout;

  String _today() {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final now = DateTime.now();
    return '${now.day} ${months[now.month - 1]}, ${days[now.weekday - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 12, 20, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.basil, AppColors.basilDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -16,
            top: 24,
            child: Transform.rotate(
              angle: 0.35,
              child: const Opacity(
                opacity: 0.16,
                child: Text('🥬', style: TextStyle(fontSize: 120)),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    _today(),
                    style: text.bodyMedium?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: onLogout,
                    tooltip: 'Çıkış yap',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white12,
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                name.isEmpty ? 'Merhaba 👋' : 'Merhaba $name 👋',
                style: text.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bu akşam ne pişiriyoruz?',
                style: text.bodyLarge?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _HeaderPill(emoji: '🧺', value: '$total', label: 'ürün evde'),
                  const SizedBox(width: 12),
                  _HeaderPill(
                    emoji: '⏰',
                    value: '$urgent',
                    label: 'yakında bitiyor',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Bölümler ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            style: text.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentCard extends StatelessWidget {
  const _UrgentCard({required this.item});

  final PantryItem item;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (label, color) = _expiryInfo(
      item.daysLeft!,
      Theme.of(context).colorScheme,
    );

    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: categoryTint[item.category] ?? const Color(0xFFE8ECEF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(item.emoji, style: const TextStyle(fontSize: 30)),
          ),
          const Spacer(),
          Text(
            item.ingredientName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(_formatQuantity(item), style: text.bodySmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _Chip(
            label: '✨ Tümü',
            active: selected == null,
            onTap: () => onSelected(null),
          ),
          for (final c in categories)
            _Chip(
              label: '${_categoryIcon[c] ?? ''} ${_categoryLabel[c] ?? c}',
              active: selected == c,
              onTap: () => onSelected(c),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.basil : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active
                  ? AppColors.basil
                  : Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.ink,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
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
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: categoryTint[item.category] ?? const Color(0xFFE8ECEF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(item.emoji, style: const TextStyle(fontSize: 26)),
              ),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, size: 20),
                padding: EdgeInsets.zero,
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
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.ingredientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatQuantity(item),
                  style: text.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                _FreshnessBar(daysLeft: item.daysLeft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshnessBar extends StatelessWidget {
  const _FreshnessBar({required this.daysLeft});

  final int? daysLeft;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (daysLeft == null) {
      return Text(
        'Tarihsiz',
        style: TextStyle(
          color: colors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    final (label, color) = _expiryInfo(daysLeft!, colors);
    final value = daysLeft!.clamp(0, 14) / 14;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value == 0 ? 0.04 : value,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

// ─── Boş ve hata durumları ──────────────────────────────────

class _EmptyFridge extends StatelessWidget {
  const _EmptyFridge({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Text('🧊', style: TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 24),
          Text(
            'Buzdolabın bomboş',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Evdeki malzemelerini ekle,\nsana ne pişireceğini söyleyelim.',
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk ürünü ekle'),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
    );
  }
}
