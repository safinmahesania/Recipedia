-- Profile, preferences, collections, planning.
--
-- One migration for the whole profile/UX pass so it lands atomically:
--   * profile fields (username, bio, preferences, notification prefs)
--   * favorite collections
--   * per-user allergies and pantry staples
--   * cooked history, shopping list, meal plan
--   * profile_stats() so the profile screen is one round trip, not three
--   * match_recipes_for_user() — scan matching that respects the signed-in
--     user's own staples and flags allergens
--
-- Notification preference columns are stored now and read by the settings UI,
-- but nothing sends yet: FCM is still pending.

-- =====================================================================
-- profiles
-- =====================================================================
alter table public.profiles
  add column if not exists username        text unique,
  add column if not exists bio             text,
  add column if not exists diet_preference text,
  add column if not exists default_cuisine text,
  add column if not exists units           text not null default 'metric'
                                           check (units in ('metric','imperial')),
  add column if not exists language        text not null default 'en',
  add column if not exists theme_mode      text not null default 'system'
                                           check (theme_mode in ('system','light','dark')),
  add column if not exists hide_unsafe     boolean not null default true,
  add column if not exists notify_new_recipes       boolean not null default true,
  add column if not exists notify_submission_status boolean not null default true,
  add column if not exists notify_review_replies    boolean not null default true;

-- Usernames are case-insensitively unique. The column is nullable so existing
-- rows stay valid; the app prompts for one on first visit to the profile.
create unique index if not exists profiles_username_lower_idx
  on public.profiles (lower(username)) where username is not null;

-- =====================================================================
-- collections (FR: organise saved recipes)
-- =====================================================================
create table if not exists public.collections (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  name       text not null,
  sort_order int  not null default 0,
  created_at timestamptz not null default now(),
  unique (user_id, name)
);
create index if not exists collections_user_idx on public.collections(user_id);

alter table public.favorites
  add column if not exists collection_id uuid references public.collections(id) on delete set null;
create index if not exists favorites_collection_idx on public.favorites(collection_id);

-- =====================================================================
-- per-user ingredient preferences
-- =====================================================================
create table if not exists public.user_allergies (
  user_id       uuid not null references public.profiles(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (user_id, ingredient_id)
);

-- `ingredients.is_pantry` is global. This makes it personal: whatever a user
-- marks here stops counting as "missing" in their scan results.
create table if not exists public.user_pantry_staples (
  user_id       uuid not null references public.profiles(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  created_at    timestamptz not null default now(),
  primary key (user_id, ingredient_id)
);

-- =====================================================================
-- activity
-- =====================================================================
create table if not exists public.cooked_history (
  id        uuid primary key default gen_random_uuid(),
  user_id   uuid not null references public.profiles(id) on delete cascade,
  recipe_id uuid not null references public.recipes(id) on delete cascade,
  cooked_at timestamptz not null default now(),
  note      text
);
create index if not exists cooked_history_user_idx on public.cooked_history(user_id, cooked_at desc);

-- =====================================================================
-- shopping list — fed by missing_names from the scan
-- =====================================================================
create table if not exists public.shopping_list_items (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references public.profiles(id) on delete cascade,
  ingredient_id uuid references public.ingredients(id) on delete set null,
  custom_name   text,
  recipe_id     uuid references public.recipes(id) on delete set null,
  quantity      text,
  checked       boolean not null default false,
  created_at    timestamptz not null default now(),
  -- an item is either a known ingredient or a free-text one, never neither
  check (ingredient_id is not null or custom_name is not null)
);
create index if not exists shopping_user_idx on public.shopping_list_items(user_id, checked);

-- =====================================================================
-- meal plan
-- =====================================================================
create table if not exists public.meal_plan_entries (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  recipe_id  uuid not null references public.recipes(id) on delete cascade,
  plan_date  date not null,
  slot       text not null check (slot in ('breakfast','lunch','dinner','snack')),
  created_at timestamptz not null default now(),
  unique (user_id, plan_date, slot, recipe_id)
);
create index if not exists meal_plan_user_date_idx on public.meal_plan_entries(user_id, plan_date);

-- =====================================================================
-- ROW LEVEL SECURITY — every table here is owner-only
-- =====================================================================
alter table public.collections          enable row level security;
alter table public.user_allergies       enable row level security;
alter table public.user_pantry_staples  enable row level security;
alter table public.cooked_history       enable row level security;
alter table public.shopping_list_items  enable row level security;
alter table public.meal_plan_entries    enable row level security;

do $$
declare t text;
begin
  foreach t in array array[
    'collections','user_allergies','user_pantry_staples',
    'cooked_history','shopping_list_items','meal_plan_entries'
  ] loop
    execute format(
      'create policy %I on public.%I for all using (user_id = auth.uid()) with check (user_id = auth.uid())',
      t || '_own', t);
  end loop;
end $$;

-- =====================================================================
-- profile_stats — one call instead of three counts
-- =====================================================================
create or replace function public.profile_stats(uid uuid)
returns table (saved bigint, submitted bigint, reviews bigint, cooked bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select
    (select count(*) from public.favorites      where user_id = uid),
    (select count(*) from public.recipes        where author_id = uid),
    (select count(*) from public.reviews        where user_id = uid),
    (select count(*) from public.cooked_history where user_id = uid);
$$;

-- =====================================================================
-- match_recipes_for_user — scan matching v3
--
-- v2 excluded globally-flagged pantry items. v3 also excludes whatever THIS
-- user marked as a staple, and reports whether a recipe contains one of their
-- allergens so the UI can hide it or warn, per their `hide_unsafe` setting.
-- =====================================================================
create or replace function public.match_recipes_for_user(scanned text[])
returns table (
  id            uuid,
  title         text,
  image_url     text,
  cook_time     text,
  diet          text,
  cuisine       text,
  matched_count bigint,
  missing_count bigint,
  missing_names text[],
  has_allergen  boolean
)
language sql
stable
security invoker
set search_path = public
as $$
  with me as (select auth.uid() as uid),
  staples as (
    select ingredient_id from public.user_pantry_staples, me where user_id = me.uid
  ),
  allergens as (
    select ingredient_id from public.user_allergies, me where user_id = me.uid
  ),
  core as (
    select r.id as recipe_id, r.title, r.image_url, r.cook_time, r.diet, r.cuisine,
           lower(i.name) as ing_name,
           (ri.ingredient_id in (select ingredient_id from allergens)) as is_allergen
    from public.recipes r
    join public.recipe_ingredients ri on ri.recipe_id = r.id and ri.role = 'core'
    join public.ingredients i on i.id = ri.ingredient_id
    where r.status = 'approved'
      and i.is_pantry = false
      and ri.ingredient_id not in (select ingredient_id from staples)
  ),
  scored as (
    select recipe_id, title, image_url, cook_time, diet, cuisine,
           count(*) filter (where ing_name = any (scanned))  as matched_count,
           count(*) filter (where ing_name <> all (scanned)) as missing_count,
           array_agg(ing_name) filter (where ing_name <> all (scanned)) as missing_names,
           bool_or(is_allergen) as has_allergen
    from core
    group by recipe_id, title, image_url, cook_time, diet, cuisine
  )
  select recipe_id, title, image_url, cook_time, diet, cuisine,
         matched_count, missing_count, coalesce(missing_names, '{}'),
         coalesce(has_allergen, false)
  from scored
  where matched_count > 0
  order by missing_count asc, matched_count desc, title
  limit 60;
$$;
