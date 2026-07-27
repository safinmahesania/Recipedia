import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/submission_controller.dart';
import '../../theme/app_tokens.dart';
import 'submit_recipe_view.dart';
import '../../shared/widgets/skeletons.dart';

/// The user's own submissions and where each one stands.
///
/// StatefulWidget because loadMySubmissions() was being called straight from
/// build() — every rebuild fired another network request.
class MySubmissionsView extends StatefulWidget {
  const MySubmissionsView({super.key});

  @override
  State<MySubmissionsView> createState() => _MySubmissionsViewState();
}

class _MySubmissionsViewState extends State<MySubmissionsView> {
  final SubmissionController c = Get.put(SubmissionController());

  @override
  void initState() {
    super.initState();
    c.loadMySubmissions();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('My submissions')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const SubmitRecipeView()),
        backgroundColor: t.brandFill,
        foregroundColor: t.onBrandFill,
        tooltip: 'Add a recipe',
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 52, card: true);
        }
        if (c.mySubmissions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note,
                      size: AppSizes.iconXl, color: t.borderStrong),
                  const SizedBox(height: AppSizes.smd),
                  Text('Nothing submitted yet',
                      style: text.titleLarge?.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Share a recipe you cook often — an admin reviews it before '
                    'it goes live.',
                    textAlign: TextAlign.center,
                    style: text.bodySmall?.copyWith(color: t.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadMySubmissions,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPad),
            itemCount: c.mySubmissions.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
            itemBuilder: (_, i) {
              final r = c.mySubmissions[i];
              final status = (r['status'] ?? 'pending') as String;
              final canEdit = status != 'approved';
              final reason = (r['rejection_reason'] ?? '').toString();

              return Container(
                padding: const EdgeInsets.all(AppSizes.md),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text((r['title'] ?? '') as String,
                              style: text.titleMedium),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        _StatusChip(status),
                      ],
                    ),
                    if (status == 'rejected' && reason.isNotEmpty) ...[
                      const SizedBox(height: AppSizes.smd),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSizes.smd),
                        decoration: BoxDecoration(
                          color: t.errorTint,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusSm),
                        ),
                        child: Text('Reason: $reason',
                            style: text.labelSmall
                                ?.copyWith(color: t.onErrorTint)),
                      ),
                    ],
                    const SizedBox(height: AppSizes.sm),
                    if (canEdit)
                      Row(children: [
                        TextButton.icon(
                          onPressed: () =>
                              Get.to(() => SubmitRecipeView(existing: r)),
                          icon: const Icon(Icons.edit_outlined,
                              size: AppSizes.iconSm),
                          label: const Text('Edit'),
                          style: TextButton.styleFrom(
                              foregroundColor: t.textSecondary),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, c, r['id'] as String),
                          icon: const Icon(Icons.delete_outline,
                              size: AppSizes.iconSm),
                          label: const Text('Delete'),
                          style: TextButton.styleFrom(foregroundColor: t.error),
                        ),
                      ])
                    else
                      Text('Published — edits go back for review',
                          style: text.labelSmall
                              ?.copyWith(color: t.textSecondary)),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _confirmDelete(
      BuildContext context, SubmissionController c, String id) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete submission'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              c.delete(id);
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Status uses the tint + on-tint pairs rather than a raw hue at 12% opacity.
/// The raw success and warning hues are 2.38:1 and 2.03:1 on white — as label
/// text on a pale wash they were unreadable.
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip(this.status);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    late final Color bg, fg;
    switch (status) {
      case 'approved':
        bg = t.successTint;
        fg = t.onSuccessTint;
        break;
      case 'rejected':
        bg = t.errorTint;
        fg = t.onErrorTint;
        break;
      default:
        bg = t.warningTint;
        fg = t.onWarningTint;
    }
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
      ),
      child: Text(
        status == 'approved' ? 'Live' : status,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}
