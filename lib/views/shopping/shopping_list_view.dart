import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/shopping_controller.dart';
import '../../shared/widgets/ingredient_icon.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';

/// The other half of the scan. `missing_names` tells you what you lack; this
/// turns it into something you can act on, and checked items flow back into
/// the pantry so the next scan is accurate without re-entering anything.
class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key});

  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> {
  final ShoppingController c = Get.put(ShoppingController());

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(
        title: const Text('Shopping list'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add item',
            onPressed: () => _addSheet(context),
          ),
        ],
      ),
      body: Obx(() {
        if (c.isLoading.value && c.items.isEmpty) {
          return const ListSkeleton(thumb: 22);
        }
        if (c.items.isEmpty) return const _Empty();

        final total = c.items.length;
        final done = c.doneCount;
        final groups = c.grouped;

        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.md,
                AppSizes.screenPad, AppSizes.xxl),
            children: [
              Text('$done of $total done',
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
              const SizedBox(height: AppSizes.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                child: LinearProgressIndicator(
                  value: total == 0 ? 0 : done / total,
                  minHeight: 5,
                  backgroundColor: t.surface,
                ),
              ),
              const SizedBox(height: AppSizes.lg),
              for (final entry in groups.entries) ...[
                Text(
                  entry.key.isEmpty
                      ? 'ADDED BY YOU'
                      : 'FOR ${entry.key.toUpperCase()}',
                  style: text.labelSmall?.copyWith(
                      color: t.textTertiary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1),
                ),
                const SizedBox(height: AppSizes.xs),
                ...entry.value.map((item) => _Row(controller: c, item: item)),
                const SizedBox(height: AppSizes.md),
              ],
              if (done > 0)
                FilledButton.icon(
                  onPressed: () async {
                    final n = await c.moveCheckedToPantry();
                    if (n > 0 && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('$n ${n == 1 ? 'item' : 'items'} '
                            'moved to your pantry'),
                      ));
                    }
                  },
                  icon: const Icon(Icons.shopping_basket_outlined,
                      size: AppSizes.iconSm),
                  label: const Text('Move checked to pantry'),
                ),
            ],
          ),
        );
      }),
    );
  }

  void _addSheet(BuildContext context) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.tokens.surfaceRaised,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            AppSizes.screenPad,
            AppSizes.lg,
            AppSizes.screenPad,
            MediaQuery.of(sheetCtx).viewInsets.bottom + AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add an item',
                style: Theme.of(sheetCtx).textTheme.titleLarge),
            const SizedBox(height: AppSizes.smd),
            TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(hintText: 'Paneer'),
              onSubmitted: (v) {
                c.addCustom(v);
                Navigator.pop(sheetCtx);
              },
            ),
            const SizedBox(height: AppSizes.md),
            FilledButton(
              onPressed: () {
                c.addCustom(ctrl.text);
                Navigator.pop(sheetCtx);
              },
              child: const Text('Add to list'),
            ),
          ],
        ),
      ),
    ).then((_) => ctrl.dispose());
  }
}

class _Row extends StatelessWidget {
  final ShoppingController controller;
  final Map<String, dynamic> item;
  const _Row({required this.controller, required this.item});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    final checked = item['checked'] == true;
    final label = controller.labelOf(item);
    final qty = (item['quantity'] ?? '') as String;

    return Dismissible(
      key: ValueKey(item['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.md),
        decoration: BoxDecoration(
          color: t.errorTint,
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(Icons.delete_outline, color: t.onErrorTint),
      ),
      onDismissed: (_) => controller.remove(item),
      child: InkWell(
        onTap: () => controller.toggle(item),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppSizes.durFast,
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: checked ? t.brandFill : Colors.transparent,
                  border: checked
                      ? null
                      : Border.all(color: t.borderStrong, width: 1.6),
                  borderRadius: BorderRadius.circular(AppSizes.radiusXs),
                ),
                child: checked
                    ? Icon(Icons.check, size: 14, color: t.onBrandFill)
                    : null,
              ),
              const SizedBox(width: AppSizes.smd),
              Opacity(
                opacity: checked ? 0.45 : 1,
                child: IngredientIcon(name: label, size: 20, tile: false),
              ),
              const SizedBox(width: AppSizes.smd),
              Expanded(
                child: Text(
                  label,
                  style: text.bodyLarge?.copyWith(
                    color: checked ? t.textTertiary : t.textPrimary,
                    decoration: checked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (qty.isNotEmpty)
                Text(qty,
                    style: text.labelSmall?.copyWith(color: t.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_basket_outlined,
                size: AppSizes.iconXl, color: t.borderStrong),
            const SizedBox(height: AppSizes.smd),
            Text('Nothing to buy',
                style: text.titleLarge?.copyWith(fontSize: 16)),
            const SizedBox(height: AppSizes.xs),
            Text(
              'Scan your pantry — anything a recipe is missing can be added '
              'here in one tap.',
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: t.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
