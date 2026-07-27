import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';
import '../../constants/app_strings.dart';
import '../../services/auth_service.dart';
import '../../services/onboarding_service.dart';
import '../onboarding/onboarding_view.dart';
import '../home/main_shell.dart';
import '../../shared/widgets/app_icon.dart';
import '../auth/welcome_view.dart';

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
    Timer(const Duration(seconds: 2), () => _route());
  }

  Future<void> _route() async {
    if (!mounted) return;
    final user = AuthService().currentUser;
    if (user == null) {
      Get.offAll(() => const WelcomeView());
      return;
    }
    // A null diet_preference means this profile has never been through
    // onboarding. Failures return false, so a bad connection lands you in the
    // app rather than trapping you in setup.
    final needs = await OnboardingService().needsOnboarding(user.id);
    if (!mounted) return;
    Get.offAll(() => needs ? const OnboardingView() : const MainShell());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon('restaurant_menu', fallback: Icons.restaurant_menu,
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
