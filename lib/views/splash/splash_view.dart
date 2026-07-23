import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../recipes/recipe_list_view.dart';

/// Splash: brief brand screen, then route by Supabase session.
/// No stored credentials — Supabase persists the session itself.
class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), _route);
  }

  void _route() {
    final loggedIn = AuthService().currentUser != null;
    // TEMP landing: recipe list until home_view is migrated.
    Get.offAll(() => loggedIn ? RecipeListView() : LoginView());
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text(AppStrings.appName,
                style: TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
