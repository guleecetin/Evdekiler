import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_image.dart';
import 'recipe_models.dart';
import 'recipe_repository.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  RecipeCategory? _category; // null = Tümü

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(recipeSuggestionsProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(recipeSuggestionsProvider.future),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tarifler',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Buzdolabındakilere göre senin için sıraladık',
                        style: TextStyle(color: AppColors.muted, fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _CategoryChips(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
              ),
              ...suggestions.when<List<Widget>>(
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
                      child: Text('Öneriler yüklenemedi: $e'),
                    ),
                  ),
                ],
                data: (list) {
                  final filtered = _category == null
                      ? list
                      : list.where((r) => r.category == _category).toList();

                  if (filtered.isEmpty) {
                    return [
                      SliverToBoxAdapter(
                        child: _EmptyCategory(category: _category),
                      ),
                    ];
                  }

                  return [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      sliver: SliverList.builder(
                        itemCount: filtered.length,
                        itemBuilder: (_, i) => _RecipeCard(recipe: filtered[i]),
                      ),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Kategori çipleri ───────────────────────────────────────

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final RecipeCategory? selected;
  final ValueChanged<RecipeCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final items = <RecipeCategory?>[null, ...RecipeCategory.values];

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = items[i];
          final active = c == selected;
          final fg = c?.foreground ?? AppColors.basilDark;
          final bg = c?.background ?? const Color(0xFFE3ECE4);

          return GestureDetector(
            onTap: () => onSelected(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: active ? fg : bg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    c?.icon ?? Icons.grid_view_rounded,
                    size: 18,
                    color: active ? Colors.white : fg,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    c?.label ?? 'Tümü',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: active ? Colors.white : fg,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Tarif kartı ────────────────────────────────────────────

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    final tag = 'list-${recipe.id}';
    final c = recipe.category;

    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}?hero=$tag'),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(recipe.imageUrl, fallbackEmoji: recipe.emoji),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _Pill(
                          text: recipe.isReady
                              ? 'Hemen yapılabilir'
                              : '${recipe.haveCount}/${recipe.requiredCount} malzeme evde',
                          background: Colors.white,
                          foreground: AppColors.ink,
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: _Pill(
                          text: c.label,
                          icon: c.icon,
                          background: c.background,
                          foreground: c.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    recipe.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(Icons.schedule_rounded, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${recipe.prepMinutes} dk',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              recipe.isReady
                  ? 'Tüm malzemeler evde 🎉'
                  : 'Eksik: ${recipe.missing.join(', ')}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            Text(
              '${recipe.servings} kişilik',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 6),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory({required this.category});

  final RecipeCategory? category;

  @override
  Widget build(BuildContext context) {
    final c = category;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 60, 32, 0),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: c?.background ?? AppColors.cream,
              shape: BoxShape.circle,
            ),
            child: Icon(
              c?.icon ?? Icons.kitchen_outlined,
              size: 44,
              color: c?.foreground ?? AppColors.muted,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            c == null ? 'Henüz öneri yok' : '${c.label} önerisi yok',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Buzdolabındakilerle eşleşen tarif bulamadık.\nBirkaç malzeme daha eklemeyi dene.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
