import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/recipe_controller.dart';
import '../../theme/app_tokens.dart';

/// Bottom sheet combining category, cuisine and diet.
/// Counts come from the database so the user can see how much each option holds
/// before committing to it.
class FilterSheet extends StatelessWidget {
  const FilterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tokens.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RecipeController c = Get.find<RecipeController>();
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: AppSizes.smd),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: t.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPad, 0, AppSizes.smd, AppSizes.xs),
            child: Row(
              children: [
                Text('Filters', style: text.titleLarge),
                const Spacer(),
                Obx(() => c.activeFilterCount > 0
                    ? TextButton(
                        onPressed: () {
                          c.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear all'),
                      )
                    : const SizedBox.shrink()),
                IconButton(
                  icon: Icon(Icons.close, color: t.textSecondary),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: t.border),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                  AppSizes.md, AppSizes.screenPad, AppSizes.xl),
              children: [
                const _Section('Diet'),
                Obx(() => _Chips(
                      options: c.diets
                          .map((d) => _Opt(
                              d['value'] as String, d['recipe_count'] as int))
                          .toList(),
                      selected: c.diet.value,
                      onTap: (o) => c.setDiet(o?.label),
                    )),
                const SizedBox(height: AppSizes.lg),
                const _Section('Course'),
                Obx(() => _Chips(
                      options: c.categories
                          .map((cat) => _Opt(cat['name'] as String, null,
                              id: cat['id'] as String))
                          .toList(),
                      selected: c.categoryName.value,
                      onTap: (o) => c.setCategory(o?.id, o?.label),
                    )),
                const SizedBox(height: AppSizes.lg),
                const _Section('Cuisine'),
                Obx(() => _Chips(
                      options: c.cuisines
                          .map((cu) => _Opt(
                              cu['value'] as String, cu['recipe_count'] as int))
                          .toList(),
                      selected: c.cuisine.value,
                      onTap: (o) => c.setCuisine(o?.label),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.smd),
        child: Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
      );
}

/// One callback shape for every section: passes the tapped option, or null when
/// the user taps the selected chip to clear it.
class _Chips extends StatelessWidget {
  final List<_Opt> options;
  final String? selected;
  final void Function(_Opt?) onTap;

  const _Chips({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    if (options.isEmpty) {
      return Text('—', style: text.bodyMedium?.copyWith(color: t.textSecondary));
    }

    return Wrap(
      spacing: AppSizes.sm,
      runSpacing: AppSizes.sm,
      children: options.map((o) {
        final isSelected = selected == o.label;
        return GestureDetector(
          onTap: () => onTap(isSelected ? null : o),
          child: AnimatedContainer(
            duration: AppSizes.durFast,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md, vertical: AppSizes.sm),
            decoration: BoxDecoration(
              // brandFill, not brand: white on #FF4F5A is 3.14:1 and fails AA.
              color: isSelected ? t.brandFill : t.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text(
              o.count == null ? o.label : '${o.label}  ${o.count}',
              style: text.labelSmall?.copyWith(
                color: isSelected ? t.onBrandFill : t.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Opt {
  final String label;
  final int? count;
  final String? id;
  _Opt(this.label, this.count, {this.id});
}
