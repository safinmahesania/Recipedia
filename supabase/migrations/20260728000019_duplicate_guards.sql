-- Stops the duplicates that the current constraints allow.
--
-- Two gaps found by tools/verify_duplicates.sql:
--
-- 1. `ingredients.name text unique` is CASE-SENSITIVE. 'Onion', 'onion' and
--    'onion ' all satisfy it, so any import that title-cases its output splits
--    every recipe across two rows and scan finds half of them. A unique index
--    on lower(btrim(name)) closes it.
--
-- 2. Four tables have no unique constraint at all. Three of them should:
--    an allergy, a pantry staple and an open shopping item are each things a
--    user has once or not at all. Reports are excluded deliberately — someone
--    reporting the same recipe twice is signal, not noise.
--
-- Run tools/verify_duplicates.sql BEFORE this. If it returns rows, these
-- indexes will fail to build, and the failure is the point: it refuses to
-- pretend the data is clean.

-- ---------------------------------------------------------------- ingredients
create unique index if not exists ingredients_name_ci_uniq
  on public.ingredients (lower(btrim(name)));

-- ---------------------------------------------------------------- categories
create unique index if not exists categories_name_ci_uniq
  on public.categories (lower(btrim(name)));

-- ------------------------------------------------------------------ profiles
-- Partial, because username is optional and many rows will be null.
create unique index if not exists profiles_username_ci_uniq
  on public.profiles (lower(btrim(username)))
  where username is not null and btrim(username) <> '';

-- ------------------------------------------- tables that had no constraint
alter table public.user_allergies
  drop constraint if exists user_allergies_user_ingredient_uniq;
alter table public.user_allergies
  add constraint user_allergies_user_ingredient_uniq
  unique (user_id, ingredient_id);

alter table public.user_pantry_staples
  drop constraint if exists user_staples_user_ingredient_uniq;
alter table public.user_pantry_staples
  add constraint user_staples_user_ingredient_uniq
  unique (user_id, ingredient_id);

-- Shopping list: unique only among UNCHECKED items, so buying flour twice in
-- two weeks is still possible while the same open list cannot list it twice.
create unique index if not exists shopping_open_item_uniq
  on public.shopping_list_items (user_id, ingredient_id)
  where checked = false and ingredient_id is not null;

create unique index if not exists shopping_open_custom_uniq
  on public.shopping_list_items (user_id, lower(btrim(custom_name)))
  where checked = false and custom_name is not null;

comment on index ingredients_name_ci_uniq is
  'Case-insensitive uniqueness. The column constraint alone allows Onion and onion.';
