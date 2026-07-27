import 'package:get/get.dart';
import '../services/auth_service.dart';
import '../services/cooked_service.dart';

class CookedController extends GetxController {
  final CookedService _service = CookedService();
  final AuthService _auth = AuthService();

  final isLoading = false.obs;
  final entries = <Map<String, dynamic>>[].obs;

  String? get _uid => _auth.currentUser?.id;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      isLoading.value = true;
      entries.value = await _service.history(uid);
    } catch (_) {
      Get.snackbar('Offline', 'Could not load your cooking history.');
    } finally {
      isLoading.value = false;
    }
  }

  /// Distinct recipes cooked, not total sessions — "24 recipes" is a more
  /// meaningful number than "31 times" when the same dal appears eight times.
  int get distinctRecipes => entries
      .map((e) => (e['recipes'] as Map?)?['id'])
      .whereType<String>()
      .toSet()
      .length;

  int get thisMonth {
    final now = DateTime.now();
    return entries.where((e) {
      final d = DateTime.tryParse((e['cooked_at'] ?? '').toString());
      return d != null && d.year == now.year && d.month == now.month;
    }).length;
  }

  Future<void> remove(Map<String, dynamic> entry) async {
    entries.remove(entry);
    try {
      await _service.remove(entry['id'] as String);
    } catch (_) {
      await load();
    }
  }
}
