import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

/// Reusable list-style recipe row: thumbnail + title + meta.
/// One card, used by the list view, favorites, and scan results.
class RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final VoidCallback? onTap;

  const RecipeCard({Key? key, required this.recipe, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final title    = recipe['title'] ?? '';
    final imageUrl = recipe['image_url'] as String?;
    final cookTime = recipe['cook_time'] as String?;
    final diet     = recipe['diet'] as String?;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64, height: 64,
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: imageUrl, fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.primaryTint),
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (cookTime != null) ...[
                      const Icon(Icons.schedule, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(cookTime, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (diet != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                        decoration: BoxDecoration(
                            color: AppColors.accentTint,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(diet,
                            style: const TextStyle(fontSize: 11, color: AppColors.accentDark)),
                      ),
                    ],
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.primaryTint,
        child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 22),
      );
}
