import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/favorites_controller.dart';
import '../../controllers/recent_controller.dart';
import '../../controllers/review_controller.dart';
import '../../services/auth_service.dart';
import '../../services/cache_service.dart';
import '../../services/cooked_service.dart';
import '../../services/recipe_service.dart';
import '../../services/share_service.dart';
import '../../shared/recipe_steps.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../shared/widgets/recipe_image.dart';
import '../../theme/app_tokens.dart';
import 'cook_mode_view.dart';
import 'review_rating_view.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';

/// Recipe detail — hero, meta, ingredients, instructions, and the favorite,
/// share, review and report actions.
class RecipeDetailsView extends StatelessWidget {
  final String recipeId;
  const RecipeDetailsView({super.key, required this.recipeId});

  /// Network first, cache on success, cache as fallback when offline.
  Future<Map<String, dynamic>> _load() async {
    final cache = CacheService();
    try {
      final r = await RecipeService().getRecipeDetails(recipeId);
      await cache.saveRecipe(recipeId, r);
      Get.put(RecentController()).track(r);
      return r;
    } catch (_) {
      final cached = await cache.getRecipe(recipeId);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = Get.put(FavoritesController());
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _load(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Text('Could not load this recipe',
                  style: text.bodyMedium?.copyWith(color: t.textSecondary)),
            );
          }
          if (!snap.hasData) {
            return const _DetailSkeleton();
          }

          final r = snap.data!;
          final ingredients = (r['recipe_ingredients'] as List?) ?? [];
          final steps = RecipeSteps.split((r['instructions'] ?? '') as String);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                backgroundColor: t.canvas,
                surfaceTintColor: Colors.transparent,
                iconTheme: IconThemeData(color: t.textPrimary),
                actions: [
                  Obx(() {
                    final isFav =
                        favorites.favorites.any((f) => f['id'] == recipeId);
                    return IconButton(
                      icon: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? t.brand : t.textPrimary),
                      tooltip: isFav ? 'Remove from saved' : 'Save',
                      onPressed: () => favorites.toggleFavorite(recipeId),
                    );
                  }),
                  IconButton(
                    icon: const AppIcon('share', fallback: Icons.share),
                    tooltip: 'Share',
                    onPressed: () => ShareService().shareRecipe(r),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  // Same deterministic placeholder as every card, so a recipe
                  // keeps one identity from grid to detail.
                  background: LayoutBuilder(
                    builder: (_, box) => RecipeImage(
                      seed: recipeId,
                      imageUrl: r['image_url'] as String?,
                      width: box.maxWidth,
                      height: box.maxHeight,
                      radius: 0,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.screenPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((r['title'] ?? '') as String,
                          style: text.headlineMedium),
                      const SizedBox(height: AppSizes.smd),
                      _CookedBadge(recipeId: recipeId),
                      Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          if (r['cook_time'] != null)
                            _Meta('schedule', '${r['cook_time']}'),
                          if (r['diet'] != null)
                            _Meta('eco', '${r['diet']}', accent: true),
                          if (r['cuisine'] != null)
                            _Meta('public', '${r['cuisine']}'),
                        ],
                      ),

                      const SizedBox(height: AppSizes.lg),
                      _SectionTitle('Ingredients', trailing: '${ingredients.length}'),
                      const SizedBox(height: AppSizes.sm),
                      ...ingredients.map((ri) {
                        final ing = ri['ingredients'] as Map<String, dynamic>?;
                        final name = (ing?['name'] ?? '') as String;
                        final qty = (ri['quantity'] ?? '') as String;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSizes.xs + 1),
                          child: Row(
                            children: [
                              IngredientIconFromRow(
                                  row: ri as Map<String, dynamic>, size: 22),
                              const SizedBox(width: AppSizes.smd),
                              Expanded(child: Text(name, style: text.bodyLarge)),
                              if (qty.isNotEmpty)
                                Text(qty,
                                    style: text.labelSmall
                                        ?.copyWith(color: t.textSecondary)),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: AppSizes.lg),
                      _SectionTitle('Instructions',
                          trailing: steps.isEmpty ? null : '${steps.length} steps'),
                      const SizedBox(height: AppSizes.smd),
                      if (steps.isEmpty)
                        Text((r['instructions'] ?? '') as String,
                            style: text.bodyLarge?.copyWith(height: 1.6))
                      else
                        ...steps.asMap().entries.map((e) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSizes.smd),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: t.brandTint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text('${e.key + 1}',
                                        style: text.labelSmall?.copyWith(
                                            color: t.onBrandTint,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                  const SizedBox(width: AppSizes.smd),
                                  Expanded(
                                    child: Text(e.value,
                                        style: text.bodyLarge
                                            ?.copyWith(height: 1.55)),
                                  ),
                                ],
                              ),
                            )),

                      const SizedBox(height: AppSizes.lg),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Get.to(() => ReviewRatingView(
                                recipeId: recipeId,
                                recipeTitle: (r['title'] ?? '') as String)),
                            icon: const AppIcon('star_border', fallback: Icons.star_border,
                                size: AppSizes.iconSm),
                            label: const Text('Reviews'),
                          ),
                        ),
                        const SizedBox(width: AppSizes.smd),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Get.to(() => CookModeView(
                                      recipeId: recipeId,
                                      title: (r['title'] ?? '') as String,
                                      steps: RecipeSteps.stepsOrWhole(
                                          (r['instructions'] ?? '') as String),
                                      ingredients: [
                                        for (final ri in ingredients)
                                          [
                                            ((ri['ingredients'] as Map?)?['name'] ?? '')
                                                .toString(),
                                            ((ri['quantity'] ?? '') as String)
                                          ].where((x) => x.isNotEmpty).join('  ')
                                      ],
                                    )),
                            icon: const AppIcon('local_fire_department', fallback: Icons.local_fire_department,
                                size: AppSizes.iconSm),
                            label: const Text('Start cooking'),
                          ),
                        ),
                      ]),
                      const SizedBox(height: AppSizes.sm),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => _reportDialog(context, recipeId),
                          icon: AppIcon('flag_outlined', fallback: Icons.flag_outlined,
                              size: AppSizes.iconSm, color: t.textSecondary),
                          label: Text('Report this recipe',
                              style: text.labelSmall
                                  ?.copyWith(color: t.textSecondary)),
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _reportDialog(BuildContext context, String recipeId) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Report recipe'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: "What's wrong with this recipe?"),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.put(ReviewController())
                  .report('recipe', recipeId, reason.text.trim());
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Report'),
          ),
        ],
      ),
      // The controller outlives the dialog otherwise.
    ).then((_) => reason.dispose());
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionTitle(this.title, {this.trailing});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: text.titleLarge?.copyWith(fontSize: 17)),
        if (trailing != null)
          Text(trailing!,
              style: text.labelSmall?.copyWith(color: t.textSecondary)),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  final String icon;
  final String label;
  final bool accent;
  const _Meta(this.icon, this.label, {this.accent = false});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.smd, vertical: AppSizes.xs + 2),
      decoration: BoxDecoration(
        color: accent ? t.accentTint : t.surface,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        AppIcon(icon, fallback: Icons.circle_outlined,
            size: AppSizes.iconSm,
            color: accent ? t.onAccentTint : t.textSecondary),
        const SizedBox(width: AppSizes.xs + 1),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: accent ? t.onAccentTint : t.textSecondary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Mirrors the real layout — hero, title, chips, two sections — so nothing
/// shifts when the recipe arrives.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => Pulse(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            SkeletonBox(height: 240, radius: 0),
            Padding(
              padding: EdgeInsets.all(AppSizes.screenPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 220, height: 24),
                  SizedBox(height: AppSizes.smd),
                  SkeletonBox(width: 180, height: 28, radius: AppSizes.radiusPill),
                  SizedBox(height: AppSizes.lg),
                  SkeletonBox(width: 120, height: 14),
                  SizedBox(height: AppSizes.smd),
                  SkeletonBox(height: 12),
                  SizedBox(height: AppSizes.sm),
                  SkeletonBox(height: 12),
                  SizedBox(height: AppSizes.sm),
                  SkeletonBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      );
}

