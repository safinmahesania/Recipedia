import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../home/main_shell.dart';

/// Splash: brief brand moment, then route by Supabase session.
///
/// This is the one screen that intentionally uses full-strength brand coral in
/// both modes — it is the logo lockup, not UI chrome. White on #FF4F5A is
/// 3.22:1, which passes AA for large text (the wordmark is 30px bold) and for
/// non-text UI (the icon). Nothing smaller may sit on this background.
class SplashView extends StatefulWidget {
  const SplashView({super.key});

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
    if (!mounted) return;
    final loggedIn = AuthService().currentUser != null;
    Get.offAll(() => loggedIn ? const MainShell() : const LoginView());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu,
                size: 72, color: Colors.white),
            const SizedBox(height: AppSizes.md),
            Text(
              AppStrings.appName,
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
