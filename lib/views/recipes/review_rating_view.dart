import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/review_controller.dart';
import '../../shared/widgets/primary_button.dart';

/// Rate + review a recipe, and read others' reviews.
class ReviewRatingView extends StatefulWidget {
  final String recipeId;
  final String recipeTitle;
  const ReviewRatingView({Key? key, required this.recipeId, this.recipeTitle = ''})
      : super(key: key);

  @override
  State<ReviewRatingView> createState() => _ReviewRatingViewState();
}

class _ReviewRatingViewState extends State<ReviewRatingView> {
  final ReviewController c = Get.put(ReviewController());
  final comment = TextEditingController();
  int rating = 0;

  @override
  void initState() {
    super.initState();
    c.load(widget.recipeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Reviews',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.recipeTitle.isNotEmpty)
              Text(widget.recipeTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Obx(() => Row(children: [
                  ...List.generate(
                      5,
                      (i) => Icon(
                          i < c.average.value.round() ? Icons.star : Icons.star_border,
                          size: 18, color: AppColors.star)),
                  const SizedBox(width: 8),
                  Text(c.average.value.toStringAsFixed(1),
                      style: const TextStyle(color: AppColors.textSecondary)),
                  Text('  (${c.reviews.length})',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ])),
            const SizedBox(height: 24),

            const Text('Your rating',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (i) => IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40),
                  icon: Icon(i < rating ? Icons.star : Icons.star_border,
                      size: 30, color: AppColors.star),
                  onPressed: () => setState(() => rating = i + 1),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: comment,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your thoughts (optional)',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Obx(() => PrimaryButton(
                  label: 'Submit review',
                  loading: c.isSubmitting.value,
                  onTap: () => c.submit(widget.recipeId, rating, comment.text),
                )),

            const SizedBox(height: 28),
            const Text('All reviews',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Obx(() {
              if (c.isLoading.value) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }
              if (c.reviews.isEmpty) {
                return const Text('No reviews yet',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13));
              }
              return Column(
                children: c.reviews.map((r) {
                  final name = (r['profiles'] as Map<String, dynamic>?)?['name'] ?? 'User';
                  final stars = r['rating'] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                          const Spacer(),
                          ...List.generate(
                              5,
                              (s) => Icon(s < stars ? Icons.star : Icons.star_border,
                                  size: 13, color: AppColors.star)),
                        ]),
                        if ((r['comment'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r['comment'],
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
