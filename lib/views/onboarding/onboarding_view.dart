import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/onboarding_controller.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';
import '../home/main_shell.dart';
import '../scan/scan_view.dart';
import '../../shared/widgets/app_icon.dart';

/// Three preference steps, then a confirmation.
///
/// This is FR5 from the original requirements — onboarding personalization —
/// which was dropped somewhere between the spec and the build. Every answer
/// writes to a column that already exists, and each one changes what the app
/// actually does: diet filters the catalogue, allergies drive the warn/hide
/// behaviour, staples stop counting against scan matches.
class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final OnboardingController c = Get.put(OnboardingController());
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _finish() => Get.offAll(() => const MainShell());

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Obx(() {
          if (c.done.value) return _Done(onStart: _finish, controller: c);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(controller: c),
              Expanded(
                child: switch (c.step.value) {
                  0 => _DietStep(controller: c),
                  1 => _AllergyStep(controller: c, search: _search),
                  _ => _StapleStep(controller: c),
                },
              ),
              _Footer(controller: c),
            ],
          );
        }),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final OnboardingController controller;
  const _Header({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    // Own Obx: this widget's build runs outside the parent's tracking scope,
    // so reading step.value up there would never subscribe.
    return Obx(() {
      final step = controller.step.value;
      return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPad, AppSizes.md, AppSizes.screenPad, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (step > 0)
                GestureDetector(
                  onTap: controller.back,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const AppIcon('arrow_back', fallback: Icons.arrow_back, size: AppSizes.iconMd),
                  ),
                )
              else
                const SizedBox(width: 38, height: 38),
              Text('Step ${step + 1} of ${OnboardingController.totalSteps}',
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSizes.smd),
          Row(
            children: List.generate(
              OnboardingController.totalSteps,
              (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i == OnboardingController.totalSteps - 1
                          ? 0
                          : AppSizes.xs + 1),
                  child: AnimatedContainer(
                    duration: AppSizes.durBase,
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= step ? t.brandFill : t.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    });
  }
}

// ---------------------------------------------------------------- diet
class _DietStep extends StatelessWidget {
  final OnboardingController controller;
  const _DietStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Obx(() => ListView(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.lg,
          AppSizes.screenPad, AppSizes.md),
      children: [
        Text('How do you eat?', style: text.headlineMedium),
        const SizedBox(height: AppSizes.sm),
        Text('We will use this as your default filter. You can change it any '
            'time from your profile.',
            style: text.bodyMedium?.copyWith(color: t.textSecondary)),
        const SizedBox(height: AppSizes.lg),
        if (controller.isLoading.value)
          const Center(child: Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: CircularProgressIndicator()))
        else ...[
          ...controller.diets.map((d) {
            final label = (d['value'] ?? '') as String;
            final count = d['recipe_count'];
            return _Choice(
              label: label,
              subtitle: count == null ? null : '$count recipes',
              selected: controller.diet.value == label,
              onTap: () => controller.setDiet(label),
            );
          }),
          _Choice(
            label: 'No preference',
            subtitle: 'Show me everything',
            selected: controller.diet.value == 'any',
            onTap: () => controller.setDiet('any'),
          ),
        ],
      ],
    ));
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.smd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: AnimatedContainer(
          duration: AppSizes.durFast,
          padding: const EdgeInsets.all(AppSizes.md),
          decoration: BoxDecoration(
            color: t.surfaceRaised,
            border: Border.all(
                color: selected ? t.brand : t.cardBorder,
                width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            boxShadow: t.cardShadow,
          ),
          child: Row(
            children: [
              IngredientIcon(name: label, size: 22),
              const SizedBox(width: AppSizes.smd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: text.titleMedium),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(subtitle!,
                            style: text.labelSmall
                                ?.copyWith(color: t.textSecondary)),
                      ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? t.brandFill : Colors.transparent,
                  border: selected
                      ? null
                      : Border.all(color: t.borderStrong, width: 2),
                ),
                child: selected
                    ? AppIcon('check', fallback: Icons.check, size: 14, color: t.onBrandFill)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- allergies
class _AllergyStep extends StatelessWidget {
  final OnboardingController controller;
  final TextEditingController search;
  const _AllergyStep({required this.controller, required this.search});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Obx(() => ListView(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.lg,
          AppSizes.screenPad, AppSizes.md),
      children: [
        Text('Anything to avoid?', style: text.headlineMedium),
        const SizedBox(height: AppSizes.sm),
        Text('Skip this if none apply.',
            style: text.bodyMedium?.copyWith(color: t.textSecondary)),
        const SizedBox(height: AppSizes.md),
        TextField(
          controller: search,
          onChanged: controller.search,
          decoration: const InputDecoration(
            hintText: 'Search an ingredient',
            prefixIcon: AppIcon('search', fallback: Icons.search, size: AppSizes.iconMd),
          ),
        ),
        if (controller.searchResults.isNotEmpty) ...[
          const SizedBox(height: AppSizes.sm),
          Container(
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Column(
              children: controller.searchResults.map((ing) {
                final id = ing['id'] as String;
                return ListTile(
                  dense: true,
                  leading: IngredientIconFromRow(row: ing, size: 20),
                  title: Text((ing['name'] ?? '') as String,
                      style: text.bodyMedium),
                  trailing: Icon(
                      controller.isAllergy(id) ? Icons.check : Icons.add,
                      size: AppSizes.iconMd,
                      color: t.onBrandTint),
                  onTap: () {
                    controller.toggleAllergy(ing);
                    search.clear();
                    controller.searchResults.clear();
                  },
                );
              }).toList(),
            ),
          ),
        ],
        if (controller.allergies.isNotEmpty) ...[
          const SizedBox(height: AppSizes.md),
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: controller.allergies
                .map((a) => Chip(
                      avatar: IngredientIconFromRow(row: a, size: 16, tile: false),
                      label: Text((a['name'] ?? '') as String),
                      backgroundColor: t.errorTint,
                      side: BorderSide.none,
                      labelStyle:
                          text.labelSmall?.copyWith(color: t.onErrorTint),
                      deleteIconColor: t.onErrorTint,
                      onDeleted: () => controller.toggleAllergy(a),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: AppSizes.lg),
        Text('COMMON',
            style: text.labelSmall?.copyWith(
                color: t.textTertiary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: AppSizes.smd),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: controller.allergenOptions.map((ing) {
            final id = ing['id'] as String;
            final on = controller.isAllergy(id);
            return GestureDetector(
              onTap: () => controller.toggleAllergy(ing),
              child: AnimatedContainer(
                duration: AppSizes.durFast,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.smd, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: on ? t.errorTint : t.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IngredientIconFromRow(row: ing, size: 16, tile: false),
                  const SizedBox(width: AppSizes.sm),
                  Text((ing['name'] ?? '') as String,
                      style: text.labelSmall?.copyWith(
                          color: on ? t.onErrorTint : t.textSecondary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSizes.lg),
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
                      style:
                          text.labelSmall?.copyWith(color: t.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: controller.hideUnsafe.value,
              onChanged: (v) => controller.hideUnsafe.value = v,
            ),
          ]),
        ),
      ],
    ));
  }
}

// -------------------------------------------------------------- staples
class _StapleStep extends StatelessWidget {
  final OnboardingController controller;
  const _StapleStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Obx(() => ListView(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.lg,
          AppSizes.screenPad, AppSizes.md),
      children: [
        Text("What's always in\nyour kitchen?", style: text.headlineMedium),
        const SizedBox(height: AppSizes.sm),
        Text('These stop counting as missing when we match recipes, so your '
            'results get noticeably better.',
            style: text.bodyMedium?.copyWith(color: t.textSecondary)),
        const SizedBox(height: AppSizes.md),
        Wrap(
          spacing: AppSizes.sm,
          runSpacing: AppSizes.sm,
          children: controller.stapleOptions.map((ing) {
            final id = ing['id'] as String;
            final on = controller.staples.contains(id);
            return GestureDetector(
              onTap: () => controller.toggleStaple(id),
              child: AnimatedContainer(
                duration: AppSizes.durFast,
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.smd, vertical: AppSizes.sm),
                decoration: BoxDecoration(
                  color: on ? t.brandTint : t.surface,
                  borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  IngredientIconFromRow(row: ing, size: 16, tile: false),
                  const SizedBox(width: AppSizes.sm),
                  Text((ing['name'] ?? '') as String,
                      style: text.labelSmall?.copyWith(
                          color: on ? t.onBrandTint : t.textSecondary,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
            );
          }).toList(),
        ),
        if (controller.staples.isNotEmpty) ...[
          const SizedBox(height: AppSizes.lg),
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: t.accentTint,
              borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            ),
            child: Row(children: [
              AppIcon('auto_awesome', fallback: Icons.auto_awesome,
                  size: AppSizes.iconLg, color: t.onAccentTint),
              const SizedBox(width: AppSizes.smd),
              Expanded(
                child: Text(
                  '${controller.staples.length} staples marked. Recipes that '
                  'only needed these now count as ready to cook.',
                  style: text.bodyMedium?.copyWith(color: t.onAccentTint),
                ),
              ),
            ]),
          ),
        ],
      ],
    ));
  }
}

// ----------------------------------------------------------------- done
class _Done extends StatelessWidget {
  final VoidCallback onStart;
  final OnboardingController controller;
  const _Done({required this.onStart, required this.controller});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          Center(
            child: Container(
              width: 104,
              height: 104,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.accentTint,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
              ),
              child: AppIcon('check_rounded', fallback: Icons.check_rounded, size: 52, color: t.onAccentTint),
            ),
          ),
          const SizedBox(height: AppSizes.lg),
          Text("You're all set", textAlign: TextAlign.center,
              style: text.headlineMedium),
          const SizedBox(height: AppSizes.sm),
          Text('Add a few ingredients and we will get straight to what you '
              'can cook tonight.',
              textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: t.textSecondary)),
          const SizedBox(height: AppSizes.lg),
          Row(children: [
            _Stat(label: 'Diet', value: controller.diet.value ?? 'any'),
            const SizedBox(width: AppSizes.sm),
            _Stat(label: 'Allergies', value: '${controller.allergies.length}'),
            const SizedBox(width: AppSizes.sm),
            _Stat(label: 'Staples', value: '${controller.staples.length}'),
          ]),
          const Spacer(),
          PrimaryButton(
            label: 'Scan my pantry',
            onTap: () {
              onStart();
              Get.to(() => const ScanView());
            },
          ),
          const SizedBox(height: AppSizes.smd),
          Center(
            child: TextButton(
                onPressed: onStart, child: const Text("I'll do this later")),
          ),
        ],
      ),
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
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleLarge?.copyWith(fontSize: 17)),
          const SizedBox(height: 1),
          Text(label,
              style: text.labelSmall?.copyWith(color: t.textSecondary)),
        ]),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  final OnboardingController controller;
  const _Footer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final onDiet = controller.step.value == 0;
      final canAdvance = !onDiet || controller.diet.value != null;
      return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.sm,
          AppSizes.screenPad, AppSizes.md),
      child: Row(children: [
        // Diet is the one step that cannot be skipped: a null diet_preference
        // is what marks a profile as never having been through onboarding.
        if (!onDiet)
          Expanded(
            child: OutlinedButton(
              onPressed: controller.isSaving.value ? null : controller.next,
              child: const Text('Skip'),
            ),
          ),
        if (!onDiet) const SizedBox(width: AppSizes.smd),
        Expanded(
          flex: onDiet ? 1 : 2,
          child: PrimaryButton(
            label: controller.step.value == OnboardingController.totalSteps - 1
                ? 'Finish setup'
                : 'Continue',
            loading: controller.isSaving.value,
            onTap: canAdvance ? controller.next : () {},
          ),
        ),
      ]),
    );
    });
  }
}
