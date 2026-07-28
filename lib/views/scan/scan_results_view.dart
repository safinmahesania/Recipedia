import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/shopping_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';

/// Matches, split into what you can cook now and what you are short of.
///
/// A separate screen rather than a section under the form: once results exist
/// they are the whole point, and leaving them below the input meant scrolling
/// past the thing you just filled in to see the answer.
class ScanResultsView extends StatefulWidget {
  const ScanResultsView({super.key});

  @override
  State<ScanResultsView> createState() => _ScanResultsViewState();
}

class _ScanResultsViewState extends State<ScanResultsView> {
  final ScanController c = Get.put(ScanController());
  final ShoppingController shopping = Get.put(ShoppingController());
  final _tab = 0.obs;

  Future<void> _addMissing(Map<String, dynamic> r) async {
    final names =
        (r['missing_names'] as List?)?.map((e) => e.toString()).toList() ?? [];
    final added = await shopping.addMissing(names, recipeId: r['id'] as String?);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(added == 0
          ? 'Already on your list'
          : '$added added to your shopping list'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        titleSpacing: 0,
        title: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Matches', style: text.titleLarge),
                Text('From ${c.ingredients.length} ingredients',
                    style:
                        text.labelSmall?.copyWith(color: t.textSecondary)),
              ],
            )),
      ),
      body: Obx(() {
        final ready = c.ready;
        final almost = c.almost;
        final rows = _tab.value == 0 ? ready : almost;

        if (c.results.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon('search_off',
                      size: AppSizes.iconXl,
                      color: t.borderStrong),
                  const SizedBox(height: AppSizes.smd),
                  Text('No matches',
                      style: text.titleLarge?.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSizes.xs),
                  Text('Try adding one or two more ingredients.',
                      textAlign: TextAlign.center,
                      style:
                          text.bodySmall?.copyWith(color: t.textSecondary)),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                  AppSizes.sm, AppSizes.screenPad, AppSizes.smd),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Row(children: [
                  _Segment(
                    label: 'Ready · ${ready.length}',
                    selected: _tab.value == 0,
                    onTap: () => _tab.value = 0,
                  ),
                  _Segment(
                    label: 'Almost · ${almost.length}',
                    selected: _tab.value == 1,
                    onTap: () => _tab.value = 1,
                  ),
                ]),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        _tab.value == 0
                            ? 'Nothing is fully covered yet'
                            : 'Nothing close by',
                        style:
                            text.bodyMedium?.copyWith(color: t.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, 0,
                          AppSizes.screenPad, AppSizes.xl),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSizes.smd),
                      itemBuilder: (_, i) {
                        final r = rows[i];
                        return RecipeCard(
                          recipe: r,
                          onAddMissing:
                              _tab.value == 0 ? null : () => _addMissing(r),
                          onTap: () => Get.to(
                              () => RecipeDetailsView(recipeId: r['id'])),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppSizes.durFast,
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? t.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            boxShadow: selected ? t.cardShadow : null,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? t.textPrimary : t.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
