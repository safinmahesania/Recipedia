-- ===========================================================================
-- READ-ONLY. Run this first. It changes nothing.
--
-- The frequency list shows singular and plural stored as separate ingredients:
--   onion 294 / onions 81 · tomatoes 139 / tomato 119 · potatoes 89 / potato 38
--   carrot 38 / carrots 38 · bay leaf 97 / bay leaves 36
--
-- This is not cosmetic. match_recipes_by_ingredients compares lower(i.name)
-- against the scanned array, so a user who scans "onion" gets no credit for a
-- recipe that stored "onions". Every duplicate pair is silently costing you
-- matches on the feature the whole app is built around.
-- ===========================================================================

-- 1. Candidate duplicate pairs (naive plural rule).
select a.id as keep_id, a.name as keep_name, ca.uses as keep_uses,
       b.id as drop_id, b.name as drop_name, cb.uses as drop_uses
from public.ingredients a
join public.ingredients b
  on b.id <> a.id
 and lower(trim(b.name)) in (lower(trim(a.name)) || 's',
                             lower(trim(a.name)) || 'es')
left join (select ingredient_id, count(*) uses from public.recipe_ingredients group by 1) ca
       on ca.ingredient_id = a.id
left join (select ingredient_id, count(*) uses from public.recipe_ingredients group by 1) cb
       on cb.ingredient_id = b.id
order by coalesce(cb.uses,0) desc;

-- 2. Near-duplicates the plural rule will miss — review by eye.
--    e.g. "fresh coconut" vs "coconut", "coriander leaves" vs "coriander".
select name, count(*) over () as total
from public.ingredients
where lower(name) similar to '%(chilli|chili|coconut|coriander|methi|pepper|dal)%'
order by name;
