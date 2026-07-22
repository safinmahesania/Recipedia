-- Recipedia — initial schema + RLS
-- Run via Supabase CLI (supabase db push) or paste into the SQL editor.

-- ---------- profiles (linked to Supabase auth users) ----------
create table public.profiles (
  id            uuid primary key references auth.users(id) on delete cascade,
  name          text,
  email         text,
  avatar_url    text,
  role          text not null default 'user' check (role in ('user','admin')),
  created_at    timestamptz not null default now()
);

-- auto-create a profile row when a user signs up
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, name)
  values (new.id, new.email, new.raw_user_meta_data->>'name');
  return new;
end;
$$;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------- helper: is the current user an admin? ----------
create or replace function public.is_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

-- ---------- categories ----------
create table public.categories (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  kind       text not null default 'food' check (kind in ('food','beverage')),
  created_at timestamptz not null default now()
);

-- ---------- recipes ----------
create table public.recipes (
  id               uuid primary key default gen_random_uuid(),
  title            text not null,
  instructions     text,
  image_url        text,
  cook_time        text,
  diet             text,
  category_id      uuid references public.categories(id) on delete set null,
  author_id        uuid not null references public.profiles(id) on delete cascade,
  status           text not null default 'pending' check (status in ('pending','approved','rejected')),
  rejection_reason text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create index recipes_status_idx   on public.recipes(status);
create index recipes_category_idx on public.recipes(category_id);

-- ---------- ingredients (master list) ----------
create table public.ingredients (
  id         uuid primary key default gen_random_uuid(),
  name       text not null unique,
  is_pantry  boolean not null default false,   -- common/at-home (namak, tel, spices)
  created_at timestamptz not null default now()
);

-- ---------- recipe_ingredients (link + role) ----------
create table public.recipe_ingredients (
  id            uuid primary key default gen_random_uuid(),
  recipe_id     uuid not null references public.recipes(id) on delete cascade,
  ingredient_id uuid not null references public.ingredients(id) on delete cascade,
  role          text not null default 'core' check (role in ('core','optional')),
  quantity      text,
  unique (recipe_id, ingredient_id)
);
create index recipe_ingredients_ingredient_idx on public.recipe_ingredients(ingredient_id);

-- ---------- favorites ----------
create table public.favorites (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  recipe_id  uuid not null references public.recipes(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (user_id, recipe_id)
);

-- ---------- reviews ----------
create table public.reviews (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references public.profiles(id) on delete cascade,
  recipe_id  uuid not null references public.recipes(id) on delete cascade,
  rating     int  not null check (rating between 1 and 5),
  comment    text,
  created_at timestamptz not null default now(),
  unique (user_id, recipe_id)
);

-- ---------- reports ----------
create table public.reports (
  id          uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('recipe','review','user')),
  target_id   uuid not null,
  reason      text not null,
  status      text not null default 'open' check (status in ('open','resolved','dismissed')),
  created_at  timestamptz not null default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY
-- =====================================================================
alter table public.profiles           enable row level security;
alter table public.categories         enable row level security;
alter table public.recipes            enable row level security;
alter table public.ingredients        enable row level security;
alter table public.recipe_ingredients enable row level security;
alter table public.favorites          enable row level security;
alter table public.reviews            enable row level security;
alter table public.reports            enable row level security;

-- profiles: anyone can read basic profile; you update your own; admins do anything
create policy profiles_read   on public.profiles for select using (true);
create policy profiles_update on public.profiles for update using (id = auth.uid() or is_admin());

-- categories & ingredients: public read, admin write
create policy categories_read  on public.categories  for select using (true);
create policy categories_admin on public.categories  for all    using (is_admin()) with check (is_admin());
create policy ingredients_read  on public.ingredients for select using (true);
create policy ingredients_admin on public.ingredients for all    using (is_admin()) with check (is_admin());

-- recipes: see approved (everyone) or your own (any status) or all (admin)
create policy recipes_read on public.recipes for select
  using (status = 'approved' or author_id = auth.uid() or is_admin());
-- create your own (starts pending)
create policy recipes_insert on public.recipes for insert
  with check (author_id = auth.uid());
-- edit: your own while not yet approved, OR admin (admin also approves/rejects)
create policy recipes_update on public.recipes for update
  using (is_admin() or (author_id = auth.uid() and status <> 'approved'));
create policy recipes_delete on public.recipes for delete
  using (is_admin() or (author_id = auth.uid() and status <> 'approved'));

-- recipe_ingredients: readable if the parent recipe is; writable by its author (while pending) or admin
create policy ri_read on public.recipe_ingredients for select
  using (exists (select 1 from public.recipes r where r.id = recipe_id
                 and (r.status = 'approved' or r.author_id = auth.uid() or is_admin())));
create policy ri_write on public.recipe_ingredients for all
  using (is_admin() or exists (select 1 from public.recipes r where r.id = recipe_id
                 and r.author_id = auth.uid() and r.status <> 'approved'))
  with check (is_admin() or exists (select 1 from public.recipes r where r.id = recipe_id
                 and r.author_id = auth.uid() and r.status <> 'approved'));

-- favorites: you manage only your own
create policy favorites_own on public.favorites for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- reviews: public read; you manage only your own
create policy reviews_read on public.reviews for select using (true);
create policy reviews_own  on public.reviews for all
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- reports: you file your own; admins read/resolve
create policy reports_insert on public.reports for insert with check (reporter_id = auth.uid());
create policy reports_admin  on public.reports for select using (is_admin() or reporter_id = auth.uid());
create policy reports_update on public.reports for update using (is_admin());