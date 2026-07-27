-- The 117 ingredients with no specific art yet, most-used first.
-- This is the list that decides what gets drawn next.
select i.name, i.category, count(ri.recipe_id) as uses
from public.ingredients i
left join public.recipe_ingredients ri on ri.ingredient_id = i.id
where i.icon_key is null
group by i.name, i.category
order by uses desc, i.name;
