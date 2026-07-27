import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';
import '../../shared/widgets/app_icon.dart';
import '../recipes/recipe_details_view.dart';

/// Moderation queue for reported recipes, reviews and users.
class ReportsView extends StatefulWidget {
  const ReportsView({super.key});

  @override
  State<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<ReportsView> {
  final AdminController c = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    c.loadReports();
  }

  String _ago(dynamic iso) {
    final t = DateTime.tryParse((iso ?? '').toString());
    if (t == null) return '';
    final d = DateTime.now().difference(t);
    if (d.inDays >= 1) return ' · ${d.inDays} d ago';
    if (d.inHours >= 1) return ' · ${d.inHours} h ago';
    return ' · just now';
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
          final open = c.reports.where((r) => r['status'] == 'open').length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Reports', style: Theme.of(context).textTheme.titleLarge),
              Text(open == 0 ? 'Nothing open' : '$open open',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.tokens.textSecondary)),
            ],
          );
        }),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 0, card: true);
        }
        if (c.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon('flag_outlined', fallback: Icons.flag_outlined,
                    size: AppSizes.iconXl, color: t.borderStrong),
                const SizedBox(height: AppSizes.smd),
                Text('Nothing reported',
                    style: text.bodyMedium?.copyWith(color: t.textSecondary)),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadReports,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.screenPad),
            itemCount: c.reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.smd),
            itemBuilder: (_, i) {
              final r = c.reports[i];
              final reporter =
                  (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'User';
              final open = r['status'] == 'open';

              // The spine is a child, not a border. BoxDecoration asserts a
              // borderRadius needs uniform border colours, so a coloured left
              // edge with hairline sides is invalid — as is color + gradient,
              // which was the previous attempt. Clip a strip inside instead:
              // valid, and it hugs the corner radius properly.
              return Container(
                decoration: BoxDecoration(
                  color: t.surfaceRaised,
                  border: Border.all(color: t.cardBorder),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: t.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (open) Container(width: 3, color: t.warning),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm, vertical: AppSizes.xxs),
                        decoration: BoxDecoration(
                          color: t.brandTint,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text((r['target_type'] ?? '') as String,
                            style: text.labelSmall?.copyWith(
                                color: t.onBrandTint,
                                fontWeight: FontWeight.w700)),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm, vertical: AppSizes.xxs),
                        decoration: BoxDecoration(
                          color: open ? t.warningTint : t.surface,
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusPill),
                        ),
                        child: Text((r['status'] ?? '') as String,
                            style: text.labelSmall?.copyWith(
                                color: open
                                    ? t.onWarningTint
                                    : t.textSecondary,
                                fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: AppSizes.smd),
                    if ((r['target_title'] ?? '').toString().isNotEmpty) ...[
                      Text((r['target_title']) as String,
                          style: text.titleMedium),
                      const SizedBox(height: AppSizes.xs),
                    ],
                    Text((r['reason'] ?? '') as String,
                        style: text.bodyLarge?.copyWith(height: 1.45)),
                    const SizedBox(height: AppSizes.xs),
                    Text('reported by $reporter${_ago(r['created_at'])}',
                        style:
                            text.labelSmall?.copyWith(color: t.textSecondary)),
                    if (open) ...[
                      const SizedBox(height: AppSizes.smd),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                  AppSizes.buttonHeightSm),
                            ),
                            onPressed: () =>
                                c.resolveReport(r['id'] as String, 'dismissed'),
                            child: const Text('Dismiss'),
                          ),
                        ),
                        if (r['target_type'] == 'recipe' &&
                            r['target_id'] != null) ...[
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(
                                    AppSizes.buttonHeightSm),
                              ),
                              // Judging a report without seeing what was
                              // reported is guesswork.
                              onPressed: () => Get.to(() => RecipeDetailsView(
                                  recipeId: r['target_id'] as String)),
                              child: const Text('Open recipe'),
                            ),
                          ),
                        ],
                        const SizedBox(width: AppSizes.smd),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(
                                  AppSizes.buttonHeightSm),
                            ),
                            onPressed: () =>
                                c.resolveReport(r['id'] as String, 'resolved'),
                            child: const Text('Resolve'),
                          ),
                        ),
                      ]),
                    ],
                  ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
