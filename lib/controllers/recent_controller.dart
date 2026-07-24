import 'package:get/get.dart';
import '../services/cache_service.dart';

/// Recently viewed recipes — stored locally, so it works offline (FR21).
class RecentController extends GetxController {
  final CacheService _cache = CacheService();
  final recent = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    recent.value = await _cache.getRecent();
  }

  Future<void> track(Map<String, dynamic> recipe) async {
    await _cache.addRecent(recipe);
    await load();
  }

  Future<void> clear() async {
    await _cache.clearRecent();
    await load();
  }
}
