import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/cooked_controller.dart';
import '../../shared/widgets/recipe_image.dart';
import '../../shared/widgets/skeletons.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';

/// What you have actually cooked, newest first.
///
/// cook_mode has been writing to cooked_history since it shipped and nothing
/// read it back — the app knew what you cooked and never told you.
class CookingHistoryView extends StatefulWidget {
  const CookingHistoryView({super.key});

  @override
  State<CookingHistoryView> createState() => _CookingHistoryViewState();
}

class _CookingHistoryViewState extends State<CookingHistoryView> {
  final CookedController c = Get.put(CookedController());

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _when(dynamic iso) {
    final d = DateTime.tryParse((iso ?? '').toString());
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${d.day} ${_months[d.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Cooking history')),
      body: Obx(() {
        if (c.isLoading.value && c.entries.isEmpty) {
          return const ListSkeleton(thumb: 52, card: true);
        }
        if (c.entries.isEmpty) {
          return const EmptyState(
            icon: 'local_fire_department',
            title: 'Nothing cooked yet',
            message: 'Finish a recipe in cook mode and it lands here.',
          );
        }

        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.load,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPad),
            itemCount: c.entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
            itemBuilder: (_, i) {
              if (i == 0) {
                return Row(children: [
                  _Stat(label: 'Recipes', value: '${c.distinctRecipes}'),
                  const SizedBox(width: AppSizes.sm),
                  _Stat(label: 'Times', value: '${c.entries.length}'),
                  const SizedBox(width: AppSizes.sm),
                  _Stat(label: 'This month', value: '${c.thisMonth}'),
                ]);
              }

              final e = c.entries[i - 1];
              final r = (e['recipes'] as Map<String, dynamic>?) ?? {};
              final id = (r['id'] ?? '').toString();
              final note = (e['note'] ?? '').toString();

              return Dismissible(
                key: ValueKey(e['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: AppSizes.md),
                  decoration: BoxDecoration(
                    color: t.errorTint,
                    borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  ),
                  child: Icon(Icons.delete_outline, color: t.onErrorTint),
                ),
                onDismissed: (_) => c.remove(e),
                child: InkWell(
                  onTap: id.isEmpty
                      ? null
                      : () => Get.to(() => RecipeDetailsView(recipeId: id)),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.smd),
                    decoration: BoxDecoration(
                      color: t.surfaceRaised,
                      border: Border.all(color: t.cardBorder),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      boxShadow: t.cardShadow,
                    ),
                    child: Row(children: [
                      RecipeImage(
                        seed: id,
                        imageUrl: r['image_url'] as String?,
                        width: 52,
                        height: 52,
                        radius: AppSizes.radiusSm,
                      ),
                      const SizedBox(width: AppSizes.smd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text((r['title'] ?? 'Recipe') as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: text.titleMedium),
                            const SizedBox(height: 2),
                            Text(_when(e['cooked_at']),
                                style: text.labelSmall
                                    ?.copyWith(color: t.textSecondary)),
                            if (note.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Text(note,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall
                                        ?.copyWith(color: t.textSecondary)),
                              ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.smd),
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Column(children: [
          Text(value, style: text.titleLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 1),
          Text(label,
              style: text.labelSmall?.copyWith(color: t.textSecondary)),
        ]),
      ),
    );
  }
}
