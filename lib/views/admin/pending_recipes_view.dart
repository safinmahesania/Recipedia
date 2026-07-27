import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../shared/widgets/skeletons.dart';
import '../../theme/app_tokens.dart';
import '../recipes/recipe_details_view.dart';

/// Approval queue. Oldest first — a submission that has waited four days is
/// more urgent than one from this morning, and sorting newest-first buried it.
class PendingRecipesView extends StatefulWidget {
  const PendingRecipesView({super.key});

  @override
  State<PendingRecipesView> createState() => _PendingRecipesViewState();
}

class _PendingRecipesViewState extends State<PendingRecipesView> {
  final AdminController c = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    c.loadPending();
  }

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
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        titleSpacing: AppSizes.screenPad,
        title: Obx(() {
          final n = c.pending.length;
          final oldest = c.pending.isEmpty ? '' : _ago(c.pending.first['created_at']);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Pending', style: text.titleLarge),
              Text(
                n == 0
                    ? 'Nothing waiting'
                    : '$n waiting${oldest.isEmpty ? '' : ' · oldest $oldest'}',
                style: text.labelSmall?.copyWith(color: t.textSecondary),
              ),
            ],
          );
        }),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 52, card: true);
        }
        if (c.pending.isEmpty) {
          return const EmptyState(
            icon: 'inbox_outlined',
            title: 'Queue is clear',
            message: 'Nothing is waiting for review.',
          );
        }

        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadPending,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPad),
            itemCount: c.pending.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
            itemBuilder: (_, i) {
              final r = c.pending[i];
              final id = r['id'] as String;
              final author =
                  (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'Unknown';
              final category =
                  ((r['categories'] as Map?)?['name'] ?? '') as String;
              final diet = (r['diet'] ?? '') as String;
              final items = (r['recipe_ingredients'] as List?)?.length ?? 0;
              final noPhoto = (r['image_url'] ?? '').toString().trim().isEmpty;

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
                    Text((r['title'] ?? '') as String,
                        style: text.titleLarge?.copyWith(fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('by $author · ${_ago(r['created_at'])}',
                        style:
                            text.labelSmall?.copyWith(color: t.textSecondary)),
                    const SizedBox(height: AppSizes.smd),
                    // At-a-glance meta so most decisions need no drill-in.
                    Wrap(
                      spacing: AppSizes.xs,
                      runSpacing: AppSizes.xs,
                      children: [
                        if (diet.isNotEmpty) _Tag(diet, accent: true),
                        if (category.isNotEmpty) _Tag(category),
                        _Tag('$items items'),
                        if (noPhoto) _Tag('No photo', warn: true),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize:
                                const Size.fromHeight(AppSizes.buttonHeightSm),
                          ),
                          onPressed: () =>
                              Get.to(() => RecipeDetailsView(recipeId: id)),
                          child: const Text('Review'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: t.error,
                            minimumSize:
                                const Size.fromHeight(AppSizes.buttonHeightSm),
                          ),
                          onPressed: () => _rejectDialog(context, c, id),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: FilledButton(
                          // Tinted, not solid green: the raw success hue is
                          // 2.38:1 with white on it.
                          style: FilledButton.styleFrom(
                            backgroundColor: t.successTint,
                            foregroundColor: t.onSuccessTint,
                            minimumSize:
                                const Size.fromHeight(AppSizes.buttonHeightSm),
                          ),
                          onPressed: () => c.approve(id),
                          child: const Text('Approve'),
                        ),
                      ),
                    ]),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }

  void _rejectDialog(BuildContext context, AdminController c, String recipeId) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Reject recipe'),
        content: TextField(
          controller: reason,
          maxLines: 3,
          decoration: const InputDecoration(
              hintText: 'Tell them what to fix — this is shown to the author'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              c.reject(recipeId, reason.text.trim());
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dctx).colorScheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    ).then((_) => reason.dispose());
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final bool accent;
  final bool warn;
  const _Tag(this.label, {this.accent = false, this.warn = false});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bg = warn ? t.warningTint : (accent ? t.accentTint : t.surface);
    final fg = warn ? t.onWarningTint : (accent ? t.onAccentTint : t.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm, vertical: AppSizes.xxs),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
      child: Text(label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w600)),
    );
  }
}
