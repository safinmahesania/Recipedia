# Repository cleanup. Run from the repo root.
#
# ASCII only, on purpose: Windows PowerShell 5.1 reads .ps1 as ANSI unless the
# file has a BOM, so a stray em-dash becomes mojibake and breaks the parser.
# This file is written UTF-8 with BOM as well, so both paths are covered.
#
#   powershell -ExecutionPolicy Bypass -File tools\clean_repo.ps1
#   powershell -ExecutionPolicy Bypass -File tools\clean_repo.ps1 -Apply
#
# Without -Apply it only reports. Nothing is deleted until you pass it.

param([switch]$Apply)

$ErrorActionPreference = "Stop"

function Section($n, $title) {
    Write-Host ""
    Write-Host "=== $n. $title ===" -ForegroundColor Cyan
}

if (-not (Test-Path ".git")) {
    Write-Host "Run this from the repository root." -ForegroundColor Red
    exit 1
}

$mode = if ($Apply) { "APPLY" } else { "REPORT ONLY (pass -Apply to change anything)" }
Write-Host "Mode: $mode" -ForegroundColor Yellow

# ---------------------------------------------------------------------------
Section 1 "Generated output tracked in git"
# Every file under out/ is produced by a script in tools/. Committing them puts
# multi-megabyte fetch dumps into every clone, permanently.
$tracked = @(git ls-files "out/*")
if ($tracked.Count -gt 0) {
    Write-Host ("  {0} tracked files under out/" -f $tracked.Count)
    $tracked | Select-Object -First 8 | ForEach-Object { Write-Host "    $_" }
    if ($tracked.Count -gt 8) { Write-Host ("    ... {0} more" -f ($tracked.Count - 8)) }
    if ($Apply) {
        git rm -r --cached out/ --quiet
        Write-Host "  untracked out/ (files remain on disk)" -ForegroundColor Green
    } else {
        Write-Host "  would run: git rm -r --cached out/" -ForegroundColor Yellow
    }
} else {
    Write-Host "  clean"
}

# ---------------------------------------------------------------------------
Section 2 "Duplicate import migrations"
# The importers were run more than once. Each insert is guarded by a title
# check, so the extra copies are no-ops - but they are megabytes of SQL that
# replay on every fresh 'supabase db push'.
foreach ($kind in @("import_wikibooks", "import_themealdb")) {
    $files = @(Get-ChildItem "supabase/migrations/*$kind*.sql" -ErrorAction SilentlyContinue |
               Sort-Object Length -Descending)
    if ($files.Count -le 1) { continue }
    Write-Host "  $kind :"
    $keep = $files[0]
    foreach ($f in $files) {
        $tag = if ($f.FullName -eq $keep.FullName) { "KEEP (largest)" } else { "remove" }
        Write-Host ("    {0,7:N0} KB  {1,-14} {2}" -f ($f.Length/1KB), $tag, $f.Name)
    }
    if ($Apply) {
        foreach ($f in $files | Where-Object { $_.FullName -ne $keep.FullName }) {
            git rm --quiet $("supabase/migrations/" + $f.Name)
            Write-Host ("    removed {0}" -f $f.Name) -ForegroundColor Green
        }
    }
}

# ---------------------------------------------------------------------------
Section 3 "Empty or stub migrations"
$stubs = @(Get-ChildItem "supabase/migrations/*.sql" | Where-Object { $_.Length -lt 500 })
if ($stubs.Count -gt 0) {
    $stubs | ForEach-Object { Write-Host ("    {0,5} bytes  {1}" -f $_.Length, $_.Name) }
    Write-Host "  Check these by hand. A short migration can be legitimate." -ForegroundColor Yellow
} else {
    Write-Host "  none"
}

# ---------------------------------------------------------------------------
Section 4 "Node tooling"
$js = @(Get-ChildItem "tools/*.js" -ErrorAction SilentlyContinue)
if (Test-Path "package.json") {
    Write-Host ("  package.json present, {0} js tools in tools/" -f $js.Count)
    $js | ForEach-Object { Write-Host "    $($_.Name)" }
    Write-Host "  These exported data out of Firebase. That migration is finished."
    Write-Host "  Keep them only if you might re-run it; otherwise remove them" -ForegroundColor Yellow
    Write-Host "  along with package.json and package-lock.json." -ForegroundColor Yellow
} else {
    Write-Host "  none"
}

# ---------------------------------------------------------------------------
Section 5 "gitignore coverage"
$gi = if (Test-Path ".gitignore") { Get-Content ".gitignore" -Raw } else { "" }
foreach ($p in @("out/", "build/", ".dart_tool/", ".env", "*.tflite")) {
    $has = $gi -match [regex]::Escape($p)
    $mark = if ($has) { "ok     " } else { "MISSING" }
    $colour = if ($has) { "Gray" } else { "Yellow" }
    Write-Host ("    {0}  {1}" -f $mark, $p) -ForegroundColor $colour
}

# ---------------------------------------------------------------------------
Section 6 "Repository size"
git count-objects -vH | Select-String "size-pack|count" | ForEach-Object { Write-Host "    $_" }

# ---------------------------------------------------------------------------
Section 7 "Next"
if ($Apply) {
    Write-Host "  Review, then commit:"
    Write-Host "    git status --short"
    Write-Host "    git add -A"
    Write-Host '    git commit -m "chore: untrack generated output, drop duplicate migrations"'
    Write-Host "    git push"
} else {
    Write-Host "  Re-run with -Apply to make the changes above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  Untracking leaves the files in history, so clones still download" -ForegroundColor Gray
Write-Host "  them. Purging history needs git-filter-repo and forces everyone" -ForegroundColor Gray
Write-Host "  to re-clone. Working alone, untracking is enough." -ForegroundColor Gray
Write-Host ""
