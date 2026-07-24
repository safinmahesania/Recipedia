import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/recipe_controller.dart';

/// Bottom sheet for combining category + cuisine + diet filters.
/// Counts come from the database so the user can see how much each option holds.
class FilterSheet extends StatelessWidget {
  const FilterSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FilterSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RecipeController c = Get.find<RecipeController>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // grabber
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(
                color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: [
                const Text('Filters',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Obx(() => c.activeFilterCount > 0
                    ? TextButton(
                        onPressed: () {
                          c.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear all',
                            style: TextStyle(color: AppColors.primary)),
                      )
                    : const SizedBox.shrink()),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _section('Diet'),
                Obx(() => _chips(
                      options: c.diets
                          .map((d) => _Opt(d['value'] as String, d['recipe_count'] as int))
                          .toList(),
                      selected: c.diet.value,
                      onTap: (o) => c.setDiet(o?.label),
                    )),
                const SizedBox(height: 24),
                _section('Course'),
                Obx(() => _chips(
                      options: c.categories
                          .map((cat) => _Opt(cat['name'] as String, null, id: cat['id'] as String))
                          .toList(),
                      selected: c.categoryName.value,
                      onTap: (o) => c.setCategory(o?.id, o?.label),
                    )),
                const SizedBox(height: 24),
                _section('Cuisine'),
                Obx(() => _chips(
                      options: c.cuisines
                          .map((cu) => _Opt(cu['value'] as String, cu['recipe_count'] as int))
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

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      );

  /// One callback shape for every section: passes the tapped option,
  /// or null when the user taps the selected chip to clear it.
  Widget _chips({
    required List<_Opt> options,
    required String? selected,
    required void Function(_Opt?) onTap,
  }) {
    if (options.isEmpty) {
      return const Text('—', style: TextStyle(color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final isSelected = selected == o.label;
        return GestureDetector(
          // tapping the selected chip clears that filter
          onTap: () => onTap(isSelected ? null : o),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              o.count == null ? o.label : '${o.label}  ${o.count}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : AppColors.textSecondary,
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
