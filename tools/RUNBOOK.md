# Catalogue rebuild — runbook (Windows, no psql)

`psql` is not installed on Windows by default and nothing here needs it.
Everything below uses the Supabase CLI you already have, plus Python.

---

## 0. Back up first

**Actions → Database backup → Run workflow.** Wait for green. Not last night's
run — this one. Everything after step 2 is irreversible.

## 1. Set your keys

```powershell
$env:SUPABASE_URL="https://YOURPROJECT.supabase.co"
$env:SUPABASE_ANON_KEY="eyJ..."
```

Both from **Supabase → Project Settings → API**. They last for this PowerShell
session only, so re-set them if you open a new window.

## 2. Add the attribution columns

```powershell
supabase db push
```

Applies migration `018_recipe_attribution`. Do this **before** importing —
Wikibooks is CC BY-SA and every recipe must carry its source.

## 3. Delete the scraped catalogue

Supabase dashboard → **SQL Editor** → paste the contents of
`tools/reset_catalogue.sql` → Run.

It ends with a count of what survived. Expect **0 recipes** and
**157 ingredients**. If ingredients is 0, stop — something went wrong and you
should restore the backup.

> Using the SQL Editor rather than the CLI is deliberate here. This is the one
> destructive step, and pasting it means you read it before it runs.

## 4. Export what you already know

```powershell
python tools/export_ingredients.py
```

Writes `out/existing_ingredients.txt` — canonical names **and** aliases, so the
importers do not "discover" *pyaz* as new when *onion* already covers it.

If this fails with 401, RLS is blocking anonymous reads. Use the
`service_role` key instead; it stays on your machine and never reaches the app.

## 5. Import TheMealDB

```powershell
python tools/import_themealdb.py
```

Dry run — writes nothing to the database. Then:

- open `out/new_ingredients.csv`
- set `action=skip` for anything that duplicates a name you already have
  ("spring onions" when you have "spring onion")

```powershell
python tools/import_themealdb.py --emit-sql
```

## 6. Import Wikibooks

```powershell
python tools/import_wikibooks.py --limit 300
```

Same pattern. Also check `out/wikibooks_rejected.csv` — high rejection is
expected and healthy; a page with no ingredient list is not a recipe.

```powershell
python tools/import_wikibooks.py --limit 300 --emit-sql
```

## 7. Apply the imports

Each importer writes its SQL twice: a plain `import_*.sql`, and a copy named
`<timestamp>_import_*.sql`. Move the timestamped ones into
`supabase/migrations/` and:

```powershell
supabase db push
```

That gives you the import in version control and repeatable on a fresh
database, which matters more than it sounds — you have now rebuilt this
catalogue once and would rather not do it from memory a second time.

**Alternatively**, paste `out/import_*.sql` into the SQL Editor. Same result,
not recorded anywhere.

## 8. Check

```powershell
supabase db push          # confirm no pending migrations
flutter run
```

- Recipes tab lists recipes
- **Browse by cuisine** on Home shows more than one entry
- Recipe detail shows *"Recipe from Wikibooks Cookbook · CC BY-SA 3.0"* on
  imported recipes and nothing on your own
- Scan with two or three ingredients returns matches

If scan returns nothing, the ingredient names in the import did not match your
canonical table — check `out/new_ingredients.csv` for entries you skipped that
should have been created.

---

## If you would rather have psql anyway

It ships with PostgreSQL. Install, then add
`C:\Program Files\PostgreSQL\16\bin` to PATH. Useful, but not required for any
step above.
