# Recipedia - final cleanup: remove legacy files left over after migration.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File .\cleanup_final.ps1
$ErrorActionPreference = "Continue"

Write-Host ">> Remove legacy screens/services replaced during migration"
@(
  "lib/views/auth/otp_view.dart",              # replaced by email confirmation link
  "lib/views/auth/auth_gate_view.dart",        # replaced by login_view
  "lib/views/scan/scan_result_view.dart",      # replaced by scan_view
  "lib/views/admin/add_recipe_view.dart",      # merged into edit_recipe_view
  "lib/views/admin/recipe_crud_view.dart",     # merged into manage_recipe_view
  "lib/views/recipes/recipes_view.dart",       # stale data class -> models/recipe.dart
  "lib/views/recipes/favorite_recipes_view.dart", # stale data class
  "lib/models/favorite.dart",                  # favorites handled by RecipeService
  "lib/services/local_storage_service.dart",   # Supabase persists the session
  "lib/services/notification_service.dart"     # re-add with FCM when FR6 is built
) | ForEach-Object { if (Test-Path $_) { git rm -f -- $_ } }

Write-Host ">> Remove legacy widgets no longer referenced by any screen"
@(
  "lib/shared/widgets/automated_slider.dart",
  "lib/shared/widgets/category_tile.dart",
  "lib/shared/widgets/faq_tile.dart",
  "lib/shared/widgets/profile_picture.dart",
  "lib/shared/widgets/progress_bar.dart",
  "lib/shared/widgets/recipe_card_slider.dart",
  "lib/shared/widgets/setting_tile.dart",
  "lib/shared/widgets/snack_bar.dart",
  "lib/shared/widgets/toast_message.dart"
) | ForEach-Object { if (Test-Path $_) { git rm -f -- $_ } }

Write-Host ">> Remove Firebase android config (re-add if/when FCM is set up)"
@(
  "android/app/google-services.json"
) | ForEach-Object { if (Test-Path $_) { git rm -f -- $_ } }

Write-Host ""
Write-Host ">> MANUAL steps still required:"
Write-Host "   1. android/build.gradle      - remove line: classpath 'com.google.gms:google-services:4.3.15'"
Write-Host "   2. android/app/build.gradle  - remove line: apply plugin: 'com.google.gms.google-services'"
Write-Host "   3. android/app/build.gradle  - remove firebase-bom implementation line"
Write-Host "   4. android/app/build.gradle  - set minSdkVersion to 21 or higher (Supabase needs it)"
Write-Host "   5. Run: flutter pub get"
Write-Host "   6. Run: flutter analyze"
