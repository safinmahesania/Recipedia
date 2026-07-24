-- Scan matching v2: partial matches, ranked.
--
-- v1 required EVERY core ingredient to be scanned. With 1000+ real recipes
-- (5-10 ingredients each) that almost never fires — searching "fish" returned
-- one recipe while dozens actually use fish.
--
-- v2 returns any recipe that uses at least one scanned ingredient, annotated
-- with what is still missing, ordered so "you can cook this now" comes first.

drop function if exists public.match_recipes_by_ingredients(text[]);

create or replace function public.match_recipes_by_ingredients(scanned text[])
returns table (
  id             uuid,
  title          text,
  image_url      text,
  cook_time      text,
  diet           text,
  cuisine        text,
  matched_count  bigint,
  missing_count  bigint,
  missing_names  text[]
)
language sql
stable
security invoker
set search_path = public
as $$
  with core as (
    -- every real (non-pantry) core ingredient of every approved recipe
    select r.id   as recipe_id,
           r.title, r.image_url, r.cook_time, r.diet, r.cuisine,
           lower(i.name) as ing_name
    from public.recipes r
    join public.recipe_ingredients ri on ri.recipe_id = r.id and ri.role = 'core'
    join public.ingredients i on i.id = ri.ingredient_id and i.is_pantry = false
    where r.status = 'approved'
  ),
  scored as (
    select recipe_id, title, image_url, cook_time, diet, cuisine,
           count(*) filter (where ing_name = any (scanned))  as matched_count,
           count(*) filter (where ing_name <> all (scanned)) as missing_count,
           array_agg(ing_name) filter (where ing_name <> all (scanned)) as missing_names
    from core
    group by recipe_id, title, image_url, cook_time, diet, cuisine
  )
  select recipe_id, title, image_url, cook_time, diet, cuisine,
         matched_count, missing_count,
         coalesce(missing_names, '{}')
  from scored
  where matched_count > 0
  order by
    missing_count asc,      -- fewest missing first: cookable right now
    matched_count desc,     -- then most overlap with what you have
    title
  limit 60;
$$;
