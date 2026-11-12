import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import 'recipe_models.dart';
import 'recipe_repository.dart';

class RecipesScreen extends ConsumerWidget {
  const RecipesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final suggestions = ref.watch(recipeSuggestionsProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(recipeSuggestionsProvider.future),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                'Ne pişirsem? 🍳',
                style: text.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Buzdolabındakilere göre senin için sıraladık',
                style: text.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              suggestions.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => _InfoBox(
                  emoji: '😕',
                  title: 'Öneriler yüklenemedi',
                  text: '$e',
                ),
                data: (list) => list.isEmpty
                    ? const _InfoBox(
                        emoji: '🧊',
                        title: 'Henüz öneri yok',
                        text: 'Buzdolabına birkaç malzeme ekle, sana ne pişirebileceğini söyleyelim.',
                      )
                    : _SuggestionList(list: list),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionList extends StatelessWidget {
  const _SuggestionList({required this.list});

  final List<RecipeSuggestion> list;

  @override
  Widget build(BuildContext context) {
    final ready = list.where((r) => r.isReady).toList();
    final almost = list.where((r) => !r.isReady).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ready.isNotEmpty) ...[
          const _SectionTitle('Hemen yapabileceklerin ✨'),
          for (final r in ready) _RecipeCard(recipe: r),
          const SizedBox(height: 16),
        ],
        if (almost.isNotEmpty) ...[
          const _SectionTitle('Birkaç eksikle 🛒'),
          for (final r in almost) _RecipeCard(recipe: r),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  const _RecipeCard({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final barColor = recipe.isReady ? AppColors.basil : AppColors.tomato;

    return GestureDetector(
      onTap: () => context.push('/recipe/${recipe.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: recipe.isReady
                    ? colors.primaryContainer
                    : const Color(0xFFFDE8D7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(recipe.emoji, style: const TextStyle(fontSize: 38)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text('${recipe.prepMinutes} dk', style: text.bodySmall),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text('${recipe.servings} kişilik', style: text.bodySmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: recipe.matchPercent / 100,
                            minHeight: 6,
                            backgroundColor: barColor.withValues(alpha: 0.15),
                            valueColor: AlwaysStoppedAnimation(barColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${recipe.haveCount}/${recipe.requiredCount}',
                        style: TextStyle(
                          color: barColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (recipe.isReady)
                    const Text(
                      'Tüm malzemeler evde 🎉',
                      style: TextStyle(
                        color: AppColors.basil,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final m in recipe.missing)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.tomato.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '+ $m',
                              style: const TextStyle(
                                color: AppColors.tomato,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
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

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.emoji,
    required this.title,
    required this.text,
  });

  final String emoji;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            title,
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
