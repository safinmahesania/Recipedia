import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../controllers/admin_controller.dart';
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';

/// Add (recipe == null) or edit an existing recipe.
class EditRecipeView extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  const EditRecipeView({Key? key, this.recipe}) : super(key: key);

  @override
  State<EditRecipeView> createState() => _EditRecipeViewState();
}

class _EditRecipeViewState extends State<EditRecipeView> {
  final _service = AdminService();
  final _auth = AuthService();

  final title = TextEditingController();
  final instructions = TextEditingController();
  final imageUrl = TextEditingController();
  final cookTime = TextEditingController();
  final diet = TextEditingController();
  final coreIngredients = TextEditingController();
  final optionalIngredients = TextEditingController();

  bool saving = false;
  bool get isEdit => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    if (r != null) {
      title.text = r['title'] ?? '';
      instructions.text = r['instructions'] ?? '';
      imageUrl.text = r['image_url'] ?? '';
      cookTime.text = r['cook_time'] ?? '';
      diet.text = r['diet'] ?? '';
    }
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) {
      Get.snackbar(AppStrings.error, 'Title is required');
      return;
    }
    setState(() => saving = true);
    try {
      final data = {
        'title': title.text.trim(),
        'instructions': instructions.text.trim(),
        'image_url': imageUrl.text.trim(),
        'cook_time': cookTime.text.trim(),
        'diet': diet.text.trim(),
        'status': 'approved', // admin-created recipes publish directly
      };

      String recipeId;
      if (isEdit) {
        recipeId = widget.recipe!['id'];
        await _service.updateRecipe(recipeId, data);
        await _service.clearRecipeIngredients(recipeId);
      } else {
        data['author_id'] = _auth.currentUser!.id;
        recipeId = await _service.addRecipe(data);
      }

      await _linkIngredients(recipeId, coreIngredients.text, 'core');
      await _linkIngredients(recipeId, optionalIngredients.text, 'optional');

      Get.back();
      Get.snackbar(AppStrings.appName, AppStrings.recipeSaved);
      Get.find<AdminController>().loadRecipes();
    } catch (_) {
      Get.snackbar(AppStrings.error, AppStrings.somethingWentWrong);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _linkIngredients(String recipeId, String csv, String role) async {
    for (final raw in csv.split(',')) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final id = await _service.ensureIngredient(name);
      await _service.setRecipeIngredient(
          recipeId: recipeId, ingredientId: id, role: role);
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
        title: Text(isEdit ? 'Edit recipe' : 'Add recipe',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(label: 'Title', hint: 'Recipe name', controller: title),
            const SizedBox(height: 14),
            AppTextField(label: 'Cook time', hint: '30 min', controller: cookTime),
            const SizedBox(height: 14),
            AppTextField(label: 'Diet', hint: 'Vegetarian', controller: diet),
            const SizedBox(height: 14),
            AppTextField(label: 'Image URL', hint: 'https://...', controller: imageUrl),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Core ingredients (comma separated)',
                hint: 'aloo, palak',
                controller: coreIngredients),
            const SizedBox(height: 6),
            const Text('Main ingredients — these drive scan matching.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Optional ingredients (comma separated)',
                hint: 'tomato',
                controller: optionalIngredients),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Instructions', hint: 'Steps...', controller: instructions),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Save recipe', loading: saving, onTap: _save),
          ],
        ),
      ),
    );
  }
}
