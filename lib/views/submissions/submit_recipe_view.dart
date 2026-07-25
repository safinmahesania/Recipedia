import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../controllers/submission_controller.dart';
import '../../services/image_service.dart';
import '../../shared/widgets/primary_button.dart';

/// Submit a new recipe, or edit one of your own (FR34/36).
/// Validated form + dropdowns + image (gallery / camera / URL).
class SubmitRecipeView extends StatefulWidget {
  final Map<String, dynamic>? existing;
  const SubmitRecipeView({Key? key, this.existing}) : super(key: key);

  @override
  State<SubmitRecipeView> createState() => _SubmitRecipeViewState();
}

class _SubmitRecipeViewState extends State<SubmitRecipeView> {
  final SubmissionController c = Get.put(SubmissionController());
  final ImageService _images = ImageService();
  final _formKey = GlobalKey<FormState>();

  final title = TextEditingController();
  final instructions = TextEditingController();
  final imageUrl = TextEditingController();
  final cookTime = TextEditingController();
  final core = TextEditingController();
  final optional = TextEditingController();

  String? _diet;
  String? _categoryId;
  File? _pickedImage;   // local file to upload
  bool _uploading = false;

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
      _diet = e['diet'];
      _categoryId = e['category_id'];
    }
  }

  Future<void> _pick(ImageSource source) async {
    final file = await _images.pick(source);
    if (file != null) {
      setState(() {
        _pickedImage = file;
        imageUrl.clear(); // a picked file overrides a pasted URL
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    String? finalUrl = imageUrl.text.trim().isEmpty ? null : imageUrl.text.trim();

    // upload a picked file first
    if (_pickedImage != null) {
      try {
        setState(() => _uploading = true);
        finalUrl = await _images.upload(_pickedImage!);
      } catch (_) {
        Get.snackbar('Error', 'Image upload failed. Try a URL instead.');
        return;
      } finally {
        if (mounted) setState(() => _uploading = false);
      }
    }

    final ok = await c.submit(
      title: title.text,
      instructions: instructions.text,
      coreCsv: core.text,
      optionalCsv: optional.text,
      imageUrl: finalUrl,
      cookTime: cookTime.text,
      diet: _diet,
      categoryId: _categoryId,
      existingId: widget.existing?['id'],
    );

    if (ok && mounted) {
      Get.back();
      // clear confirmation the user cannot miss
      Get.dialog(
        AlertDialog(
          icon: const Icon(Icons.check_circle, color: AppColors.success, size: 40),
          title: const Text('Submitted for review'),
          content: const Text(
              'An admin will review your recipe before it goes live. '
              'You can track its status in My submissions.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
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

              // ---------- image ----------
              _label('Photo'),
              _imagePicker(),
              const SizedBox(height: 18),

              // ---------- title ----------
              _label('Title *'),
              _field(title, 'Recipe name',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Title is required' : null),
              const SizedBox(height: 16),

              // ---------- diet + cook time ----------
              _label('Diet'),
              DropdownButtonFormField<String>(
                value: _diet,
                decoration: _decoration('Select diet'),
                items: SubmissionController.dietOptions
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setState(() => _diet = v),
              ),
              const SizedBox(height: 16),

              _label('Category'),
              Obx(() => DropdownButtonFormField<String>(
                    value: _categoryId,
                    decoration: _decoration('Select category'),
                    items: c.categories
                        .map((cat) => DropdownMenuItem(
                            value: cat['id'] as String,
                            child: Text(cat['name'] ?? '')))
                        .toList(),
                    onChanged: (v) => setState(() => _categoryId = v),
                  )),
              const SizedBox(height: 16),

              _label('Cook time'),
              _field(cookTime, 'e.g. 30 min'),
              const SizedBox(height: 16),

              // ---------- ingredients ----------
              _label('Main ingredients *'),
              _field(core, 'potato, spinach  (comma separated)',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Add at least one main ingredient'
                      : null),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('These decide which scans match your recipe.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 16),

              _label('Optional ingredients'),
              _field(optional, 'tomato  (comma separated)'),
              const SizedBox(height: 16),

              _label('Instructions'),
              _field(instructions, 'Steps...', maxLines: 5),
              const SizedBox(height: 24),

              Obx(() => PrimaryButton(
                    label: isEdit ? 'Resubmit for review' : 'Submit for review',
                    loading: c.isSaving.value || _uploading,
                    onTap: _save,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- helpers ----------
  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
      );

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error)),
      );

  Widget _field(TextEditingController ctrl, String hint,
          {String? Function(String?)? validator, int maxLines = 1}) =>
      TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        validator: validator,
        decoration: _decoration(hint),
      );

  Widget _imagePicker() {
    return Column(
      children: [
        if (_pickedImage != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_pickedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
          )
        else if (imageUrl.text.trim().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(imageUrl.text.trim(),
                height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _emptyImage()),
          )
        else
          _emptyImage(),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.gallery),
              icon: const Icon(Icons.image_outlined, size: 18),
              label: const Text('Gallery'),
              style: _outlined(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _pick(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Camera'),
              style: _outlined(),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        TextFormField(
          controller: imageUrl,
          decoration: _decoration('or paste an image URL'),
          onChanged: (_) => setState(() => _pickedImage = null),
        ),
      ],
    );
  }

  Widget _emptyImage() => Container(
        height: 160,
        decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: const Center(
          child: Icon(Icons.add_a_photo_outlined, size: 32, color: AppColors.border),
        ),
      );

  ButtonStyle _outlined() => OutlinedButton.styleFrom(
      foregroundColor: AppColors.textPrimary,
      side: const BorderSide(color: AppColors.border));
}
