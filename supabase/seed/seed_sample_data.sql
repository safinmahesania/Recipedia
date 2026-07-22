-- Recipedia — SAMPLE/SEED data (safe to delete later; see cleanup at bottom).
-- Run in Supabase SQL Editor after the schema migration.
-- NOTE: recipes need an author_id from public.profiles. This script grabs the
-- first existing profile. So sign up at least ONE user in the app first,
-- OR replace :author with a real profiles.id before running.

do $$
declare
  v_author   uuid;
  cat_main   uuid := gen_random_uuid();
  cat_bev    uuid := gen_random_uuid();
  ing_aloo   uuid := gen_random_uuid();
  ing_palak  uuid := gen_random_uuid();
  ing_tomato uuid := gen_random_uuid();
  ing_salt   uuid := gen_random_uuid();
  ing_oil    uuid := gen_random_uuid();
  ing_mango  uuid := gen_random_uuid();
  ing_milk   uuid := gen_random_uuid();
  ing_sugar  uuid := gen_random_uuid();
  r_aloo     uuid := gen_random_uuid();
  r_mango    uuid := gen_random_uuid();
begin
  select id into v_author from public.profiles limit 1;
  if v_author is null then
    raise exception 'No profile found. Sign up one user in the app first, then re-run.';
  end if;

  -- categories
  insert into public.categories (id, name, kind) values
    (cat_main, 'Main Course', 'food'),
    (cat_bev,  'Juices',      'beverage');

  -- ingredients  (is_pantry = common at-home items)
  insert into public.ingredients (id, name, is_pantry) values
    (ing_aloo,   'aloo',   false),
    (ing_palak,  'palak',  false),
    (ing_tomato, 'tomato', false),
    (ing_salt,   'salt',   true),
    (ing_oil,    'oil',    true),
    (ing_mango,  'mango',  false),
    (ing_milk,   'milk',   false),
    (ing_sugar,  'sugar',  true);

  -- recipe 1: Aloo Palak (core: aloo, palak | optional: tomato | pantry: salt, oil)
  insert into public.recipes (id, title, instructions, cook_time, diet, category_id, author_id, status)
  values (r_aloo, 'Aloo Palak', 'Saute aloo, add palak, cook till soft.', '30 min', 'Vegetarian', cat_main, v_author, 'approved');
  insert into public.recipe_ingredients (recipe_id, ingredient_id, role, quantity) values
    (r_aloo, ing_aloo,   'core',     '2 medium'),
    (r_aloo, ing_palak,  'core',     '1 bunch'),
    (r_aloo, ing_tomato, 'optional', '1'),
    (r_aloo, ing_salt,   'core',     'to taste'),
    (r_aloo, ing_oil,    'core',     '2 tbsp');

  -- recipe 2: Mango Juice (beverage)
  insert into public.recipes (id, title, instructions, cook_time, diet, category_id, author_id, status)
  values (r_mango, 'Mango Juice', 'Blend mango, milk, sugar.', '5 min', 'Vegetarian', cat_bev, v_author, 'approved');
  insert into public.recipe_ingredients (recipe_id, ingredient_id, role, quantity) values
    (r_mango, ing_mango, 'core', '1'),
    (r_mango, ing_milk,  'core', '1 cup'),
    (r_mango, ing_sugar, 'core', '2 tbsp');

  raise notice 'Seed done. Author used: %', v_author;
end $$;

-- ===================== CLEANUP (run later to remove seed) =====================
-- delete from public.recipes    where title in ('Aloo Palak','Mango Juice');
-- delete from public.categories where name  in ('Main Course','Juices');
-- delete from public.ingredients where name in ('aloo','palak','tomato','salt','oil','mango','milk','sugar');
-- (recipe_ingredients auto-delete via ON DELETE CASCADE when recipes are removed)
