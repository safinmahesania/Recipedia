import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../theme/app_tokens.dart';
import 'edit_recipe_view.dart';
import '../../shared/widgets/skeletons.dart';

/// Full recipe catalogue with edit and delete. StatefulWidget because
/// loadRecipes() was firing from build() on every rebuild.
class ManageRecipeView extends StatefulWidget {
  const ManageRecipeView({super.key});

  @override
  State<ManageRecipeView> createState() => _ManageRecipeViewState();
}

class _ManageRecipeViewState extends State<ManageRecipeView> {
  final AdminController c = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    c.loadRecipes();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Recipes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.to(() => const EditRecipeView()),
        backgroundColor: t.brandFill,
        foregroundColor: t.onBrandFill,
        tooltip: 'Add recipe',
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 0);
        }
        if (c.recipes.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No recipes',
            message: 'Add one with the button below, or approve a submission.',
          );
        }
        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadRecipes,
          child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
          itemCount: c.recipes.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
          itemBuilder: (_, i) {
            final r = c.recipes[i];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text((r['title'] ?? '') as String, style: text.bodyLarge),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSizes.xs),
                child: Row(children: [
                  _StatusChip((r['status'] ?? 'pending') as String),
                  const SizedBox(width: AppSizes.sm),
                  Flexible(
                    child: Text(
                      ((r['categories'] as Map<String, dynamic>?)?['name'] ?? '')
                          as String,
                      overflow: TextOverflow.ellipsis,
                      style:
                          text.labelSmall?.copyWith(color: t.textSecondary),
                    ),
                  ),
                ]),
              ),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: Icon(Icons.edit_outlined,
                      color: t.textSecondary, size: AppSizes.iconMd),
                  tooltip: 'Edit',
                  onPressed: () => Get.to(() => EditRecipeView(recipe: r)),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline,
                      color: t.error, size: AppSizes.iconMd),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context, c,
                      r['id'] as String, (r['title'] ?? '') as String),
                ),
              ]),
            );
            },
          ),
        );
      }),
    );
  }

  void _confirmDelete(BuildContext context, AdminController c, String id,
      String title) {
    showDialog(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete recipe'),
        content: Text('Delete "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dctx);
              c.deleteRecipe(id);
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

/// Tint + on-tint pair. The raw hues were being used as both a 12% wash and
/// the label colour on top of it, which left "approved" at roughly 2:1.
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
          horizontal: AppSizes.sm, vertical: 1),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(AppSizes.radiusPill)),
      child: Text(status == 'approved' ? 'live' : status,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: fg, fontWeight: FontWeight.w700)),
    );
  }
}
