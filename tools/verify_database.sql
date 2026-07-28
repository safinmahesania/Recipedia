-- Recipedia database health check.
--
-- Paste into the Supabase SQL Editor and run. Read-only: no writes, no locks
-- held beyond the query. Returns one table, worst problems first.
--
-- Severity means:
--   FAIL  something the app depends on is missing or broken
--   WARN  works today, will bite you later or degrades a feature
--   INFO  a number worth knowing, not a problem
--
-- Ordered so FAILs are at the top. If there are none, scroll for WARNs.

with

-- ---------------------------------------------------------------- structure
expected_tables(name) as (values
  ('profiles'),('categories'),('recipes'),('ingredients'),('recipe_ingredients'),
  ('favorites'),('collections'),('reviews'),('reports'),('user_allergies'),
  ('user_pantry_staples'),('shopping_list_items'),('meal_plan_entries'),
  ('cooked_history')
),
missing_tables as (
  select string_agg(e.name, ', ') as detail, count(*) as n
  from expected_tables e
  where not exists (
    select 1 from information_schema.tables t
    where t.table_schema = 'public' and t.table_name = e.name)
),

expected_functions(name) as (values
  ('match_recipes_for_user'),('profile_stats'),('distinct_diets'),
  ('distinct_cuisines'),('is_admin'),('handle_new_user'),
  ('merge_ingredient'),('search_ingredients')
),
missing_functions as (
  select string_agg(e.name, ', ') as detail, count(*) as n
  from expected_functions e
  where not exists (
    select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and p.proname = e.name)
),

rls_off as (
  select string_agg(c.relname, ', ') as detail, count(*) as n
  from pg_class c join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public' and c.relkind = 'r'
    and c.relname in (select name from expected_tables)
    and not c.relrowsecurity
),

no_policies as (
  select string_agg(t.name, ', ') as detail, count(*) as n
  from expected_tables t
  where not exists (
    select 1 from pg_policies p
    where p.schemaname = 'public' and p.tablename = t.name)
),

-- ------------------------------------------------------------ core content
counts as (
  select
    (select count(*) from public.recipes)             as recipes,
    (select count(*) from public.recipes where status = 'approved') as approved,
    (select count(*) from public.ingredients)         as ingredients,
    (select count(*) from public.recipe_ingredients)  as links,
    (select count(*) from public.profiles)            as profiles,
    (select count(*) from public.categories)          as categories
),

-- A recipe with no ingredients can never be matched by scan. It is invisible
-- to the feature the app exists for.
recipes_no_ingredients as (
  select count(*) as n from public.recipes r
  where not exists (select 1 from public.recipe_ingredients ri
                    where ri.recipe_id = r.id)
),

-- Core ingredients are what matching actually uses; optional ones never block.
recipes_no_core as (
  select count(*) as n from public.recipes r
  where not exists (select 1 from public.recipe_ingredients ri
                    where ri.recipe_id = r.id and ri.role = 'core')
),

thin_recipes as (
  select count(*) as n from (
    select ri.recipe_id from public.recipe_ingredients ri
    where ri.role = 'core'
    group by ri.recipe_id having count(*) < 3
  ) t
),

avg_ingredients as (
  select round(avg(c)::numeric, 1) as v from (
    select count(*) c from public.recipe_ingredients
    where role = 'core' group by recipe_id
  ) t
),

no_instructions as (
  select count(*) as n from public.recipes
  where instructions is null or length(trim(instructions)) < 20
),

no_title as (
  select count(*) as n from public.recipes
  where title is null or length(trim(title)) = 0
),

dup_titles as (
  select count(*) as n from (
    select lower(trim(title)) from public.recipes
    group by 1 having count(*) > 1) t
),

-- ------------------------------------------------------------- ingredients
dup_ingredients as (
  select count(*) as n, string_agg(distinct nm, ', ') as detail from (
    select lower(trim(name)) as nm from public.ingredients
    group by 1 having count(*) > 1) t
),

ingredients_unused as (
  select count(*) as n from public.ingredients i
  where not exists (select 1 from public.recipe_ingredients ri
                    where ri.ingredient_id = i.id)
),

ingredients_no_icon as (
  select count(*) as n from public.ingredients where icon_key is null
),

ingredients_no_category as (
  select count(*) as n from public.ingredients where category is null
),

-- An alias that duplicates a real ingredient name makes search ambiguous.
alias_collisions as (
  select count(*) as n, string_agg(distinct a, ', ') as detail
  from (select unnest(aliases) as a from public.ingredients) x
  where exists (select 1 from public.ingredients i where lower(i.name) = x.a)
),

