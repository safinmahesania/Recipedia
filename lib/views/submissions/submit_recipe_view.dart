import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/submission_controller.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';

/// Submit a new recipe, or edit one of your own (FR34/36).
class SubmitRecipeView extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const SubmitRecipeView({Key? key, this.existing}) : super(key: key);

  @override
  State<SubmitRecipeView> createState() => _SubmitRecipeViewState();
}

class _SubmitRecipeViewState extends State<SubmitRecipeView> {
  final SubmissionController c = Get.put(SubmissionController());

  final title = TextEditingController();
  final instructions = TextEditingController();
  final imageUrl = TextEditingController();
  final cookTime = TextEditingController();
  final diet = TextEditingController();
  final core = TextEditingController();
  final optional = TextEditingController();

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      title.text = e['title'] ?? '';
      instructions.text = e['instructions'] ?? '';
      imageUrl.text = e['image_url'] ?? '';
      cookTime.text = e['cook_time'] ?? '';
      diet.text = e['diet'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: Text(isEdit ? 'Edit submission' : 'Submit a recipe',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: AppColors.primaryTint, borderRadius: BorderRadius.circular(10)),
              child: const Row(children: [
                Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Your recipe is reviewed by an admin before it goes live.',
                      style: TextStyle(fontSize: 12, color: AppColors.primary)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            AppTextField(label: 'Title', hint: 'Recipe name', controller: title),
            const SizedBox(height: 14),
            AppTextField(label: 'Cook time', hint: '30 min', controller: cookTime),
            const SizedBox(height: 14),
            AppTextField(label: 'Diet', hint: 'Vegetarian', controller: diet),
            const SizedBox(height: 14),
            AppTextField(label: 'Image URL', hint: 'https://...', controller: imageUrl),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Main ingredients (comma separated)',
                hint: 'potato, spinach',
                controller: core),
            const SizedBox(height: 6),
            const Text('These decide which scans match your recipe.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Optional ingredients (comma separated)',
                hint: 'tomato',
                controller: optional),
            const SizedBox(height: 14),
            AppTextField(label: 'Instructions', hint: 'Steps...', controller: instructions),
            const SizedBox(height: 24),
            Obx(() => PrimaryButton(
                  label: isEdit ? 'Resubmit for review' : 'Submit for review',
                  loading: c.isSaving.value,
                  onTap: () async {
                    final ok = await c.submit(
                      title: title.text,
                      instructions: instructions.text,
                      coreCsv: core.text,
                      optionalCsv: optional.text,
                      imageUrl: imageUrl.text,
                      cookTime: cookTime.text,
                      diet: diet.text,
                      existingId: widget.existing?['id'],
                    );
                    if (ok) Get.back();
                  },
                )),
          ],
        ),
      ),
    );
  }
}
