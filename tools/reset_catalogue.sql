-- Removes the imported recipe catalogue and everything hanging off it.
--
-- READ THIS BEFORE RUNNING.
--
-- Deletes:  recipes, and by cascade recipe_ingredients, favorites, reviews,
--           cooked_history, meal_plan_entries, and shopping list rows that
--           reference a recipe.
--
-- Keeps:    ingredients. That table is 157 canonical rows carrying icon_key,
--           category and 103 aliases, built over five migrations. Ingredient
--           names are facts — "onion" is not authored content — so none of
--           that work is affected by the provenance problem, and throwing it
--           away would mean redoing all of it.
--
-- Keeps:    profiles, collections, user_allergies, user_pantry_staples.
--           Staples reference ingredients, not recipes.
--
-- Take a backup first. The nightly workflow makes one, but run it manually
-- before this rather than trusting last night's:
--   Actions -> Database backup -> Run workflow

begin;

-- Detach shopping list rows instead of deleting them: a user's list is their
-- own data and should survive a catalogue swap, even if the recipe that
-- suggested an item is gone.
update public.shopping_list_items set recipe_id = null where recipe_id is not null;

delete from public.recipes;

-- Report what survived, so the outcome is visible rather than assumed.
select 'recipes'            as table_name, count(*) from public.recipes
union all select 'recipe_ingredients', count(*) from public.recipe_ingredients
union all select 'ingredients',        count(*) from public.ingredients
union all select 'ingredients w/ icon',count(*) from public.ingredients where icon_key is not null
union all select 'ingredients w/ alias',count(*) from public.ingredients where cardinality(aliases) > 0
union all select 'profiles',           count(*) from public.profiles
union all select 'shopping items',     count(*) from public.shopping_list_items;

commit;
