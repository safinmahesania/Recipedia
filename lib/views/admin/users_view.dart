import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/admin_controller.dart';
import '../../theme/app_tokens.dart';
import '../../shared/widgets/skeletons.dart';

/// StatefulWidget because loadUsers() was called from build() — a fresh
/// network request on every rebuild.
class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final AdminController c = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    c.loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Users')),
      body: Obx(() {
        if (c.isLoading.value) {
          return const ListSkeleton(thumb: 40);
        }
        if (c.users.isEmpty) {
          return const EmptyState(
            icon: 'people_outline',
            title: 'No users yet',
            message: 'Accounts appear here as people sign up.',
          );
        }
        return RefreshIndicator(
          color: t.brand,
          onRefresh: c.loadUsers,
          child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPad),
          itemCount: c.users.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: t.border),
          itemBuilder: (_, i) {
            final u = c.users[i];
            final isAdmin = u['role'] == 'admin';
            final name = (u['name'] ?? 'Unnamed').toString();
            // Deterministic avatar tint, same ramp as recipe placeholders, so a
            // long user list reads as varied rather than a column of clones.
            final slot = AppColors.slotFor((u['id'] ?? name).toString());

            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: t.categoryTints[slot],
                child: Text(
                  name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                  style: text.labelMedium
                      ?.copyWith(color: t.categoryGlyphs[slot]),
                ),
              ),
              title: Text(name, style: text.bodyLarge),
              subtitle: Text((u['email'] ?? '') as String,
                  style: text.labelSmall?.copyWith(color: t.textSecondary)),
              trailing: isAdmin
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm, vertical: AppSizes.xxs),
                      decoration: BoxDecoration(
                        color: t.accentTint,
                        borderRadius:
                            BorderRadius.circular(AppSizes.radiusPill),
                      ),
                      child: Text('Admin',
                          style: text.labelSmall?.copyWith(
                              color: t.onAccentTint,
                              fontWeight: FontWeight.w700)),
                    )
                  : null,
            );
            },
          ),
        );
      }),
    );
  }
}
