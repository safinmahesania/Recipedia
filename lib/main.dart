import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'services/ingredient_art_service.dart';
import 'services/supabase_client.dart';
import 'constants/app_sizes.dart';
import 'theme/app_theme.dart';
import 'views/splash/splash_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/auth/set_password_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  // Non-blocking: populates from the local cache immediately and refreshes in
  // the background. A cold cache just means letter chips for one session.
  unawaited(IngredientArt.warm());

  // A reset link opens the app and Supabase raises passwordRecovery. Without a
  // listener the user lands on Home, still signed in with the old password and
  // no idea what happened.
  supabase.auth.onAuthStateChange.listen((state) {
    if (state.event == AuthChangeEvent.passwordRecovery) {
      Get.to(() => const SetPasswordView());
    }
  });

  runApp(const RecipediaApp());
}

class RecipediaApp extends StatelessWidget {
  const RecipediaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Recipedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Follows the OS setting. Swap to a stored preference once the settings
      // screen exposes a theme toggle.
      themeMode: ThemeMode.system,
      // Routes were snapping in with no transition. cupertino reads as a push
      // on both platforms and is short enough not to feel like waiting.
      defaultTransition: Transition.cupertino,
      transitionDuration: AppSizes.durBase,
      home: const SplashView(),
    );
  }
}
