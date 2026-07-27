-- What do the last three actually look like in real recipes?
-- One statement, so the editor shows all of it.
select i.name        as ingredient,
       r.title       as recipe,
       ri.role,
       ri.quantity
from public.ingredients i
join public.recipe_ingredients ri on ri.ingredient_id = i.id
join public.recipes r             on r.id = ri.recipe_id
where lower(trim(i.name)) in ('chana','dal','methi')
order by i.name, r.title;
