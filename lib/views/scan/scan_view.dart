import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../controllers/scan_controller.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/recipe_card.dart';
import '../recipes/recipe_details_view.dart';

/// Scan a vegetable/fruit (or type ingredients) and find matching recipes.
/// Detected items are shown as editable chips so a wrong guess is a one-tap
/// fix rather than a dead end.
class ScanView extends StatelessWidget {
  const ScanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ScanController c = Get.put(ScanController());
    final manual = TextEditingController();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Find by ingredients',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: c.reset),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // image preview / capture
            Obx(() {
              final img = c.image.value;
              return Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  image: img == null
                      ? null
                      : DecorationImage(image: FileImage(img), fit: BoxFit.cover),
                ),
                child: img != null
                    ? null
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera_outlined, size: 34, color: AppColors.border),
                            SizedBox(height: 6),
                            Text('Scan or add ingredients below',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                        ),
                      ),
              );
            }),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => c.pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Camera'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => c.pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Gallery'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border)),
                ),
              ),
            ]),

            // model-not-ready notice
            if (!c.modelReady)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.primaryTint, borderRadius: BorderRadius.circular(10)),
                  child: const Row(children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Automatic detection is coming soon. Add ingredients manually for now.',
                          style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ),
                  ]),
                ),
              ),

            const SizedBox(height: 20),
            const Text('Ingredients',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),

            // manual add
            Row(children: [
              Expanded(
                child: TextField(
                  controller: manual,
                  onChanged: c.suggest,
                  onSubmitted: (v) {
                    c.addIngredient(v);
                    manual.clear();
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. potato',
                    filled: true,
                    fillColor: AppColors.surface,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 32),
                onPressed: () {
                  c.addIngredient(manual.text);
                  manual.clear();
                },
              ),
            ]),
            // autocomplete — pick a name that actually exists in the data,
            // so "potato" does not miss recipes stored as "aloo"
            Obx(() {
              if (c.suggestions.isEmpty) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: c.suggestions
                      .map((name) => ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            title: Text(name,
                                style: const TextStyle(
                                    fontSize: 14, color: AppColors.textPrimary)),
                            trailing: const Icon(Icons.add,
                                size: 18, color: AppColors.primary),
                            onTap: () {
                              c.addIngredient(name);
                              manual.clear();
                            },
                          ))
                      .toList(),
                ),
              );
            }),

            const SizedBox(height: 10),

            // chips
            Obx(() {
              if (c.isDetecting.value) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                );
              }
              if (c.ingredients.isEmpty) {
                return const Text('No ingredients added yet',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary));
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: c.ingredients
                    .map((name) => Chip(
                          label: Text(name),
                          backgroundColor: AppColors.accentTint,
                          labelStyle: const TextStyle(color: AppColors.accentDark, fontSize: 13),
                          deleteIconColor: AppColors.accentDark,
                          onDeleted: () => c.removeIngredient(name),
                        ))
                    .toList(),
              );
            }),

            const SizedBox(height: 20),
            Obx(() => PrimaryButton(
                  label: 'Find recipes',
                  loading: c.isSearching.value,
                  onTap: c.findRecipes,
                )),

            // results
            const SizedBox(height: 24),
            Obx(() {
              if (!c.searched.value) return const SizedBox.shrink();
              if (c.results.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text('No recipes match those ingredients',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${c.results.length} recipe(s) found',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  ...c.results.map((r) => RecipeCard(
                        recipe: r,
                        onTap: () => Get.to(() => RecipeDetailsView(recipeId: r['id'])),
                      )),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
