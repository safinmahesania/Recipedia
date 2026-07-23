import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/recipe_controller.dart';
import 'filter_sheet.dart';

/// Filter button + chips showing what is currently applied.
/// Sits above any recipe list.
class ActiveFiltersBar extends StatelessWidget {
  const ActiveFiltersBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final RecipeController c = Get.find<RecipeController>();

    return Obx(() {
      final chips = <Widget>[];

      if (c.diet.value != null) {
        chips.add(_chip(c.diet.value!, () => c.setDiet(null)));
      }
      if (c.categoryName.value != null) {
        chips.add(_chip(c.categoryName.value!, () => c.setCategory(null, null)));
      }
      if (c.cuisine.value != null) {
        chips.add(_chip(c.cuisine.value!, () => c.setCuisine(null)));
      }

      return SizedBox(
        height: 40,
        child: Row(
          children: [
            // filter button with count badge
            GestureDetector(
              onTap: () => FilterSheet.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: c.activeFilterCount > 0 ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.tune,
                        size: 16,
                        color: c.activeFilterCount > 0
                            ? Colors.white
                            : AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      c.activeFilterCount > 0
                          ? 'Filters (${c.activeFilterCount})'
                          : 'Filters',
                      style: TextStyle(
                        fontSize: 13,
                        color: c.activeFilterCount > 0
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: chips.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => chips[i],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _chip(String label, VoidCallback onRemove) => Container(
        padding: const EdgeInsets.only(left: 12, right: 6),
        decoration: BoxDecoration(
            color: AppColors.accentTint, borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppColors.accentDark)),
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              icon: const Icon(Icons.close, size: 14, color: AppColors.accentDark),
              onPressed: onRemove,
            ),
          ],
        ),
      );
}
