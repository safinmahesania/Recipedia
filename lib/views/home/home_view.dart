import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/home_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../controllers/shopping_controller.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../shared/widgets/section_header.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';
import '../scan/scan_view.dart';
import '../../shared/widgets/app_icon.dart';

/// Home — "what can I cook tonight?"
///
/// Deliberately NOT a recipe list. The Recipes tab is the catalogue; Home is
/// pantry state. It leads with what the user can cook right now and what
/// they're one ingredient short of, which is the one thing the catalogue
/// cannot tell them.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController c = Get.put(HomeController());
    final ProfileController pc = Get.put(ProfileController());
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: t.brand,
          onRefresh: c.load,
          child: Obx(() {
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSizes.xl),
              children: [
                _Header(controller: c, profile: pc),
                const SizedBox(height: AppSizes.md),
                _PantryCard(controller: c),
                if (c.isLoading.value)
                  const Padding(
                    padding: EdgeInsets.all(AppSizes.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  if (c.readyToCook.isNotEmpty)
                    _ReadyToCook(controller: c),
                  if (c.almostThere.isNotEmpty)
                    _AlmostThere(controller: c),
                  if (c.recentlyViewed.isNotEmpty)
                    _Carousel(
                      title: 'Pick up where you left off',
                      items: c.recentlyViewed,
                    ),
                  if (c.newest.isNotEmpty)
                    _Carousel(
                      title: 'New from the community',
                      subtitle: 'Recently approved submissions',
                      items: c.newest,
                    ),
                ],
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final HomeController controller;
  final ProfileController profile;
  const _Header({required this.controller, required this.profile});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPad, AppSizes.md, AppSizes.screenPad, 0),
      child: Obx(() {
        final p = profile.profile.value;
        final name = (p?.name ?? '').trim();
        final count = controller.pantry.length;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty
                        ? controller.greeting
                        : '${controller.greeting}, ${name.split(' ').first}',
                    style: text.headlineMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count == 0
                        ? 'Your pantry is empty'
                        : '$count ${count == 1 ? 'thing' : 'things'} in your pantry',
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: t.brandTint,
              backgroundImage: (p?.avatarUrl != null && p!.avatarUrl!.isNotEmpty)
                  ? NetworkImage(p.avatarUrl!)
                  : null,
              child: (p?.avatarUrl == null || p!.avatarUrl!.isEmpty)
                  ? Text(
                      name.isEmpty ? '?' : name[0].toUpperCase(),
                      style: text.labelMedium?.copyWith(color: t.onBrandTint),
                    )
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

class _PantryCard extends StatelessWidget {
  final HomeController controller;
  const _PantryCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.smd),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        ),
        child: Obx(() {
          if (controller.pantry.isEmpty) {
            // Empty states are an invitation to act, not an apology.
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tell us what you have',
                    style: text.titleLarge?.copyWith(fontSize: 16)),
                const SizedBox(height: AppSizes.xs),
                Text(
                  'Add a few ingredients and we will show what you can cook right now.',
                  style: text.bodySmall?.copyWith(color: t.textSecondary),
                ),
                const SizedBox(height: AppSizes.smd),
                FilledButton(
                  onPressed: () => Get.to(() => const ScanView()),
                  child: const Text('Scan my pantry'),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('IN YOUR PANTRY',
                        style: text.labelSmall?.copyWith(
                          color: t.textSecondary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.9,
                        )),
                  ),
                  GestureDetector(
                    onTap: controller.clearPantry,
                    child: Text('Clear',
                        style:
                            text.labelMedium?.copyWith(color: t.onBrandTint)),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  ...controller.pantry.map(
                    (name) => _Chip(
                      label: name,
                      onRemove: () => controller.removeFromPantry(name),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Get.to(() => const ScanView()),
                    child: Container(
                      height: AppSizes.chipHeight,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.smd),
                      decoration: BoxDecoration(
                        color: t.brandFill,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppIcon('add', fallback: Icons.add,
                              size: AppSizes.iconSm, color: t.onBrandFill),
                          const SizedBox(width: 3),
                          Text('Scan',
                              style: text.labelSmall
                                  ?.copyWith(color: t.onBrandFill)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _Chip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      height: AppSizes.chipHeight,
      padding: const EdgeInsets.only(left: AppSizes.sm, right: AppSizes.sm),
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        border: Border.all(color: t.cardBorder),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IngredientIcon(name: label, size: 16, tile: false),
          const SizedBox(width: AppSizes.xs + 2),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: AppSizes.xs),
          GestureDetector(
            onTap: onRemove,
            child: AppIcon('close', fallback: Icons.close,
                size: AppSizes.iconSm, color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ReadyToCook extends StatelessWidget {
  final HomeController controller;
  const _ReadyToCook({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
            child: SectionHeader(
              title: 'Ready to cook',
              count: controller.readyToCook.length,
            ),
          ),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPad),
              itemCount: controller.readyToCook.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.smd),
              itemBuilder: (_, i) {
                final r = controller.readyToCook[i];
                return RecipeTile(
                  recipe: r,
                  onTap: () =>
                      Get.to(() => RecipeDetailsView(recipeId: r['id'])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AlmostThere extends StatelessWidget {
  final HomeController controller;
  const _AlmostThere({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPad, AppSizes.lg, AppSizes.screenPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Almost there',
            subtitle: 'One or two ingredients away',
          ),
          ...controller.almostThere.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: RecipeCard(
                recipe: r,
                onAddMissing: () async {
                  final names = (r['missing_names'] as List?)
                          ?.map((e) => e.toString())
                          .toList() ??
                      [];
                  final n = await Get.put(ShoppingController())
                      .addMissing(names, recipeId: r['id'] as String?);
                  Get.snackbar(
                      'Shopping list',
                      n == 0
                          ? 'Already on your list'
                          : '$n added to your shopping list');
                },
                onTap: () =>
                    Get.to(() => RecipeDetailsView(recipeId: r['id'])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carousel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Map<String, dynamic>> items;

  const _Carousel({required this.title, this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
            child: SectionHeader(title: title, subtitle: subtitle),
          ),
          SizedBox(
            height: 182,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPad),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSizes.smd),
              itemBuilder: (_, i) {
                final r = items[i];
                return RecipeTile(
                  recipe: r,
                  onTap: () =>
                      Get.to(() => RecipeDetailsView(recipeId: r['id'])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
