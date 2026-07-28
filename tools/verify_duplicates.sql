-- Duplicate detection across the whole schema.
--
-- Paste into the Supabase SQL Editor. Read-only. Empty result means clean.
--
-- WHY THIS IS NEEDED DESPITE THE UNIQUE CONSTRAINTS
--
-- ingredients.name is `text not null unique`, and Postgres compares text
-- case-sensitively. So 'Onion', 'onion' and 'onion ' are three distinct values
-- that all satisfy the constraint. An import that title-cases its output will
-- sail straight through and split every recipe across two rows.
--
-- And four tables have no unique constraint at all: user_allergies,
-- user_pantry_staples, shopping_list_items and reports.

with

-- ---------------------------------------------------------------- ingredients
ing_dupes as (
  select lower(btrim(name)) as norm, count(*) as n,
         string_agg(name, ' | ' order by name) as variants
  from public.ingredients
  group by 1 having count(*) > 1
),

-- Same alias claimed by two different ingredients: search becomes ambiguous
-- and whichever row sorts first silently wins.
alias_shared as (
  select a as alias, count(*) as n,
         string_agg(name, ' | ' order by name) as claimed_by
  from (select name, unnest(aliases) as a from public.ingredients) x
  group by a having count(*) > 1
),

-- An alias that is also a real ingredient name. Typing it should find the
-- ingredient, not silently resolve to something else.
alias_is_name as (
  select x.a as alias, x.name as alias_owner, i.name as real_ingredient
  from (select name, unnest(aliases) as a from public.ingredients) x
  join public.ingredients i on lower(i.name) = x.a
  where lower(i.name) <> lower(x.name)
),

-- -------------------------------------------------------------------- recipes
recipe_title_dupes as (
  select lower(btrim(title)) as norm, count(*) as n,
         string_agg(coalesce(source_name, 'user'), ' | ') as sources
  from public.recipes
  group by 1 having count(*) > 1
),

-- Same title after stripping punctuation and plurals — two sources describing
-- one dish. "Chicken Curry" vs "Chicken curry." vs "Chicken Curries".
recipe_title_near as (
  select norm, count(*) as n, string_agg(title, ' | ' order by title) as titles
  from (
    select id, title,
           regexp_replace(
             regexp_replace(lower(btrim(title)), '[^a-z0-9 ]', '', 'g'),
             '(e?s)\b', '', 'g') as norm
    from public.recipes
  ) t
  group by norm having count(*) > 1
),

-- Identical CORE ingredient sets. Almost always the same recipe imported
-- twice under slightly different names.
recipe_same_ingredients as (
  select fingerprint, count(*) as n,
         string_agg(title, ' | ' order by title) as titles
  from (
    select r.id, r.title,
           md5(string_agg(ri.ingredient_id::text, ',' order by ri.ingredient_id))
             as fingerprint
    from public.recipes r
    join public.recipe_ingredients ri on ri.recipe_id = r.id and ri.role = 'core'
    group by r.id, r.title
    having count(*) >= 4          -- below 4 a shared set means little
  ) t
  group by fingerprint having count(*) > 1
),

-- ----------------------------------------------------------------- categories
category_dupes as (
  select lower(btrim(name)) as norm, count(*) as n,
         string_agg(name, ' | ') as variants
  from public.categories group by 1 having count(*) > 1
),

-- ------------------------------------------------------------------- profiles
profile_username_dupes as (
  select lower(btrim(username)) as norm, count(*) as n
  from public.profiles
  where username is not null and btrim(username) <> ''
  group by 1 having count(*) > 1
),

-- ------------------------------------------- tables with NO unique constraint
allergy_dupes as (
  select count(*) as n from (
    select user_id, ingredient_id from public.user_allergies
    group by 1, 2 having count(*) > 1) t
),
staple_dupes as (
  select count(*) as n from (
    select user_id, ingredient_id from public.user_pantry_staples
    group by 1, 2 having count(*) > 1) t
),
-- Same ingredient twice on one list. Not fatal, but the user sees it twice
-- and ticking one leaves the other.
shopping_dupes as (
  select count(*) as n from (
    select user_id,
           coalesce(ingredient_id::text, lower(btrim(custom_name))) as item
    from public.shopping_list_items
    where checked = false
    group by 1, 2 having count(*) > 1) t
),
report_dupes as (
  select count(*) as n from (
    select reporter_id, target_type, target_id from public.reports
    where status = 'open'
    group by 1, 2, 3 having count(*) > 1) t
),

-- ------------------------------------------- constraints that should hold
link_dupes as (
  select count(*) as n from (
    select recipe_id, ingredient_id from public.recipe_ingredients
    group by 1, 2 having count(*) > 1) t
),
favorite_dupes as (
  select count(*) as n from (
    select user_id, recipe_id from public.favorites
    group by 1, 2 having count(*) > 1) t
),
review_dupes as (
  select count(*) as n from (
    select user_id, recipe_id from public.reviews
    group by 1, 2 having count(*) > 1) t
)

select * from (
  select 1 as ord, 'ingredients' as area,
         'case/whitespace duplicate name' as issue,
         norm as subject, n::text || ' rows: ' || variants as detail
  from ing_dupes
  union all
  select 1, 'ingredients', 'alias claimed by two ingredients', alias,
         n::text || ' rows: ' || claimed_by from alias_shared
  union all
  select 1, 'ingredients', 'alias is also a real ingredient name', alias,
         'alias on ' || alias_owner || ', but ' || real_ingredient || ' exists'
  from alias_is_name
  union all
  select 1, 'recipe_ingredients', 'duplicate link despite unique constraint',
         'recipe/ingredient pair', n::text from link_dupes where n > 0
  union all
  select 1, 'favorites', 'duplicate despite unique constraint',
         'user/recipe pair', n::text from favorite_dupes where n > 0
  union all
  select 1, 'reviews', 'duplicate despite unique constraint',
         'user/recipe pair', n::text from review_dupes where n > 0

  union all
  select 2, 'recipes', 'exact duplicate title', norm,
         n::text || ' copies, from: ' || sources from recipe_title_dupes
  union all
  select 2, 'recipes', 'near-duplicate title', norm,
         n::text || ': ' || titles from recipe_title_near
  union all
  select 2, 'recipes', 'identical core ingredient set', left(fingerprint, 8),
         n::text || ': ' || titles from recipe_same_ingredients
  union all
  select 2, 'categories', 'case duplicate', norm,
         n::text || ' rows: ' || variants from category_dupes
  union all
  select 2, 'profiles', 'duplicate username', norm, n::text || ' accounts'
  from profile_username_dupes

  union all
  select 3, 'user_allergies', 'duplicate rows (no unique constraint)',
         'user/ingredient', n::text from allergy_dupes where n > 0
  union all
  select 3, 'user_pantry_staples', 'duplicate rows (no unique constraint)',
         'user/ingredient', n::text from staple_dupes where n > 0
  union all
  select 3, 'shopping_list_items', 'same item twice on one open list',
         'user/item', n::text from shopping_dupes where n > 0
  union all
  select 3, 'reports', 'same target reported twice by one user',
         'reporter/target', n::text from report_dupes where n > 0
) findings
order by ord, area, issue, subject;
