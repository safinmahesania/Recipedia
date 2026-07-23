-- Distinct filter values, computed in the database.
-- Pulling 1000+ rows just to derive a dropdown list is wasteful; these return
-- only the values, already sorted and de-duplicated.

create or replace function public.distinct_cuisines()
returns table (value text, recipe_count bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select cuisine as value, count(*) as recipe_count
  from public.recipes
  where status = 'approved' and cuisine is not null and btrim(cuisine) <> ''
  group by cuisine
  order by count(*) desc, cuisine;
$$;

create or replace function public.distinct_diets()
returns table (value text, recipe_count bigint)
language sql
stable
security invoker
set search_path = public
as $$
  select diet as value, count(*) as recipe_count
  from public.recipes
  where status = 'approved' and diet is not null and btrim(diet) <> ''
  group by diet
  order by count(*) desc, diet;
$$;

-- supports the combined category + cuisine + diet filter
create index if not exists recipes_filter_idx
  on public.recipes(status, category_id, cuisine, diet);
