import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../theme/app_tokens.dart';

/// Approval queue for user-submitted recipes.
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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Pending submissions')),
      body: Obx(() {
        if (c.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.pending.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inbox_outlined,
                      size: AppSizes.iconXl, color: t.borderStrong),
                  const SizedBox(height: AppSizes.smd),
                  Text('Queue is clear',
                      style: text.titleLarge?.copyWith(fontSize: 16)),
                  const SizedBox(height: AppSizes.xs),
                  Text('Nothing is waiting for review.',
                      style:
                          text.bodySmall?.copyWith(color: t.textSecondary)),
                ],
              ),
            ),
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
              final author =
                  (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'Unknown';

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
                    Text('by $author',
                        style:
                            text.labelSmall?.copyWith(color: t.textSecondary)),
                    const SizedBox(height: AppSizes.smd),
                    Text((r['instructions'] ?? '') as String,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium
                            ?.copyWith(color: t.textSecondary, height: 1.45)),
                    const SizedBox(height: AppSizes.md),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: t.error,
                            minimumSize:
                                const Size.fromHeight(AppSizes.buttonHeightSm),
                          ),
                          onPressed: () =>
                              _rejectDialog(context, c, r['id'] as String),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.smd),
                      Expanded(
                        child: FilledButton(
                          // Tinted rather than a solid green fill: the raw
                          // success hue is 2.38:1 with white on it.
                          style: FilledButton.styleFrom(
                            backgroundColor: t.successTint,
                            foregroundColor: t.onSuccessTint,
                            minimumSize:
                                const Size.fromHeight(AppSizes.buttonHeightSm),
                          ),
                          onPressed: () => c.approve(r['id'] as String),
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

  void _rejectDialog(
      BuildContext context, AdminController c, String recipeId) {
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
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    ).then((_) => reason.dispose());
  }
}
