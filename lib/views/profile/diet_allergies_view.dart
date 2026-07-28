import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/preferences_controller.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';

/// Editing for the preferences onboarding collected. Every control here
/// changes what match_recipes_for_user returns on the next scan.
class DietAllergiesView extends StatefulWidget {
  const DietAllergiesView({super.key});

  @override
  State<DietAllergiesView> createState() => _DietAllergiesViewState();
}

class _DietAllergiesViewState extends State<DietAllergiesView> {
  final PreferencesController c = Get.put(PreferencesController());
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Diet and allergies')),
      body: Obx(() {
        if (c.isLoading.value) {
          return const BlockSkeleton();
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.md,
              AppSizes.screenPad, AppSizes.xxl),
          children: [
            _Label('DIET'),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                ...c.diets.map((d) {
                  final label = (d['value'] ?? '') as String;
                  return _Pill(
                    label: label,
                    on: c.diet.value == label,
                    onTap: () => c.setDiet(label),
                  );
                }),
                _Pill(
                  label: 'No preference',
                  on: c.diet.value == 'any',
                  onTap: () => c.setDiet('any'),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text('Applied as your default filter everywhere.',
                style: text.labelSmall?.copyWith(color: t.textSecondary)),

            const SizedBox(height: AppSizes.lg),
            _Label('DEFAULT CUISINE'),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                _Pill(
                  label: 'Any',
                  on: c.defaultCuisine.value == null,
                  onTap: () => c.setDefaultCuisine(null),
                ),
                ...c.cuisineOptions.take(10).map((cu) {
                  final name = (cu['value'] ?? '') as String;
                  return _Pill(
                    label: name,
                    on: c.defaultCuisine.value == name,
                    onTap: () => c.setDefaultCuisine(
                        c.defaultCuisine.value == name ? null : name),
                  );
                }),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text('Pre-selected when you open Recipes. Clearing the filter '
                'there still clears it.',
                style: text.labelSmall?.copyWith(color: t.textSecondary)),

            const SizedBox(height: AppSizes.lg),
            _Label('ALLERGIES'),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _search,
              onChanged: c.search,
              decoration: const InputDecoration(
                hintText: 'Search an ingredient',
                prefixIcon: FieldIcon('search'),
              ),
            ),
            if (c.searchResults.isNotEmpty) ...[
              const SizedBox(height: AppSizes.sm),
              Container(
                decoration: BoxDecoration(
                  color: t.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                ),
                child: Column(
                  children: c.searchResults.map((ing) {
                    return ListTile(
                      dense: true,
                      leading: IngredientIconFromRow(row: ing, size: 20),
                      title: Text((ing['name'] ?? '') as String,
                          style: text.bodyMedium),
                      trailing: Icon(
                          c.isAllergy(ing['id'] as String)
                              ? Icons.check
                              : Icons.add,
                          size: AppSizes.iconMd,
                          color: t.onBrandTint),
                      onTap: () {
                        c.toggleAllergy(ing);
                        _search.clear();
                        c.searchResults.clear();
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.smd),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                ...c.allergies.map((a) => _Pill(
                      label: (a['name'] ?? '') as String,
                      on: true,
                      danger: true,
                      row: a,
                      onTap: () => c.toggleAllergy(a),
                    )),
                ...c.allergenOptions
                    .where((o) => !c.isAllergy(o['id'] as String))
                    .map((o) => _Pill(
                          label: (o['name'] ?? '') as String,
                          on: false,
                          row: o,
                          onTap: () => c.toggleAllergy(o),
                        )),
              ],
            ),

            const SizedBox(height: AppSizes.md),
            Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: t.surfaceRaised,
                border: Border.all(color: t.cardBorder),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: t.cardShadow,
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hide unsafe recipes', style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text('Off shows a warning instead of removing them',
                          style: text.labelSmall
                              ?.copyWith(color: t.textSecondary)),
                    ],
                  ),
                ),
                Switch(
                  value: c.hideUnsafe.value,
                  onChanged: c.setHideUnsafe,
                ),
              ]),
            ),

            const SizedBox(height: AppSizes.lg),
            _Label('PANTRY STAPLES'),
            const SizedBox(height: AppSizes.xs),
            Text('Never counted as missing in scan results.',
                style: text.labelSmall?.copyWith(color: t.textSecondary)),
            const SizedBox(height: AppSizes.smd),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: c.stapleOptions.map((ing) {
                final id = ing['id'] as String;
                return _Pill(
                  label: (ing['name'] ?? '') as String,
                  on: c.staples.contains(id),
                  row: ing,
                  onTap: () => c.toggleStaple(id),
                );
              }).toList(),
            ),
          ],
        );
      }),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.tokens.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ));
}

class _Pill extends StatelessWidget {
  final String label;
  final bool on;
  final bool danger;
  final Map<String, dynamic>? row;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.on,
    required this.onTap,
    this.danger = false,
    this.row,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bg = danger ? t.errorTint : (on ? t.brandTint : t.surface);
    final fg = danger ? t.onErrorTint : (on ? t.onBrandTint : t.textSecondary);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSizes.durFast,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.smd, vertical: AppSizes.sm),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (row != null) ...[
            IngredientIconFromRow(row: row!, size: 16, tile: false),
            const SizedBox(width: AppSizes.sm),
          ],
          Text(label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: fg, fontWeight: FontWeight.w600)),
          if (danger) ...[
            const SizedBox(width: AppSizes.xs),
            AppIcon('close', size: AppSizes.iconXs + 2, color: fg),
          ],
        ]),
      ),
    );
  }
}
