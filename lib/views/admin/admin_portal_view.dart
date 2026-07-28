import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../controllers/admin_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../theme/app_tokens.dart';
import 'feedback_view.dart';
import 'manage_recipe_view.dart';
import 'pending_recipes_view.dart';
import 'reports_view.dart';
import 'users_view.dart';

/// Admin dashboard: what needs attention, then where to go.
///
/// The counts come first because an admin opens this to find out whether there
/// is anything to do — a list of five links answers that only after five taps.
class AdminPortalView extends StatefulWidget {
  const AdminPortalView({super.key});

  @override
  State<AdminPortalView> createState() => _AdminPortalViewState();
}

class _AdminPortalViewState extends State<AdminPortalView> {
  final AdminController c = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    c.loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        titleSpacing: AppSizes.screenPad,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppStrings.adminPortal, style: text.titleLarge),
            Text('Everything needing attention',
                style: text.labelSmall?.copyWith(color: t.textSecondary)),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: t.brand,
        onRefresh: c.loadCounts,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPad),
          children: [
            Obx(() {
              final n = c.counts;
              return GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSizes.smd,
                crossAxisSpacing: AppSizes.smd,
                childAspectRatio: 1.9,
                children: [
                  _Stat(
                    label: 'Pending',
                    value: n['pending'],
                    icon: 'pending_actions',
                    tint: t.warningTint,
                    onTint: t.onWarningTint,
                    onTap: () => Get.to(() => const PendingRecipesView()),
                  ),
                  _Stat(
                    label: 'Reports',
                    value: n['reports'],
                    icon: 'flag_outlined',
                    tint: t.errorTint,
                    onTint: t.onErrorTint,
                    onTap: () => Get.to(() => const ReportsView()),
                  ),
                  _Stat(
                    label: 'Recipes',
                    value: n['recipes'],
                    icon: 'menu_book_outlined',
                    tint: t.accentTint,
                    onTint: t.onAccentTint,
                    onTap: () => Get.to(() => const ManageRecipeView()),
                  ),
                  _Stat(
                    label: 'Users',
                    value: n['users'],
                    icon: 'people_outline',
                    tint: t.brandTint,
                    onTint: t.onBrandTint,
                    onTap: () => Get.to(() => const UsersView()),
                  ),
                ],
              );
            }),
            const SizedBox(height: AppSizes.lg),
            Text('MANAGE',
                style: text.labelSmall?.copyWith(
                    color: t.textTertiary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1)),
            const SizedBox(height: AppSizes.sm),
            Container(
              decoration: BoxDecoration(
                color: t.surfaceRaised,
                border: Border.all(color: t.cardBorder),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: t.cardShadow,
              ),
              child: Column(children: [
                Obx(() => _Row(
                      icon: 'pending_actions',
                      label: 'Pending approvals',
                      badge: c.counts['pending'],
                      badgeTint: t.warningTint,
                      badgeOn: t.onWarningTint,
                      onTap: () => Get.to(() => const PendingRecipesView()),
                    )),
                _Row(
                    icon: 'menu_book_outlined',
                    label: 'All recipes',
                    onTap: () => Get.to(() => const ManageRecipeView())),
                _Row(
                    icon: 'people_outline',
                    label: 'Users',
                    onTap: () => Get.to(() => const UsersView())),
                Obx(() => _Row(
                      icon: 'flag_outlined',
                      label: 'Reports',
                      badge: c.counts['reports'],
                      badgeTint: t.errorTint,
                      badgeOn: t.onErrorTint,
                      onTap: () => Get.to(() => const ReportsView()),
                    )),
                _Row(
                    icon: 'star_outline',
                    label: 'Reviews',
                    isLast: true,
                    onTap: () => Get.to(() => const FeedbackView())),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int? value;
  final String icon;
  final Color tint;
  final Color onTint;
  final VoidCallback onTap;

  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.onTint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.smd),
        decoration: BoxDecoration(
          color: t.surfaceRaised,
          border: Border.all(color: t.cardBorder),
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          boxShadow: t.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label.toUpperCase(),
                    style: text.labelSmall?.copyWith(
                        color: t.textTertiary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                AppIcon(icon,
                    size: AppSizes.iconSm,
                    color: onTint),
              ],
            ),
            const Spacer(),
            // A dash rather than 0 while loading: zero pending is good news and
            // should not be shown before it is true.
            Text(value?.toString() ?? '—',
                style: text.headlineMedium?.copyWith(fontSize: 26)),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String icon;
  final String label;
  final int? badge;
  final Color? badgeTint;
  final Color? badgeOn;
  final bool isLast;
  final VoidCallback onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeTint,
    this.badgeOn,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.smd),
        decoration: BoxDecoration(
          border:
              isLast ? null : Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(children: [
          AppIcon(icon,
              size: AppSizes.iconMd,
              color: t.textSecondary),
          const SizedBox(width: AppSizes.smd),
          Expanded(child: Text(label, style: text.bodyLarge)),
          if (badge != null && badge! > 0)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm, vertical: AppSizes.xxs),
              decoration: BoxDecoration(
                color: badgeTint,
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text('$badge',
                  style: text.labelSmall?.copyWith(
                      color: badgeOn, fontWeight: FontWeight.w700)),
            )
          else
            AppIcon('chevron_right', color: t.borderStrong),
        ]),
      ),
    );
  }
}
