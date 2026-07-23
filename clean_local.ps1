# Recipedia — clean local build junk. Safe: touches no source, no secrets.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File .\clean_local.ps1

Write-Host ">> flutter clean (removes build/ and .dart_tool/)"
flutter clean

Write-Host ">> Removing Android build caches"
@(
  "android\.gradle",
  "android\build",
  "android\app\build",
  "android\.cxx",
  "android\captures"
) | ForEach-Object {
  if (Test-Path $_) { Remove-Item -Recurse -Force $_; Write-Host "   removed $_" }
}

Write-Host ">> Removing stray IDE files"
Get-ChildItem -Recurse -Filter "*.iml" -ErrorAction SilentlyContinue |
  ForEach-Object { Remove-Item -Force $_.FullName; Write-Host "   removed $($_.Name)" }

Write-Host ">> Removing one-time scripts that already ran"
@("cleanup_final.ps1", "cleanup_final.sh", "cleanup.ps1", "cleanup.sh") | ForEach-Object {
  if (Test-Path $_) { Remove-Item -Force $_; Write-Host "   removed $_" }
}

Write-Host ""
Write-Host ">> KEPT ON PURPOSE (do not delete):"
Write-Host "   dart_define.json          - your Supabase keys (gitignored)"
Write-Host "   tools/recipes.json        - 1.9MB export, keep if you may re-import"
Write-Host "   tools/node_modules/       - delete only if you are done with tools"
Write-Host "   supabase/seed/            - reference for how seeding worked"
Write-Host ""
Write-Host ">> Next: flutter pub get"