-- ------------------------------------------------------- matching and diet
diet_missing as (
  select count(*) as n from public.recipes
  where status = 'approved' and (diet is null or trim(diet) = '')
),
cuisine_missing as (
  select count(*) as n from public.recipes
  where status = 'approved' and (cuisine is null or trim(cuisine) = '')
),
category_missing as (
  select count(*) as n from public.recipes
  where status = 'approved' and category_id is null
),

-- ------------------------------------------------------------- attribution
license_no_source as (
  select count(*) as n from public.recipes
  where license is not null and (source_url is null or trim(source_url) = '')
),

-- ------------------------------------------------------------------ images
external_images as (
  select count(*) as n from public.recipes
  where image_url is not null and trim(image_url) <> ''
    and image_url not like '%supabase%'
),

-- ------------------------------------------------------------- user tables
orphan_staples as (
  select count(*) as n from public.user_pantry_staples s
  where not exists (select 1 from public.ingredients i where i.id = s.ingredient_id)
),
admins as (select count(*) as n from public.profiles where role = 'admin')

-- ===========================================================================
select * from (
  select 1 as ord, 'FAIL' as severity, 'expected tables missing' as check_name,
         n::text as result, detail from missing_tables where n > 0
  union all
  select 1, 'FAIL', 'expected functions missing', n::text, detail
    from missing_functions where n > 0
  union all
  select 1, 'FAIL', 'RLS disabled on tables', n::text, detail
    from rls_off where n > 0
  union all
  select 1, 'FAIL', 'tables with no RLS policy', n::text, detail
    from no_policies where n > 0
  union all
  select 1, 'FAIL', 'no admin account exists', n::text,
         'admin portal and moderation are unreachable' from admins where n = 0
  union all
  select 1, 'FAIL', 'duplicate ingredient names', n::text, detail
    from dup_ingredients where n > 0
  union all
  select 1, 'FAIL', 'recipes with no ingredients', n::text,
         'invisible to scan matching' from recipes_no_ingredients where n > 0
  union all
  select 1, 'FAIL', 'recipes with no CORE ingredients', n::text,
         'can never match, optional ingredients do not count'
    from recipes_no_core where n > 0
  union all
  select 1, 'FAIL', 'licensed recipes with no source_url', n::text,
         'CC BY-SA requires attribution' from license_no_source where n > 0

  union all
  select 2, 'WARN', 'recipes with fewer than 3 core ingredients', n::text,
         'will match almost nothing useful' from thin_recipes where n > 0
  union all
  select 2, 'WARN', 'recipes with no or trivial instructions', n::text,
         'cook mode will show a single step' from no_instructions where n > 0
  union all
  select 2, 'WARN', 'duplicate recipe titles', n::text,
         'imports run twice, or two sources overlap' from dup_titles where n > 0
  union all
  select 2, 'WARN', 'blank recipe titles', n::text, '' from no_title where n > 0
  union all
  select 2, 'WARN', 'ingredients with no icon_key', n::text,
         'falls back to category art, then a letter chip'
    from ingredients_no_icon where n > 0
  union all
  select 2, 'WARN', 'ingredients with no category', n::text,
         'no fallback art at all' from ingredients_no_category where n > 0
  union all
  select 2, 'WARN', 'aliases colliding with real names', n::text, detail
    from alias_collisions where n > 0
  union all
  select 2, 'WARN', 'approved recipes with no diet', n::text,
         'invisible to diet filter and allergy logic' from diet_missing where n > 0
  union all
  select 2, 'WARN', 'approved recipes with no cuisine', n::text,
         'missing from Browse by cuisine' from cuisine_missing where n > 0
  union all
  select 2, 'WARN', 'approved recipes with no category', n::text,
         'missing from course filter' from category_missing where n > 0
  union all
  select 2, 'WARN', 'external image URLs', n::text,
         'third-party hosts hotlink-block and hang; illustrations are safer'
    from external_images where n > 0
  union all
  select 2, 'WARN', 'orphaned pantry staples', n::text, ''
    from orphan_staples where n > 0

  union all
  select 3, 'INFO', 'recipes', recipes::text,
         approved::text || ' approved' from counts
  union all
  select 3, 'INFO', 'ingredients', ingredients::text,
         (select n::text from ingredients_unused) || ' never used' from counts
  union all
  select 3, 'INFO', 'recipe_ingredients', links::text, '' from counts
  union all
  select 3, 'INFO', 'avg core ingredients per recipe',
         coalesce((select v::text from avg_ingredients), '0'),
         'under 4 and scan matching is unreliable' from counts
  union all
  select 3, 'INFO', 'profiles', profiles::text,
         (select n::text from admins) || ' admin' from counts
  union all
  select 3, 'INFO', 'categories', categories::text, '' from counts
) report
order by ord, check_name;