/// "You have made this before" — the app already recorded every cook and
/// never mentioned it. Self-contained so the detail screen does not need a
/// controller just for one line.
class _CookedBadge extends StatefulWidget {
  final String recipeId;
  const _CookedBadge({required this.recipeId});

  @override
  State<_CookedBadge> createState() => _CookedBadgeState();
}

class _CookedBadgeState extends State<_CookedBadge> {
  ({int count, DateTime? last})? _stats;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService().currentUser?.id;
    if (uid == null) return;
    try {
      final s = await CookedService().statsFor(uid, widget.recipeId);
      if (mounted && s.count > 0) setState(() => _stats = s);
    } catch (_) {
      // A missing badge is better than a broken screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _stats;
    if (s == null) return const SizedBox.shrink();
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final d = s.last;
    final when = d == null ? '' : ' · last on ${d.day} ${_months[d.month - 1]}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smd),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.smd, vertical: AppSizes.sm),
        decoration: BoxDecoration(
          color: t.successTint,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(children: [
          AppIcon('local_fire_department',
              fallback: Icons.local_fire_department,
              size: AppSizes.iconSm,
              color: t.onSuccessTint),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              s.count == 1
                  ? 'You cooked this once$when'
                  : 'You cooked this ${s.count} times$when',
              style: text.labelSmall?.copyWith(color: t.onSuccessTint),
            ),
          ),
        ]),
      ),
    );
  }
}
