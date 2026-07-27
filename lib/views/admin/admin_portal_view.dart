import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../theme/app_tokens.dart';
import 'feedback_view.dart';
import 'manage_recipe_view.dart';
import 'pending_recipes_view.dart';
import 'reports_view.dart';
import 'users_view.dart';

/// Admin dashboard — entry point to every admin tool.
class AdminPortalView extends StatelessWidget {
  const AdminPortalView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    final items = <_Item>[
      _Item(Icons.restaurant_menu, 'Recipes', 'Add, edit, delete', 0,
          () => Get.to(() => const ManageRecipeView())),
      _Item(Icons.pending_actions, 'Pending submissions', 'Approve or reject', 1,
          () => Get.to(() => const PendingRecipesView())),
      _Item(Icons.people_outline, 'Users', 'View all users', 3,
          () => Get.to(() => const UsersView())),
      _Item(Icons.star_outline, 'Reviews', 'Ratings and comments', 2,
          () => Get.to(() => const FeedbackView())),
      _Item(Icons.flag_outlined, 'Reports', 'Moderation queue', 6,
          () => Get.to(() => const ReportsView())),
    ];

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text(AppStrings.adminPortal)),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.screenPad),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
        itemBuilder: (_, i) {
          final it = items[i];
          return InkWell(
            onTap: it.onTap,
            borderRadius: BorderRadius.circular(AppSizes.radiusLg),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: t.surfaceRaised,
                border: Border.all(color: t.cardBorder),
                borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                boxShadow: t.cardShadow,
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(AppSizes.smd),
                  decoration: BoxDecoration(
                    color: t.categoryTints[it.tint],
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Icon(it.icon, color: t.categoryGlyphs[it.tint]),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(it.subtitle,
                          style: text.labelSmall
                              ?.copyWith(color: t.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: t.borderStrong),
              ]),
            ),
          );
        },
      ),
    );
  }
}

class _Item {
  final IconData icon;
  final String title;
  final String subtitle;
  /// Index into the category tint ramp, so each tool reads as its own thing
  /// rather than five identical coral squares.
  final int tint;
  final VoidCallback onTap;
  _Item(this.icon, this.title, this.subtitle, this.tint, this.onTap);
}
