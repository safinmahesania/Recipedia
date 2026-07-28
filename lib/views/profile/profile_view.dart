import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/profile_controller.dart';
import '../../theme/app_tokens.dart';
import '../admin/admin_portal_view.dart';
import 'account_security_view.dart';
import 'diet_allergies_view.dart';
import 'cooking_history_view.dart';
import 'edit_profile_view.dart';
import 'notifications_view.dart';
import 'my_reviews_view.dart';
import '../planner/meal_plan_view.dart';
import '../shopping/shopping_list_view.dart';
import '../submissions/my_submissions_view.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';
import '../../controllers/auth_controller.dart';
import 'about_view.dart';
import 'faq_view.dart';

/// Profile — identity, activity, and the settings that change how the app
/// behaves. Submissions and Admin were buried in Settings before, which is why
/// this screen felt empty while Settings did all the work.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController c = Get.put(ProfileController());
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      body: SafeArea(
        child: Obx(() {
          if (c.isLoading.value && c.profile.value == null) {
            return const ListSkeleton(count: 5, thumb: 40);
          }
          final p = c.profile.value;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.lg,
                AppSizes.screenPad, AppSizes.xl),
            children: [
              // Top-right, above the identity it edits — where a settings
              // affordance sits in most profile screens.
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Get.to(() => const EditProfileView()),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.surface,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: AppIcon('edit_outlined',
                        size: AppSizes.iconMd,
                        color: t.textSecondary),
                  ),
                ),
              ),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _avatarSheet(context, c),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CircleAvatar(
                            radius: 38,
                            backgroundColor: t.brandTint,
                            backgroundImage: (p?.avatarUrl != null &&
                                    p!.avatarUrl!.isNotEmpty)
                                ? NetworkImage(p.avatarUrl!)
                                : null,
                            child: (p?.avatarUrl == null ||
                                    p!.avatarUrl!.isEmpty)
                                ? Text(p?.initial ?? '?',
                                    style: text.headlineMedium
                                        ?.copyWith(color: t.onBrandTint))
                                : null,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              width: 22,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: t.brandFill,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: t.canvas, width: 2),
                              ),
                              child: AppIcon('camera_alt',
                                  size: 11,
                                  color: t.onBrandFill),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSizes.smd),
                    Text(p?.name ?? 'Your name', style: text.titleLarge),
                    if (p?.username != null && p!.username!.isNotEmpty)
                      Text('@${p.username}',
                          style: text.bodySmall
                              ?.copyWith(color: t.textSecondary)),
                    Text(p?.email ?? '',
                        style:
                            text.bodySmall?.copyWith(color: t.textSecondary)),
                    if (p?.bio != null && p!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.sm),
                        child: Text(p.bio!,
                            textAlign: TextAlign.center,
                            style: text.bodySmall),
                      ),
                    if (p?.isAdmin == true)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSizes.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.smd,
                              vertical: AppSizes.xxs),
                          decoration: BoxDecoration(
                            color: t.accentTint,
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusPill),
                          ),
                          child: Text('Admin',
                              style: text.labelSmall
                                  ?.copyWith(color: t.onAccentTint)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              Row(
                children: [
                  _Stat(label: 'Saved', value: c.savedCount.value),
                  const SizedBox(width: AppSizes.sm),
                  _Stat(label: 'Submitted', value: c.submittedCount.value),
                  const SizedBox(width: AppSizes.sm),
                  _Stat(label: 'Reviews', value: c.reviewCount.value),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
              _GroupLabel('COOKING'),
              _Group(children: [
                _Tile(
                  icon: 'edit_note',
                  label: 'My submissions',
                  onTap: () => Get.to(() => const MySubmissionsView()),
                ),
                _Tile(
                  icon: 'local_fire_department',
                  label: 'Cooking history',
                  onTap: () => Get.to(() => const CookingHistoryView()),
                ),
                _Tile(
                  icon: 'star_outline',
                  label: 'My reviews',
                  trailingText: '${c.reviewCount.value}',
                  onTap: () => Get.to(() => const MyReviewsView()),
                ),
                _Tile(
                  icon: 'eco_outlined',
                  label: 'Diet and allergies',
                  trailingText: p?.dietPreference ?? 'Any',
                  onTap: () => Get.to(() => const DietAllergiesView()),
                ),
                _Tile(
                  icon: 'shopping_basket_outlined',
                  label: 'Shopping list',
                  onTap: () => Get.to(() => const ShoppingListView()),
                ),
                _Tile(
                  icon: 'calendar_month_outlined',
                  label: 'Meal planner',
                  onTap: () => Get.to(() => const MealPlanView()),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: AppSizes.md),
              _GroupLabel('APP'),
              _Group(children: [
                _Tile(
                  icon: 'dark_mode_outlined',
                  label: 'Appearance',
                  trailingText: _themeLabel(p?.themeMode ?? 'system'),
                  onTap: () => _themeSheet(context, c),
                ),
                _Tile(
                  icon: 'notifications_none',
                  label: 'Notifications',
                  onTap: () => Get.to(() => const NotificationsView()),
                ),
                _Tile(
                  icon: 'shield_outlined',
                  label: 'Account and security',
                  onTap: () => Get.to(() => const AccountSecurityView()),
                  isLast: true,
                ),
              ]),
              if (p?.isAdmin == true) ...[
                const SizedBox(height: AppSizes.md),
                _GroupLabel('ADMIN'),
                _Group(children: [
                  _Tile(
                    icon: 'admin_panel_settings_outlined',
                    label: 'Admin portal',
                    onTap: () => Get.to(() => const AdminPortalView()),
                    isLast: true,
                  ),
                ]),
              ],
              const SizedBox(height: AppSizes.md),
              _GroupLabel('SUPPORT'),
              _Group(children: [
                _Tile(
                  icon: 'help_outline',
                  label: 'FAQs',
                  onTap: () => Get.to(() => const FaqView()),
                ),
                _Tile(
                  icon: 'info_outline',
                  label: 'About Recipedia',
                  onTap: () => Get.to(() => const AboutView()),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: AppSizes.md),
              _Group(children: [
                _Tile(
                  icon: 'logout',
                  label: 'Log out',
                  danger: true,
                  onTap: () => _confirmLogout(context),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: AppSizes.lg),
              Center(
                child: Text('Recipedia 1.0.0',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.tokens.textTertiary)),
              ),
            ],
          );
        }),
      ),
    );
  }

  static String _themeLabel(String mode) => switch (mode) {
        'light' => 'Light',
        'dark' => 'Dark',
        _ => 'System',
      };

  // Screens land in the next batch; the tiles ship now so the structure is
  // reviewable and the routes are already in place.
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Log out'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.put(AuthController()).logout();
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dctx).colorScheme.error),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }

  void _avatarSheet(BuildContext context, ProfileController c) {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon('photo_library_outlined'),
              title: const Text('Choose from gallery'),
              onTap: () {
                Get.back();
                c.changeAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const AppIcon('photo_camera_outlined'),
              title: const Text('Take a photo'),
              onTap: () {
                Get.back();
                c.changeAvatar(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
      backgroundColor: context.tokens.surfaceRaised,
    );
  }

  void _themeSheet(BuildContext context, ProfileController c) {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ['system', 'light', 'dark'])
              ListTile(
                title: Text(_themeLabel(mode)),
                trailing: c.profile.value?.themeMode == mode
                    ? const AppIcon('check')
                    : null,
                onTap: () {
                  Get.back();
                  c.setThemeMode(mode);
                },
              ),
          ],
        ),
      ),
      backgroundColor: context.tokens.surfaceRaised,
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
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
        child: Column(
          children: [
            Text('$value', style: text.titleLarge),
            const SizedBox(height: 1),
            Text(label,
                style: text.labelSmall?.copyWith(color: t.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  final String text;
  const _GroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.sm, left: AppSizes.xs),
      child: Text(text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.tokens.textSecondary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              )),
    );
  }
}

class _Group extends StatelessWidget {
  final List<Widget> children;
  const _Group({required this.children});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surfaceRaised,
        border: Border.all(color: t.cardBorder),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        boxShadow: t.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _Tile extends StatelessWidget {
  final String icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  final bool isLast;

  /// Destructive rows read in the error colour and drop the chevron — there is
  /// nothing to navigate to.
  final bool danger;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.isLast = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.smd, vertical: AppSizes.smd),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: t.border)),
        ),
        child: Row(
          children: [
            AppIcon(icon,
                size: AppSizes.iconMd,
                color: danger ? t.error : t.textSecondary),
            const SizedBox(width: AppSizes.smd),
            Expanded(
              child: Text(label,
                  style: text.bodyMedium
                      ?.copyWith(color: danger ? t.error : null)),
            ),
            if (trailingText != null)
              Text(trailingText!,
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            if (!danger) ...[
              const SizedBox(width: AppSizes.xs),
              AppIcon('chevron_right',
                  size: AppSizes.iconMd,
                  color: t.borderStrong),
            ],
          ],
        ),
      ),
    );
  }
}