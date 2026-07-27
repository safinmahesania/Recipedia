import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Reports')),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 0, card: true);
        }
        if (c.reports.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.flag_outlined,
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

              return Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: t.surfaceRaised,
                  // Open reports get a coloured left spine so the queue can be
                  // triaged without reading every card. A gradient cannot be
                  // used here: BoxDecoration asserts color and gradient are
                  // mutually exclusive, which would crash on the first open
                  // report.
                  border: Border(
                    left: BorderSide(
                        color: open ? t.warning : t.cardBorder, width: open ? 3 : 1),
                    top: BorderSide(color: t.cardBorder),
                    right: BorderSide(color: t.cardBorder),
                    bottom: BorderSide(color: t.cardBorder),
                  ),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: t.cardShadow,
                ),
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
                    Text((r['reason'] ?? '') as String,
                        style: text.bodyLarge?.copyWith(height: 1.45)),
                    const SizedBox(height: AppSizes.xs),
                    Text('reported by $reporter',
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
              );
            },
          ),
        );
      }),
    );
  }
}
