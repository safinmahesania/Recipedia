import 'package:get/get.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/supabase_client.dart';

/// Holds the signed-in user's profile.
class ProfileController extends GetxController {
  final AuthService _auth = AuthService();
  final profile = Rxn<UserProfile>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final id = _auth.currentUser?.id;
    if (id == null) return;
    try {
      isLoading.value = true;
      final row = await supabase.from('profiles').select().eq('id', id).single();
      profile.value = UserProfile.fromMap(row);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateName(String name) async {
    final id = _auth.currentUser?.id;
    if (id == null) return;
    await supabase.from('profiles').update({'name': name}).eq('id', id);
    await loadProfile();
  }
}
