# Verifying the database

`tools/verify_database.sql` — paste into the **Supabase SQL Editor** and run.

Read-only. No writes, no locks held beyond the query, safe against production.
Takes a second or two.

## What comes back

One table, worst first:

| Severity | Meaning |
|---|---|
| **FAIL** | something the app depends on is missing or broken |
| **WARN** | works today, degrades a feature or will bite you later |
| **INFO** | a number worth knowing |

If there are no FAIL rows, the schema is sound. Scroll for WARNs.

## The checks that matter most

**`recipes with no CORE ingredients`** — a recipe with no core ingredients can
never be returned by `match_recipes_for_user`. It is invisible to the feature
the app exists for, and nothing in the UI hints at why.

**`avg core ingredients per recipe`** — the single best predictor of whether
scan works. Under 4 and matching is unreliable regardless of how many recipes
you have. This is the number to watch after any import.

**`duplicate ingredient names`** — a FAIL rather than a warning. Two rows for
"tomato" means recipes split across both, so a scan for tomato finds half of
them. Five migrations went into eliminating these.

**`RLS disabled`** and **`tables with no policy`** — with RLS off, the anon key
reads everything. With RLS on and no policy, nobody reads anything. Both are
silent until someone notices.

**`licensed recipes with no source_url`** — CC BY-SA requires attribution. A
row with a licence and no link is a breach, not an untidy record.

**`external image URLs`** — third-party hosts hotlink-block and hang rather
than erroring, which is what made recipe images appear blank. The illustration
system covers every recipe already, so nulling these costs nothing.

## When to run it

- after any import
- after any migration
- before deploying
- when something behaves oddly and you want to rule the data out

## Fixing what it finds

Most FAILs point at one of these:

```sql
-- recipes with no ingredients: delete them, they can never match
delete from public.recipes r
where not exists (
  select 1 from public.recipe_ingredients ri where ri.recipe_id = r.id);

-- external images: fall back to the illustration system
update public.recipes set image_url = null
where image_url is not null and image_url not like '%supabase%';

-- find the duplicate ingredient names before merging them
select lower(trim(name)) as name, count(*), array_agg(id)
from public.ingredients group by 1 having count(*) > 1;
-- then, for each pair:
select public.merge_ingredient('duplicate name', 'canonical name');
```

`merge_ingredient` repoints every reference before deleting, so recipes keep
their ingredient rather than losing it.

---

# Duplicates

`tools/verify_duplicates.sql` — paste into the SQL Editor. Empty result is clean.

## Why the unique constraints are not enough

`ingredients.name` is `text not null unique`, and **Postgres compares text
case-sensitively**. So `Onion`, `onion` and `onion ` are three distinct values
that all satisfy the constraint. An import that title-cases its output passes
validation and splits every recipe across two rows — scan then finds half of
them, with nothing in the UI to suggest why.

Four tables have **no** unique constraint at all: `user_allergies`,
`user_pantry_staples`, `shopping_list_items` and `reports`.

## What it looks for

**Priority 1 — breaks matching**
- case or whitespace duplicate ingredient names
- one alias claimed by two ingredients, so search is ambiguous
- an alias that is also a real ingredient name
- duplicates in tables that have a unique constraint (should be impossible; if
  it fires, the constraint was dropped)

**Priority 2 — content**
- exact duplicate recipe titles, with the source of each
- near-duplicate titles after stripping punctuation and plurals
- **identical core ingredient sets** — the strongest signal that one dish was
  imported twice under different names

**Priority 3 — user data**
- duplicate allergies, staples, open shopping items, repeated reports

## Fixing it

```sql
-- ingredients: see the variants before merging
select lower(btrim(name)), count(*), array_agg(name)
from public.ingredients group by 1 having count(*) > 1;

-- merge repoints every reference before deleting, so recipes keep the link
select public.merge_ingredient('Onion', 'onion');

-- duplicate recipes: keep the oldest of each title
delete from public.recipes r using public.recipes k
where lower(btrim(r.title)) = lower(btrim(k.title))
  and r.created_at > k.created_at;
```

## Then prevent it

Migration `019_duplicate_guards` adds case-insensitive unique indexes and the
missing constraints. **Run the check first** — if duplicates exist the indexes
will fail to build, which is the intended behaviour rather than a problem.
