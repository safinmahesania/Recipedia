import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/profile_controller.dart';
import '../../theme/app_tokens.dart';
import '../admin/admin_portal_view.dart';
import 'diet_allergies_view.dart';
import '../shopping/shopping_list_view.dart';
import '../submissions/my_submissions_view.dart';
import 'settings_view.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
          final p = c.profile.value;

          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.lg,
                AppSizes.screenPad, AppSizes.xl),
            children: [
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
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: t.brandFill,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: t.canvas, width: 2),
                              ),
                              child: Icon(Icons.camera_alt,
                                  size: 13, color: t.onBrandFill),
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
                  icon: Icons.edit_note,
                  label: 'My submissions',
                  onTap: () => Get.to(() => const MySubmissionsView()),
                ),
                _Tile(
                  icon: Icons.star_outline,
                  label: 'My reviews',
                  trailingText: '${c.reviewCount.value}',
                  onTap: () => _soon('My reviews'),
                ),
                _Tile(
                  icon: Icons.eco_outlined,
                  label: 'Diet and allergies',
                  trailingText: p?.dietPreference ?? 'Any',
                  onTap: () => Get.to(() => const DietAllergiesView()),
                ),
                _Tile(
                  icon: Icons.shopping_basket_outlined,
                  label: 'Shopping list',
                  onTap: () => Get.to(() => const ShoppingListView()),
                  isLast: true,
                ),
              ]),
              const SizedBox(height: AppSizes.md),
              _GroupLabel('APP'),
              _Group(children: [
                _Tile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Appearance',
                  trailingText: _themeLabel(p?.themeMode ?? 'system'),
                  onTap: () => _themeSheet(context, c),
                ),
                _Tile(
                  icon: Icons.notifications_none,
                  label: 'Notifications',
                  onTap: () => _soon('Notifications'),
                ),
                _Tile(
                  icon: Icons.shield_outlined,
                  label: 'Account and security',
                  onTap: () => _soon('Account and security'),
                  isLast: true,
                ),
              ]),
              if (p?.isAdmin == true) ...[
                const SizedBox(height: AppSizes.md),
                _GroupLabel('ADMIN'),
                _Group(children: [
                  _Tile(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Admin portal',
                    onTap: () => Get.to(() => const AdminPortalView()),
                    isLast: true,
                  ),
                ]),
              ],
              const SizedBox(height: AppSizes.md),
              _Group(children: [
                _Tile(
                  icon: Icons.settings_outlined,
                  label: 'More settings',
                  onTap: () => Get.to(() => const SettingsView()),
                  isLast: true,
                ),
              ]),
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
  static void _soon(String what) =>
      Get.snackbar('Coming next', '$what is being built.');

  void _avatarSheet(BuildContext context, ProfileController c) {
    Get.bottomSheet(
      SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Get.back();
                c.changeAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
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
                    ? const Icon(Icons.check)
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
  final IconData icon;
  final String label;
  final String? trailingText;
  final VoidCallback onTap;
  final bool isLast;

  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.isLast = false,
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
            Icon(icon, size: AppSizes.iconMd, color: t.textSecondary),
            const SizedBox(width: AppSizes.smd),
            Expanded(child: Text(label, style: text.bodyMedium)),
            if (trailingText != null)
              Text(trailingText!,
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            const SizedBox(width: AppSizes.xs),
            Icon(Icons.chevron_right,
                size: AppSizes.iconMd, color: t.borderStrong),
          ],
        ),
      ),
    );
  }
}
