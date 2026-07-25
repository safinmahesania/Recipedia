import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/image_service.dart';
import '../services/supabase_client.dart';

/// Signed-in user's profile, activity stats, and preferences.
class ProfileController extends GetxController {
  final AuthService _auth = AuthService();
  final ImageService _images = ImageService();

  final profile = Rxn<UserProfile>();
  final isLoading = false.obs;
  final isSaving = false.obs;

  // profile_stats() returns all four in one round trip
  final savedCount = 0.obs;
  final submittedCount = 0.obs;
  final reviewCount = 0.obs;
  final cookedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  String? get _uid => _auth.currentUser?.id;

  Future<void> loadProfile() async {
    final id = _uid;
    if (id == null) return;
    try {
      isLoading.value = true;
      final row = await supabase.from('profiles').select().eq('id', id).single();
      profile.value = UserProfile.fromMap(row);
      await loadStats();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStats() async {
    final id = _uid;
    if (id == null) return;
    try {
      final rows = await supabase.rpc('profile_stats', params: {'uid': id});
      final list = List<Map<String, dynamic>>.from(rows as List);
      if (list.isEmpty) return;
      final s = list.first;
      savedCount.value = (s['saved'] as num?)?.toInt() ?? 0;
      submittedCount.value = (s['submitted'] as num?)?.toInt() ?? 0;
      reviewCount.value = (s['reviews'] as num?)?.toInt() ?? 0;
      cookedCount.value = (s['cooked'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // stats are decoration — never block the screen on them
    }
  }

  /// Single write path for every profile field, so callers don't each
  /// hand-roll an update + reload.
  Future<void> updateFields(Map<String, dynamic> fields) async {
    final id = _uid;
    if (id == null || fields.isEmpty) return;
    try {
      isSaving.value = true;
      await supabase.from('profiles').update(fields).eq('id', id);
      await loadProfile();
    } on Exception catch (e) {
      final msg = e.toString().contains('profiles_username')
          ? 'That username is taken. Try another.'
          : 'Could not save your changes. Try again.';
      Get.snackbar('Not saved', msg);
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> updateName(String name) =>
      updateFields({'name': name.trim()});

  Future<void> updateUsername(String username) =>
      updateFields({'username': username.trim().toLowerCase()});

  Future<void> updateBio(String bio) => updateFields({'bio': bio.trim()});

  Future<void> setThemeMode(String mode) async {
    await updateFields({'theme_mode': mode});
    Get.changeThemeMode(switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    });
  }

  Future<void> setHideUnsafe(bool value) =>
      updateFields({'hide_unsafe': value});

  Future<void> setNotifyPref(String column, bool value) =>
      updateFields({column: value});

  /// Pick and upload an avatar. `avatar_url` has existed in the schema since
  /// the first migration but nothing in the app could set it until now.
  Future<void> changeAvatar(ImageSource source) async {
    final id = _uid;
    if (id == null) return;
    try {
      final file = await _images.pick(source);
      if (file == null) return;
      isSaving.value = true;
      final url = await _images.upload(file);
      await supabase.from('profiles').update({'avatar_url': url}).eq('id', id);
      await loadProfile();
    } catch (_) {
      Get.snackbar('Upload failed', 'Could not update your photo. Try again.');
    } finally {
      isSaving.value = false;
    }
  }
}
