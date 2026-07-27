import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/scan_controller.dart';
import '../../controllers/shopping_controller.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_card.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';

/// Scan a vegetable or fruit — or just type ingredients — and rank recipes by
/// what you already have. Detected items show as editable chips so a wrong
/// guess is a one-tap fix rather than a dead end.
///
/// StatefulWidget because the manual-entry controller was previously created
/// inside build() on a StatelessWidget: never disposed, and any parent rebuild
/// wiped whatever the user had typed.
class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  final ScanController c = Get.put(ScanController());
  final ShoppingController shopping = Get.put(ShoppingController());
  final _manual = TextEditingController();

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  void _add(String value) {
    c.addIngredient(value);
    _manual.clear();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        title: const Text('Find by ingredients'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Start over',
            onPressed: c.reset,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final img = c.image.value;
              return Container(
                height: 180,
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  image: img == null
                      ? null
                      : DecorationImage(image: FileImage(img), fit: BoxFit.cover),
                ),
                child: img != null
                    ? null
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined,
                                size: AppSizes.iconXl, color: t.textTertiary),
                            const SizedBox(height: AppSizes.sm),
                            Text('Scan or add ingredients below',
                                style: text.bodySmall
                                    ?.copyWith(color: t.textSecondary)),
                          ],
                        ),
                      ),
              );
            }),
            const SizedBox(height: AppSizes.smd),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => c.pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined,
                      size: AppSizes.iconSm),
                  label: const Text('Camera'),
                ),
              ),
              const SizedBox(width: AppSizes.smd),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => c.pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined, size: AppSizes.iconSm),
                  label: const Text('Gallery'),
                ),
              ),
            ]),

            if (!c.modelReady)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.smd),
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.smd),
                  decoration: BoxDecoration(
                    color: t.brandTint,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        size: AppSizes.iconMd, color: t.onBrandTint),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        'Automatic detection is coming soon. Add ingredients '
                        'manually for now.',
                        style: text.labelSmall?.copyWith(color: t.onBrandTint),
                      ),
                    ),
                  ]),
                ),
              ),

            const SizedBox(height: AppSizes.lg),
            Text('Ingredients', style: text.titleLarge?.copyWith(fontSize: 17)),
            const SizedBox(height: AppSizes.sm),

            Row(children: [
              Expanded(
                child: TextField(
                  controller: _manual,
                  onChanged: c.suggest,
                  onSubmitted: _add,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(hintText: 'e.g. potato'),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              IconButton(
                icon: Icon(Icons.add_circle, color: t.brand, size: 32),
                tooltip: 'Add ingredient',
                onPressed: () => _add(_manual.text),
              ),
            ]),

            // Autocomplete matters more than it looks: picking a name that
            // exists in the data is what stops "potato" from missing recipes
            // stored as "aloo".
            Obx(() {
              if (c.suggestions.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: AppSizes.sm),
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  children: c.suggestions
                      .map((name) => ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            leading: IngredientIcon(name: name, size: 22),
                            title: Text(name, style: text.bodyMedium),
                            trailing: Icon(Icons.add,
                                size: AppSizes.iconMd, color: t.onBrandTint),
                            onTap: () => _add(name),
                          ))
                      .toList(),
                ),
              );
            }),

            const SizedBox(height: AppSizes.smd),

            Obx(() {
              if (c.isDetecting.value) {
                return const Padding(
                  padding: EdgeInsets.all(AppSizes.smd),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (c.ingredients.isEmpty) {
                return Text('No ingredients added yet',
                    style: text.bodySmall?.copyWith(color: t.textSecondary));
              }
              return Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: c.ingredients
                    .map((name) => Chip(
                          avatar: IngredientIcon(
                              name: name, size: 18, tile: false),
                          label: Text(name),
                          backgroundColor: t.accentTint,
                          side: BorderSide.none,
                          labelStyle:
                              text.labelSmall?.copyWith(color: t.onAccentTint),
                          deleteIconColor: t.onAccentTint,
                          onDeleted: () => c.removeIngredient(name),
                        ))
                    .toList(),
              );
            }),

            const SizedBox(height: AppSizes.lg),
            Obx(() => PrimaryButton(
                  label: 'Find recipes',
                  loading: c.isSearching.value,
                  onTap: c.findRecipes,
                )),

            const SizedBox(height: AppSizes.lg),
            Obx(() {
              if (!c.searched.value) return const SizedBox.shrink();
              if (c.results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Center(
                    child: Text('No recipes match those ingredients',
                        style: text.bodyMedium?.copyWith(color: t.textSecondary)),
                  ),
                );
              }
              final ready = c.results
                  .where((r) => (r['missing_count'] ?? 0) == 0)
                  .toList();
              final almost = c.results
                  .where((r) => (r['missing_count'] ?? 0) > 0)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ready.isNotEmpty) ...[
                    _ResultHeader(
                      title: 'You can make these now',
                      count: ready.length,
                    ),
                    ..._cards(ready),
                    const SizedBox(height: AppSizes.lg),
                  ],
                  if (almost.isNotEmpty) ...[
                    _ResultHeader(
                      title: 'Almost there',
                      subtitle: 'A few ingredients short',
                      count: almost.length,
                    ),
                    // No separate "Missing: x, y" line any more — RecipeCard
                    // renders the match meter and names the missing item
                    // itself whenever the scan RPC returns those fields.
                    ..._cards(almost),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

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

  List<Widget> _cards(List<Map<String, dynamic>> rows) => [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.smd),
            child: RecipeCard(
              recipe: r,
              onAddMissing: () => _addMissing(r),
              onTap: () => Get.to(() => RecipeDetailsView(recipeId: r['id'])),
            ),
          ),
      ];
}

class _ResultHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int count;

  const _ResultHeader({required this.title, this.subtitle, required this.count});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleLarge?.copyWith(fontSize: 17)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!,
                        style: text.bodySmall?.copyWith(color: t.textSecondary)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm, vertical: AppSizes.xxs),
            decoration: BoxDecoration(
              color: t.successTint,
              borderRadius: BorderRadius.circular(AppSizes.radiusPill),
            ),
            child: Text('$count',
                style: text.labelSmall?.copyWith(
                    color: t.onSuccessTint, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
