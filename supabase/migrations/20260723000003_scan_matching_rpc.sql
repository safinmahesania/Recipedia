-- Required for the trigram index used by title search.
create extension if not exists pg_trgm;

-- Move scan matching into the database.
-- Previously the app downloaded every approved recipe with its ingredients and
-- filtered in Dart — fine for a handful of rows, far too heavy at 1000+.
--
-- Rule (unchanged): a recipe matches when every one of its CORE, non-pantry
-- ingredients was scanned. Pantry items (salt, oil, spices) and optional
-- ingredients never block a match.

create or replace function public.match_recipes_by_ingredients(scanned text[])
returns setof public.recipes
language sql
stable
security invoker          -- respects RLS: only approved rows leak out
set search_path = public
as $$
  select r.*
  from public.recipes r
  where r.status = 'approved'
    -- must have at least one real (non-pantry) core ingredient
    and exists (
      select 1
      from public.recipe_ingredients ri
      join public.ingredients i on i.id = ri.ingredient_id
      where ri.recipe_id = r.id
        and ri.role = 'core'
        and i.is_pantry = false
    )
    -- and none of those may be missing from the scanned list
    and not exists (
      select 1
      from public.recipe_ingredients ri
      join public.ingredients i on i.id = ri.ingredient_id
      where ri.recipe_id = r.id
        and ri.role = 'core'
        and i.is_pantry = false
        and lower(i.name) <> all (scanned)
    )
  order by r.created_at desc
  limit 100;
$$;

-- helps the lookups above
create index if not exists recipe_ingredients_recipe_role_idx
  on public.recipe_ingredients(recipe_id, role);
create index if not exists ingredients_pantry_idx
  on public.ingredients(is_pantry);
-- speeds up title search
create index if not exists recipes_title_trgm_idx
  on public.recipes using gin (title gin_trgm_ops);
