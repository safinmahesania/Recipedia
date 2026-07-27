import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/submission_controller.dart';
import '../../theme/app_tokens.dart';
import 'submit_recipe_view.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';

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

  /// null = all. Kept in the widget rather than the controller because it is
  /// pure view state — nothing else needs to know which tab is open.
  final _filter = Rxn<String>();

  int _countOf(String? status) => status == null
      ? c.mySubmissions.length
      : c.mySubmissions.where((r) => (r['status'] ?? 'pending') == status).length;

  List<Map<String, dynamic>> get _visible => _filter.value == null
      ? c.mySubmissions.toList()
      : c.mySubmissions
          .where((r) => (r['status'] ?? 'pending') == _filter.value)
          .toList();

  /// "2 days ago" reads better than a timestamp on a queue you are waiting on.
  String _ago(dynamic iso) {
    final t = DateTime.tryParse((iso ?? '').toString());
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inDays >= 2) return '${d.inDays} days ago';
    if (d.inDays == 1) return 'yesterday';
    if (d.inHours >= 1) return '${d.inHours} h ago';
    return 'just now';
  }

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
        child: const AppIcon('add', fallback: Icons.add),
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
                  AppIcon('edit_note', fallback: Icons.edit_note,
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

        final rows = _visible;
        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadMySubmissions,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPad),
            itemCount: rows.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
            itemBuilder: (_, index) {
              if (index == 0) {
                return SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterTab(
                          label: 'All · ${_countOf(null)}',
                          selected: _filter.value == null,
                          onTap: () => _filter.value = null),
                      const SizedBox(width: AppSizes.sm),
                      _FilterTab(
                          label: 'Pending · ${_countOf('pending')}',
                          selected: _filter.value == 'pending',
                          onTap: () => _filter.value = 'pending'),
                      const SizedBox(width: AppSizes.sm),
                      _FilterTab(
                          label: 'Live · ${_countOf('approved')}',
                          selected: _filter.value == 'approved',
                          onTap: () => _filter.value = 'approved'),
                      const SizedBox(width: AppSizes.sm),
                      _FilterTab(
                          label: 'Changes · ${_countOf('rejected')}',
                          selected: _filter.value == 'rejected',
                          onTap: () => _filter.value = 'rejected'),
                    ],
                  ),
                );
              }
              final r = rows[index - 1];
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
                    if (_ago(r['created_at']).isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        status == 'approved'
                            ? 'Live'
                            : 'Submitted ${_ago(r['created_at'])}',
                        style: text.labelSmall
                            ?.copyWith(color: t.textSecondary),
                      ),
                    ],
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
                          icon: const AppIcon('edit_outlined', fallback: Icons.edit_outlined,
                              size: AppSizes.iconSm),
                          label: Text(status == 'rejected'
                              ? 'Edit and resubmit'
                              : 'Edit'),
                          style: TextButton.styleFrom(
                              foregroundColor: t.textSecondary),
                        ),
                        TextButton.icon(
                          onPressed: () =>
                              _confirmDelete(context, c, r['id'] as String),
                          icon: const AppIcon('delete_outline', fallback: Icons.delete_outline,
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

class _FilterTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppSizes.durFast,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? t.brandTint : t.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? t.onBrandTint : t.textSecondary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
