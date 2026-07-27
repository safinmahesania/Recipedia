import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/profile_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../theme/app_tokens.dart';

/// Notification preferences.
///
/// These three columns have existed since migration 9 with no way to change
/// them. Push delivery still needs Firebase, but the preference is the user's
/// decision and it should be recorded now — otherwise enabling FCM later means
/// either guessing or asking everyone again.
class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController c = Get.put(ProfileController());
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Notifications')),
      body: Obx(() {
        final p = c.profile.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.md,
              AppSizes.screenPad, AppSizes.xxl),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.smd),
              decoration: BoxDecoration(
                color: t.brandTint,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Row(children: [
                AppIcon('info_outline',
                    fallback: Icons.info_outline,
                    size: AppSizes.iconMd,
                    color: t.onBrandTint),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    'Push delivery is not live yet. Your choices are saved and '
                    'will apply as soon as it is.',
                    style: text.labelSmall?.copyWith(color: t.onBrandTint),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: AppSizes.lg),
            _Group(children: [
              _Toggle(
                icon: 'menu_book_outlined',
                title: 'New recipes',
                subtitle: 'When recipes matching your diet are added',
                value: p?.notifyNewRecipes ?? true,
                onChanged: (v) => c.setNotifyPref('notify_new_recipes', v),
              ),
              Divider(height: 1, color: t.border),
              _Toggle(
                icon: 'edit_note',
                title: 'Submission updates',
                subtitle: 'When your recipe is approved or needs changes',
                value: p?.notifySubmissionStatus ?? true,
                onChanged: (v) =>
                    c.setNotifyPref('notify_submission_status', v),
              ),
              Divider(height: 1, color: t.border),
              _Toggle(
                icon: 'rate_review_outlined',
                title: 'Review replies',
                subtitle: 'When someone responds to your review',
                value: p?.notifyReviewReplies ?? true,
                onChanged: (v) => c.setNotifyPref('notify_review_replies', v),
                isLast: true,
              ),
            ]),
          ],
        );
      }),
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
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        boxShadow: t.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(AppSizes.smd),
      child: Row(children: [
        AppIcon(icon,
            fallback: Icons.notifications_none,
            size: AppSizes.iconMd,
            color: t.textSecondary),
        const SizedBox(width: AppSizes.smd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: text.bodyLarge),
              const SizedBox(height: 1),
              Text(subtitle,
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ]),
    );
  }
}
