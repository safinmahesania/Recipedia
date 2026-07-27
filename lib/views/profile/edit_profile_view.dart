import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../controllers/profile_controller.dart';
import '../../shared/widgets/app_icon.dart';
import '../../shared/widgets/primary_button.dart';
import '../../theme/app_tokens.dart';

/// Edit your name, username, bio and photo.
///
/// Every mutation already existed on ProfileController — updateName,
/// updateUsername, updateBio, changeAvatar — with no screen calling them, so
/// the name and photo at the top of the Profile tab could never be changed.
class EditProfileView extends StatefulWidget {
  const EditProfileView({super.key});

  @override
  State<EditProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<EditProfileView> {
  final ProfileController c = Get.put(ProfileController());
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  bool _dirty = false;

  static const _bioLimit = 160;

  @override
  void initState() {
    super.initState();
    final p = c.profile.value;
    _name.text = p?.name ?? '';
    _username.text = p?.username ?? '';
    _bio.text = p?.bio ?? '';
    for (final f in [_name, _username, _bio]) {
      f.addListener(() {
        if (!_dirty) setState(() => _dirty = true);
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  String? get _usernameError {
    final v = _username.text.trim();
    if (v.isEmpty) return null; // optional
    if (v.length < 3) return 'At least 3 characters';
    if (!RegExp(r'^[a-z0-9_.]+$').hasMatch(v.toLowerCase())) {
      return 'Letters, numbers, dot and underscore only';
    }
    return null;
  }

  Future<void> _save() async {
    if (_usernameError != null) return;
    final p = c.profile.value;
    final fields = <String, dynamic>{};
    if (_name.text.trim() != (p?.name ?? '')) {
      fields['name'] = _name.text.trim();
    }
    if (_username.text.trim().toLowerCase() != (p?.username ?? '')) {
      fields['username'] = _username.text.trim().toLowerCase();
    }
    if (_bio.text.trim() != (p?.bio ?? '')) fields['bio'] = _bio.text.trim();

    // Nothing changed — saying "saved" would be a lie.
    if (fields.isEmpty) {
      Get.back();
      return;
    }
    await c.updateFields(fields);
    if (!mounted) return;
    Get.back();
    Get.snackbar('Saved', 'Your profile has been updated.');
  }

  void _photoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.tokens.surfaceRaised,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppSizes.radiusXl)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const AppIcon('camera_alt', fallback: Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetCtx);
                c.changeAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const AppIcon('photo', fallback: Icons.photo),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetCtx);
                c.changeAvatar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: t.canvas,
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSizes.screenPad, AppSizes.md,
            AppSizes.screenPad, AppSizes.xxl),
        children: [
          Center(
            child: Obx(() {
              final p = c.profile.value;
              final url = p?.avatarUrl;
              final seed = (p?.name ?? p?.email ?? 'x');
              final slot = AppColors.slotFor(seed);
              return Column(children: [
                Stack(children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: t.categoryTints[slot],
                    backgroundImage: (url != null && url.isNotEmpty)
                        ? NetworkImage(url)
                        : null,
                    child: (url == null || url.isEmpty)
                        ? Text(
                            seed.isEmpty ? '?' : seed[0].toUpperCase(),
                            style: text.headlineMedium
                                ?.copyWith(color: t.categoryGlyphs[slot]),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: _photoSheet,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: t.brandFill,
                          shape: BoxShape.circle,
                          border: Border.all(color: t.canvas, width: 2),
                        ),
                        child: AppIcon('camera_alt',
                            fallback: Icons.camera_alt,
                            size: 12,
                            color: t.onBrandFill),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: AppSizes.sm),
                if (c.isSaving.value)
                  Text('Uploading…',
                      style:
                          text.labelSmall?.copyWith(color: t.textSecondary))
                else
                  TextButton(
                      onPressed: _photoSheet,
                      child: const Text('Change photo')),
              ]);
            }),
          ),

          const SizedBox(height: AppSizes.md),
          _Label('DISPLAY NAME'),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'How you appear'),
          ),

          const SizedBox(height: AppSizes.md),
          _Label('USERNAME'),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _username,
            autocorrect: false,
            decoration: InputDecoration(
              hintText: 'yourname',
              prefixText: '@',
              errorText: _usernameError,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSizes.xs),
          Text('Shown on recipes you submit.',
              style: text.labelSmall?.copyWith(color: t.textTertiary)),

          const SizedBox(height: AppSizes.md),
          _Label('BIO'),
          const SizedBox(height: AppSizes.sm),
          TextField(
            controller: _bio,
            maxLines: 3,
            maxLength: _bioLimit,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
                hintText: 'What do you like to cook?'),
          ),

          const SizedBox(height: AppSizes.sm),
          Obx(() => PrimaryButton(
                label: 'Save changes',
                loading: c.isSaving.value,
                onTap: (_dirty && _usernameError == null) ? _save : () {},
              )),
          if (!_dirty)
            Padding(
              padding: const EdgeInsets.only(top: AppSizes.sm),
              child: Center(
                child: Text('Nothing changed yet',
                    style:
                        text.labelSmall?.copyWith(color: t.textTertiary)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.tokens.textTertiary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ));
}
