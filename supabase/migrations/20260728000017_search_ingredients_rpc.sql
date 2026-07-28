-- Ranked ingredient search.
--
-- The old query was a bare `ilike '%term%'` with no ordering, so typing "on"
-- could put "spring onion" above "onion", and typing a regional name returned
-- nothing at all. Ranking matters more than matching here: the first result is
-- the one people tap.
--
-- Order of preference:
--   1  exact name          "onion"        -> onion
--   2  name starts with    "oni"          -> onion
--   3  alias exact/prefix  "pyaz"         -> onion
--   4  name contains       "nio"          -> onion
--   5  alias contains
-- then by how often the ingredient is actually used, so common things win ties.

create or replace function public.search_ingredients(
  term text,
  max_results int default 10
)
returns table (
  id uuid,
  name text,
  icon_key text,
  category text,
  matched_alias text,
  is_pantry boolean
)
language sql
stable
as $$
  with q as (select lower(trim(term)) as t),
  usage as (
    select ingredient_id, count(*)::int as uses
    from public.recipe_ingredients
    group by ingredient_id
  ),
  scored as (
    select
      i.id,
      i.name,
      i.icon_key,
      i.category,
      i.is_pantry,
      -- the alias responsible for the match, so the UI can explain itself
      (select a from unnest(i.aliases) a, q
        where a = q.t or a like q.t || '%' or a like '%' || q.t || '%'
        order by (a = q.t) desc, (a like q.t || '%') desc, length(a)
        limit 1) as matched_alias,
      case
        when lower(i.name) = (select t from q) then 1
        when lower(i.name) like (select t from q) || '%' then 2
        when exists (select 1 from unnest(i.aliases) a, q
                     where a = q.t or a like q.t || '%') then 3
        when lower(i.name) like '%' || (select t from q) || '%' then 4
        when exists (select 1 from unnest(i.aliases) a, q
                     where a like '%' || q.t || '%') then 5
        else 99
      end as rank,
      coalesce(u.uses, 0) as uses
    from public.ingredients i
    left join usage u on u.ingredient_id = i.id
  )
  select id, name, icon_key, category, matched_alias, is_pantry
  from scored
  where rank < 99
    and (select length(t) from q) >= 2
  order by rank, uses desc, length(name), name
  limit max_results;
$$;

grant execute on function public.search_ingredients(text, int) to anon, authenticated;
