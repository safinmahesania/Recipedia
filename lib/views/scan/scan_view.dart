import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/scan_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import 'scan_results_view.dart';

/// "What do you have?" — ingredient entry, then matching.
///
/// Ingredient-first rather than camera-first: the model is not trained yet, so
/// leading with a camera promises something the app cannot do. Capture stays
/// available in the app bar for when it ships.
class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  final ScanController c = Get.put(ScanController());
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

  Future<void> _find() async {
    await c.findRecipes();
    if (!mounted) return;
    Get.to(() => const ScanResultsView());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        title: const Text('Scan'),
        actions: [
          IconButton(
            icon: const AppIcon('camera_alt', fallback: Icons.camera_alt),
            tooltip: 'Take a photo',
            onPressed: () => c.pickImage(ImageSource.camera),
          ),
          IconButton(
            icon: const AppIcon('image_outlined', fallback: Icons.image_outlined),
            tooltip: 'Pick a photo',
            onPressed: () => c.pickImage(ImageSource.gallery),
          ),
          IconButton(
            icon: const AppIcon('refresh', fallback: Icons.refresh),
            tooltip: 'Start over',
            onPressed: c.reset,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                    AppSizes.sm, AppSizes.screenPad, AppSizes.md),
                children: [
                  Text('What do you have?', style: text.headlineMedium),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    "Add ingredients and we'll rank what you can cook.",
                    style: text.bodyMedium?.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: AppSizes.md),

                  TextField(
                    controller: _manual,
                    onChanged: c.suggest,
                    onSubmitted: _add,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      hintText: 'Type an ingredient…',
                      prefixIcon:
                          AppIcon('search', fallback: Icons.search),
                    ),
                  ),

                  // Picking a real name is what stops "potato" missing recipes
                  // stored as "aloo".
                  Obx(() {
                    if (c.suggestions.isEmpty) return const SizedBox.shrink();
                    return Container(
                      margin: const EdgeInsets.only(top: AppSizes.sm),
                      decoration: BoxDecoration(
                        color: t.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Column(
                        children: c.suggestions
                            .map((name) => ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading:
                                      IngredientIcon(name: name, size: 20),
                                  title:
                                      Text(name, style: text.bodyMedium),
                                  trailing: AppIcon('add',
                                      fallback: Icons.add,
                                      size: AppSizes.iconMd,
                                      color: t.onBrandTint),
                                  onTap: () => _add(name),
                                ))
                            .toList(),
                      ),
                    );
                  }),

                  const SizedBox(height: AppSizes.lg),
                  Obx(() => _Eyebrow(
                      'Your pantry${c.ingredients.isEmpty ? '' : ' · ${c.ingredients.length}'}')),
                  const SizedBox(height: AppSizes.sm),
                  Obx(() {
                    if (c.isDetecting.value) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSizes.smd),
                        child: LinearProgressIndicator(minHeight: 3),
                      );
                    }
                    if (c.ingredients.isEmpty) {
                      return Text('Nothing added yet',
                          style: text.bodySmall
                              ?.copyWith(color: t.textTertiary));
                    }
                    return Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: c.ingredients
                          .map((name) => _Chip(
                                name: name,
                                onRemove: () => c.removeIngredient(name),
                              ))
                          .toList(),
                    );
                  }),

                  Obx(() {
                    if (c.staples.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: AppSizes.lg),
                        const _Eyebrow('Always in your kitchen'),
                        const SizedBox(height: AppSizes.xs),
                        Text('These never count as missing.',
                            style: text.labelSmall
                                ?.copyWith(color: t.textTertiary)),
                        const SizedBox(height: AppSizes.sm),
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: c.staples
                              .map((ing) => _Chip(
                                    name: (ing['name'] ?? '') as String,
                                    row: ing,
                                    muted: true,
                                  ))
                              .toList(),
                        ),
                      ],
                    );
                  }),

                  if (!c.modelReady) ...[
                    const SizedBox(height: AppSizes.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSizes.smd),
                      decoration: BoxDecoration(
                        color: t.brandTint,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: Row(children: [
                        AppIcon('info_outline',
                            fallback: Icons.info_outline,
                            size: AppSizes.iconMd,
                            color: t.onBrandTint),
                        const SizedBox(width: AppSizes.sm),
                        Expanded(
                          child: Text(
                            'Photo detection is coming. Type ingredients for '
                            'now — matching works the same either way.',
                            style: text.labelSmall
                                ?.copyWith(color: t.onBrandTint),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                  AppSizes.sm, AppSizes.screenPad, AppSizes.md),
              child: Obx(() => PrimaryButton(
                    label: 'Find recipes',
                    loading: c.isSearching.value,
                    onTap: c.ingredients.isEmpty ? () {} : _find,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  final String text;
  const _Eyebrow(this.text);

  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.tokens.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ));
}

class _Chip extends StatelessWidget {
  final String name;
  final Map<String, dynamic>? row;
  final VoidCallback? onRemove;
  final bool muted;

  const _Chip({
    required this.name,
    this.row,
    this.onRemove,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.only(
          left: AppSizes.sm, right: onRemove == null ? AppSizes.smd : AppSizes.xs),
      height: 34,
      decoration: BoxDecoration(
        color: muted ? t.surface : t.brandTint,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        row != null
            ? IngredientIconFromRow(row: row!, size: 18, tile: false)
            : IngredientIcon(name: name, size: 18, tile: false),
        const SizedBox(width: AppSizes.sm),
        Text(name,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: muted ? t.textSecondary : t.onBrandTint,
                fontWeight: FontWeight.w600)),
        if (onRemove != null)
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              child: AppIcon('close',
                  fallback: Icons.close,
                  size: AppSizes.iconSm,
                  color: t.onBrandTint),
            ),
          ),
      ]),
    );
  }
}
