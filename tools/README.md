# Firebase -> Supabase recipe migration

## 1. Export from Firestore
```
npm install firebase-admin
# put serviceAccountKey.json here (Firebase console -> Project settings -> Service accounts)
node export_firestore.js        # -> recipes.json
```

## 2. Run the cuisine migration first
Apply `supabase/migrations/20260723000002_add_cuisine.sql` (SQL Editor or `supabase db push`).

## 3. Get your admin profile id
Supabase SQL Editor:
```sql
select id from profiles where email = 'your@email.com';
```

## 4. Dry run, then import
```
npm install @supabase/supabase-js

# PowerShell
$env:SUPABASE_URL="https://xxxx.supabase.co"
$env:SUPABASE_SECRET_KEY="sb_secret_..."     # secret key, NOT publishable
$env:AUTHOR_ID="<uuid from step 3>"

node import_recipes.js            # dry run — prints parsed output for 5 recipes
node import_recipes.js --write    # real import
```

## Notes
- The dry run exists so you can check ingredient parsing before touching the DB.
- `PANTRY` in import_recipes.js is the list of common at-home items. Grow it as
  you spot more in your data, then re-run — existing ingredients are reused.
- The secret key bypasses RLS. Use it only here, never in the Flutter app.
