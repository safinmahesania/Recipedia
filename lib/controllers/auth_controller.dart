import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../constants/app_strings.dart';
import '../views/auth/login_view.dart';
import '../views/recipes/recipe_list_view.dart';

/// The "C": auth state + orchestration. Views only call these + read isLoading.
class AuthController extends GetxController {
  final AuthService _service = AuthService();
  final isLoading = false.obs;

  Future<void> login(String email, String password) async {
    try {
      isLoading.value = true;
      final res = await _service.signIn(email, password);
      if (res.user == null) {
        _error(AppStrings.loginFailed);
        return;
      }
      // TEMP landing: recipe list (home/admin screens migrate later).
      Get.offAll(() => RecipeListView());
    } on AuthException catch (e) {
      _error(e.message);
    } catch (_) {
      _error(AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    try {
      isLoading.value = true;
      await _service.signUp(email, password, name: name);
      Get.snackbar(AppStrings.appName, AppStrings.verifyEmailSent);
      Get.offAll(() => LoginView());
    } on AuthException catch (e) {
      _error(e.message);
    } catch (_) {
      _error(AppStrings.somethingWentWrong);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginWithGoogle() => _oauth(_service.signInWithGoogle);
  Future<void> loginWithApple()  => _oauth(_service.signInWithApple);
  Future<void> _oauth(Future<bool> Function() fn) async {
    try {
      isLoading.value = true;
      await fn();
    } on AuthException catch (e) {
      _error(e.message);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _service.resetPassword(email);
      Get.snackbar(AppStrings.appName, AppStrings.resetLinkSent);
    } on AuthException catch (e) {
      _error(e.message);
    }
  }

  Future<void> logout() async {
    await _service.signOut();
    Get.offAll(() => LoginView());
  }

  void _error(String msg) => Get.snackbar(AppStrings.error, msg);
}
