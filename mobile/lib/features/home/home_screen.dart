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

// Aramada Türkçe karakter duyarsızlık: "sogan" -> "Soğan"
String _fold(String s) => s
    .replaceAll('İ', 'i')
    .replaceAll('I', 'i')
    .toLowerCase()
    .replaceAll('ç', 'c')
    .replaceAll('ğ', 'g')
    .replaceAll('ı', 'i')
    .replaceAll('ö', 'o')
    .replaceAll('ş', 's')
    .replaceAll('ü', 'u');

// Aynı malzemenin farklı partileri (farklı tarihlerde alınmış) tek kartta
class _FridgeGroup {
  _FridgeGroup(this.items);

  final List<PantryItem> items;

  PantryItem get first => items.first;
  String get name => first.ingredientName;
  String get imageUrl => first.imageUrl;
  String get emoji => first.emoji;
  String get category => first.category;

  // En yakın son kullanma tarihi
  int? get daysLeft {
    final days = items.map((i) => i.daysLeft).whereType<int>();
    return days.isEmpty ? null : days.reduce(min);
  }

  // Birimlere göre toplam: "33 adet" ya da "1 adet + 1,25 kg"
  String get quantityText {
    final sums = <MeasureUnit, double>{};
    for (final i in items) {
      sums[i.unit] = (sums[i.unit] ?? 0) + i.quantity;
    }
    return sums.entries.map((e) => formatQuantity(e.value, e.key)).join(' + ');
  }
}

List<_FridgeGroup> _groupItems(List<PantryItem> list) {
  final map = <int, List<PantryItem>>{};
  for (final item in list) {
    map.putIfAbsent(item.ingredientId, () => []).add(item);
  }

  final groups = map.values.map(_FridgeGroup.new).toList();
  // Önce son kullanma tarihi yaklaşanlar, sonra tarihsizler; kendi içinde alfabetik
  groups.sort((a, b) {
    final da = a.daysLeft, db = b.daysLeft;
    if (da != null && db != null && da != db) return da.compareTo(db);
    if (da != null && db == null) return -1;
    if (da == null && db != null) return 1;
    return a.name.compareTo(b.name);
  });
  return groups;
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _category;
  String _query = '';

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
    final groups = _groupItems(list);
    final categories = groups.map((g) => g.category).toSet().toList();

    final q = _fold(_query.trim());
    final filtered = groups.where((g) {
      if (_category != null && g.category != _category) return false;
      if (q.isNotEmpty && !_fold(g.name).contains(q)) return false;
      return true;
    }).toList();

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
          subtitle: '${groups.length} çeşit ürün',
        ),
      ),
      SliverToBoxAdapter(
        child: _FridgeSearch(onChanged: (v) => setState(() => _query = v)),
      ),
      SliverToBoxAdapter(
        child: _CategoryTabs(
          categories: categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
      ),
      if (filtered.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 40, 20, 0),
            child: Center(
              child: Text(
                'Aradığın ürün buzdolabında yok.',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          ),
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _GroupCard(group: filtered[i]),
              childCount: filtered.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 20,
              childAspectRatio: 0.74,
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
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.ink,
                    ),
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

class _FridgeSearch extends StatelessWidget {
  const _FridgeSearch({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: TextField(
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buzdolabında ara…',
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: AppColors.ink),
          ),
        ),
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

// ─── Gruplanmış ürün kartı ──────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});

  final _FridgeGroup group;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) => _BatchSheet(group: group),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AppImage(group.imageUrl, fallbackEmoji: group.emoji),
                ),
                if (group.daysLeft != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ExpiryPill(days: group.daysLeft!),
                  ),
                if (group.items.length > 1)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${group.items.length} parti',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            group.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          Text(
            group.quantityText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// Karta dokununca: bu malzemenin buzdolabındaki partileri
class _BatchSheet extends ConsumerWidget {
  const _BatchSheet({required this.group});

  final _FridgeGroup group;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PantryItem item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await ref.read(pantryRepositoryProvider).deleteItem(item.id);
      ref.invalidate(pantryItemsProvider);
      ref.invalidate(recipeSuggestionsProvider);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${group.name} buzdolabından çıkarıldı')),
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batches = [...group.items]
      ..sort((a, b) => (a.daysLeft ?? 9999).compareTo(b.daysLeft ?? 9999));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: AppImage(group.imageUrl, fallbackEmoji: group.emoji),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Toplam ${group.quantityText}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Partiler',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            for (final item in batches)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        formatQuantity(item.quantity, item.unit),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (item.daysLeft != null)
                      _ExpiryPill(days: item.daysLeft!, outlined: true),
                    if (item.daysLeft == null)
                      const Text(
                        'Tarih yok',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    IconButton(
                      onPressed: () => _delete(context, ref, item),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.muted,
                      ),
                      tooltip: 'Bu partiyi çıkar',
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

class _ExpiryPill extends StatelessWidget {
  const _ExpiryPill({required this.days, this.outlined = false});

  final int days;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final (label, color) = expiryInfo(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: AppColors.line) : null,
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
            'Evdeki malzemelerini ekle\nya da market fişini okut.',
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
