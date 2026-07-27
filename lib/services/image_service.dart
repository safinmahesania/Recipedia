import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'supabase_client.dart';

/// Picks an image (camera or gallery) and uploads it to Supabase Storage,
/// returning a public URL. URL-based images are handled by the caller directly.
class ImageService {
  final ImagePicker _picker = ImagePicker();
  static const _recipeBucket = 'recipe-images';
  static const _avatarBucket = 'avatars';

  Future<File?> pick(ImageSource source) async {
    final x = await _picker.pickImage(
        source: source, imageQuality: 80, maxWidth: 1400);
    return x == null ? null : File(x.path);
  }

  /// Uploads a recipe photo and returns its public URL.
  Future<String> upload(File file) => _put(_recipeBucket, file);

  /// Avatars live in their own bucket. Storage policy requires the first path
  /// segment to be the uploader's uid, so one user cannot overwrite another's.
  Future<String> uploadAvatar(File file) => _put(_avatarBucket, file);

  Future<String> _put(String bucket, File file) async {
    final userId = supabase.auth.currentUser?.id ?? 'anon';
    final ext = p.extension(file.path).toLowerCase();
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}$ext';
    await supabase.storage.from(bucket).upload(path, file);
    return supabase.storage.from(bucket).getPublicUrl(path);
  }
}
