import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/meal_plan_controller.dart';
import '../../services/meal_plan_service.dart';
import '../../shared/widgets/recipe_image.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';

/// A week of meals, one day at a time.
///
/// Deliberately not a 7x4 grid: on a phone that means 28 cells of roughly
/// nothing. A day selector plus four readable slots fits the screen and the
/// way people actually plan — a day at a time, not a spreadsheet.
class MealPlanView extends StatefulWidget {
  const MealPlanView({super.key});

  @override
  State<MealPlanView> createState() => _MealPlanViewState();
}

class _MealPlanViewState extends State<MealPlanView> {
  final MealPlanController c = Get.put(MealPlanController());

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Meal planner')),
      body: Obx(() {
        final days = c.week;
        final last = days.last;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSizes.screenPad, AppSizes.sm, AppSizes.screenPad, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const AppIcon('chevron_left', fallback: Icons.chevron_left),
                    tooltip: 'Previous week',
                    onPressed: () => c.shiftWeek(-1),
                  ),
                  Expanded(
                    child: Text(
                      '${days.first.day} ${_months[days.first.month - 1]} — '
                      '${last.day} ${_months[last.month - 1]}',
                      textAlign: TextAlign.center,
                      style: text.titleMedium,
                    ),
                  ),
                  IconButton(
                    icon: const AppIcon('chevron_right', fallback: Icons.chevron_right),
                    tooltip: 'Next week',
                    onPressed: () => c.shiftWeek(1),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
                itemBuilder: (_, i) {
                  final day = days[i];
                  final on = c.isSameDay(day, c.selectedDay.value);
                  final planned = c.countFor(day);
                  return GestureDetector(
                    onTap: () => c.selectedDay.value = day,
                    child: AnimatedContainer(
                      duration: AppSizes.durFast,
                      width: 52,
                      decoration: BoxDecoration(
                        color: on ? t.brandFill : t.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_dayNames[i],
                              style: text.labelSmall?.copyWith(
                                  color: on
                                      ? t.onBrandFill.withValues(alpha: 0.8)
                                      : t.textSecondary)),
                          const SizedBox(height: 2),
                          Text('${day.day}',
                              style: text.titleMedium?.copyWith(
                                  color:
                                      on ? t.onBrandFill : t.textPrimary)),
                          const SizedBox(height: 4),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: planned > 0
                                  ? (on ? t.onBrandFill : t.brand)
                                  : Colors.transparent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: c.isLoading.value
                  ? const ListSkeleton(thumb: 48, card: true)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                          AppSizes.md, AppSizes.screenPad, AppSizes.xxl),
                      children: [
                        for (final slot in MealPlanService.slots)
                          _Slot(
                            controller: c,
                            slot: slot,
                            day: c.selectedDay.value,
                            onPick: () => _pick(context, slot),
                          ),
                        const SizedBox(height: AppSizes.md),
                        if (c.entries.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () async {
                              final n = await c.addWeekToShoppingList();
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(n == 0
                                      ? 'You already have everything for this week'
                                      : "$n added to your shopping list"),
                                ),
                              );
                            },
                            icon: const AppIcon('shopping_basket_outlined', fallback: Icons.shopping_basket_outlined,
                                size: AppSizes.iconSm),
                            label: const Text("Shop for this week"),
                          ),
                      ],
                    ),
            ),
          ],
        );
      }),
    );
  }

  void _pick(BuildContext context, String slot) {
    final search = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tokens.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        expand: false,
        builder: (_, scroll) => Obx(() {
          final t = sheetCtx.tokens;
          final results =
              c.searchResults.isNotEmpty ? c.searchResults : c.saved;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                    AppSizes.md, AppSizes.screenPad, AppSizes.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add to ${slot[0].toUpperCase()}${slot.substring(1)}',
                        style: Theme.of(sheetCtx).textTheme.titleLarge),
                    const SizedBox(height: AppSizes.smd),
                    TextField(
                      controller: search,
                      onChanged: c.search,
                      decoration: const InputDecoration(
                        hintText: 'Search all recipes',
                        prefixIcon: AppIcon('search', fallback: Icons.search, size: AppSizes.iconMd),
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      c.searchResults.isEmpty
                          ? 'FROM YOUR SAVED'
                          : 'SEARCH RESULTS',
                      style: Theme.of(sheetCtx).textTheme.labelSmall?.copyWith(
                          color: t.textTertiary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text('Nothing to show',
                            style: Theme.of(sheetCtx)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: t.textSecondary)),
                      )
                    : ListView.builder(
                        controller: scroll,
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.screenPad),
                        itemCount: results.length,
                        itemBuilder: (_, i) {
                          final r = results[i];
                          final id = (r['id'] ?? '').toString();
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: RecipeImage(
                              seed: id,
                              imageUrl: r['image_url'] as String?,
                              width: 44,
                              height: 44,
                              radius: AppSizes.radiusSm,
                            ),
                            title: Text((r['title'] ?? '') as String,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Text((r['cook_time'] ?? '') as String),
                            onTap: () {
                              c.add(id, c.selectedDay.value, slot);
                              c.searchResults.clear();
                              Navigator.pop(sheetCtx);
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        }),
      ),
    ).then((_) {
      search.dispose();
      c.searchResults.clear();
    });
  }
}

class _Slot extends StatelessWidget {
  final MealPlanController controller;
  final String slot;
  final DateTime day;
  final VoidCallback onPick;

  const _Slot({
    required this.controller,
    required this.slot,
    required this.day,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final entry = controller.entryFor(day, slot);
      final recipe = entry?['recipes'] as Map<String, dynamic>?;
      final label = '${slot[0].toUpperCase()}${slot.substring(1)}';

      return Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.smd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: text.labelSmall?.copyWith(
                    color: t.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
            const SizedBox(height: AppSizes.xs + 2),
            if (recipe == null)
              InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.md, horizontal: AppSizes.md),
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Row(children: [
                    AppIcon('add', fallback: Icons.add, size: AppSizes.iconMd, color: t.textTertiary),
                    const SizedBox(width: AppSizes.sm),
                    Text('Add a recipe',
                        style: text.bodyMedium
                            ?.copyWith(color: t.textTertiary)),
                  ]),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(AppSizes.smd),
                decoration: BoxDecoration(
                  color: t.surfaceRaised,
                  border: Border.all(color: t.cardBorder),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: t.cardShadow,
                ),
                child: Row(children: [
                  RecipeImage(
                    seed: (recipe['id'] ?? '').toString(),
                    imageUrl: recipe['image_url'] as String?,
                    width: 48,
                    height: 48,
                    radius: AppSizes.radiusSm,
                  ),
                  const SizedBox(width: AppSizes.smd),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.to(() => RecipeDetailsView(
                          recipeId: (recipe['id'] ?? '').toString())),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text((recipe['title'] ?? '') as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium),
                          if ((recipe['cook_time'] ?? '').toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(recipe['cook_time'] as String,
                                  style: text.labelSmall
                                      ?.copyWith(color: t.textSecondary)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: AppIcon('close', fallback: Icons.close,
                        size: AppSizes.iconMd, color: t.textSecondary),
                    tooltip: 'Remove',
                    onPressed: () => controller.remove(entry!),
                  ),
                ]),
              ),
          ],
        ),
      );
    });
  }
}
