import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/recipe_controller.dart';
import '../../theme/app_tokens.dart';
import 'filter_sheet.dart';
import '../../shared/widgets/app_icon.dart';

/// Filter button + chips showing what is currently applied.
/// Belongs to the Recipes tab only — Home holds no filter state.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({super.key});

  @override
  Widget build(BuildContext context) {
    final RecipeController c = Get.find<RecipeController>();
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Obx(() {
      final chips = <Widget>[
        if (c.diet.value != null)
          _FilterChip(label: c.diet.value!, onRemove: () => c.setDiet(null)),
        if (c.categoryName.value != null)
          _FilterChip(
              label: c.categoryName.value!,
              onRemove: () => c.setCategory(null, null)),
        if (c.cuisine.value != null)
          _FilterChip(
              label: c.cuisine.value!, onRemove: () => c.setCuisine(null)),
      ];

      final active = c.activeFilterCount > 0;
      // Active state fills with brandFill, not brand: white label text on
      // #FF4F5A is 3.22:1 and fails AA.
      final fill = active ? t.brandFill : t.surface;
      final fg = active ? t.onBrandFill : t.textSecondary;

      return SizedBox(
        height: 40,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => FilterSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.smd, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  border: active ? null : Border.all(color: t.cardBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon('tune', fallback: Icons.tune, size: AppSizes.iconSm, color: fg),
                    const SizedBox(width: AppSizes.xs + 2),
                    Text(
                      active ? 'Filters (${c.activeFilterCount})' : 'Filters',
                      style: text.labelSmall?.copyWith(color: fg),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSizes.sm),
                itemBuilder: (_, i) => chips[i],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;
  const _FilterChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.only(left: AppSizes.smd, right: AppSizes.xs),
      decoration: BoxDecoration(
        color: t.accentTint,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: t.onAccentTint)),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: AppIcon('close', fallback: Icons.close,
                size: AppSizes.iconXs + 2, color: t.onAccentTint),
            tooltip: 'Remove $label filter',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
