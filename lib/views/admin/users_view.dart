import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/skeletons.dart';
import '../../theme/app_tokens.dart';

class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final AdminController c = Get.put(AdminController());
  final _search = TextEditingController();
  final _query = ''.obs;
  final _filter = ''.obs; // '' | admin | new

  @override
  void initState() {
    super.initState();
    c.loadUsers();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  int _recipeCount(Map<String, dynamic> u) =>
      (u['recipes'] as List?)?.length ?? 0;

  bool _isNew(Map<String, dynamic> u) {
    final t = DateTime.tryParse((u['created_at'] ?? '').toString());
    return t != null && DateTime.now().difference(t).inDays <= 30;
  }

  List<Map<String, dynamic>> get _visible {
    var list = c.users.toList();
    if (_filter.value == 'admin') {
      list = list.where((u) => u['role'] == 'admin').toList();
    } else if (_filter.value == 'new') {
      list = list.where(_isNew).toList();
    }
    final q = _query.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(q) || email.contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Users')),
      body: Obx(() {
        if (c.isLoading.value) return const ListSkeleton(thumb: 40);
        if (c.users.isEmpty) {
          return const EmptyState(
            icon: 'people_outline',
            title: 'No users yet',
            message: 'Accounts appear here as people sign up.',
          );
        }

        final rows = _visible;
        final admins = c.users.where((u) => u['role'] == 'admin').length;
        final recent = c.users.where(_isNew).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSizes.screenPad,
                  AppSizes.sm, AppSizes.screenPad, AppSizes.sm),
              child: Column(
                children: [
                  TextField(
                    controller: _search,
                    onChanged: (v) => _query.value = v,
                    decoration: const InputDecoration(
                      hintText: 'Search by name or email',
                      prefixIcon: AppIcon('search', fallback: Icons.search),
                    ),
                  ),
                  const SizedBox(height: AppSizes.smd),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _Tab('All · ${c.users.length}', _filter.value == '',
                            () => _filter.value = ''),
                        const SizedBox(width: AppSizes.sm),
                        _Tab('Admins · $admins', _filter.value == 'admin',
                            () => _filter.value = 'admin'),
                        const SizedBox(width: AppSizes.sm),
                        _Tab('New · $recent', _filter.value == 'new',
                            () => _filter.value = 'new'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text('No one matches',
                          style: text.bodyMedium
                              ?.copyWith(color: t.textSecondary)))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.screenPad),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: t.border),
                      itemBuilder: (_, i) {
                        final u = rows[i];
                        final name = (u['name'] ?? 'Unnamed').toString();
                        final isAdmin = u['role'] == 'admin';
                        final n = _recipeCount(u);
                        // Same tint ramp as recipe placeholders, so a long
                        // list reads as varied rather than a column of clones.
                        final slot = AppColors.slotFor(
                            (u['id'] ?? name).toString());

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: t.categoryTints[slot],
                            child: Text(
                              name.isEmpty
                                  ? '?'
                                  : name.characters.first.toUpperCase(),
                              style: text.labelMedium
                                  ?.copyWith(color: t.categoryGlyphs[slot]),
                            ),
                          ),
                          title: Row(children: [
                            Flexible(
                              child: Text(name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyLarge),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: AppSizes.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSizes.sm, vertical: 1),
                                decoration: BoxDecoration(
                                  color: t.accentTint,
                                  borderRadius: BorderRadius.circular(
                                      AppSizes.radiusPill),
                                ),
                                child: Text('Admin',
                                    style: text.labelSmall?.copyWith(
                                        color: t.onAccentTint,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          subtitle: Text(
                            '${u['email'] ?? ''} · $n '
                            '${n == 1 ? 'recipe' : 'recipes'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall
                                ?.copyWith(color: t.textSecondary),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      }),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab(this.label, this.selected, this.onTap);

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
        child: Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? t.onBrandTint : t.textSecondary,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}
