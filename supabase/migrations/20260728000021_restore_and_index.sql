-- Restores the curated ingredients that migration 020 deleted, and closes the
-- gaps the full audit found.
--
-- WHAT WENT WRONG
--
-- Migration 020 deleted ingredients no recipe referenced. At the time that
-- looked like tidying. It was not: reset_catalogue.sql had just removed the
-- Indian recipes, so every Indian ingredient became unreferenced and was
-- deleted with them — masoor dal, sambar powder, kasuri methi, bhindi,
-- brinjal, arhar dal, and 48 more, each carrying an icon_key, a category and
-- aliases built up over five migrations.
--
-- Ingredients are a REFERENCE table, not derived data. They cost nothing to
-- keep, and they are the vocabulary that every future import and every user
-- submission is matched against. An unused ingredient is not waste; it is a
-- word the app knows.
--
-- The cleanup in 020 was wrong and is not repeated here.

begin;

-- ===========================================================================
-- 1. Restore every ingredient the migrations declare
-- ===========================================================================

with declared(name, category, icon_key) as (values
  ('ajwain', 'spice', 'seeds_ajwain'),
  ('all purpose flour', 'grain', 'flour'),
  ('almonds', 'nut', 'almond'),
  ('amchur', 'spice', 'powder_amchur'),
  ('apple', 'fruit', 'apple'),
  ('arhar dal', 'legume', 'dal_arhar'),
  ('asafoetida', 'spice', 'powder_hing'),
  ('ash gourd', 'vegetable', 'gourd'),
  ('baking soda', 'other', 'bakingsoda'),
  ('banana', 'fruit', 'banana'),
  ('basmati rice', 'grain', 'rice_basmati'),
  ('bay leaf', 'spice', 'bayleaf'),
  ('bay leaves', 'spice', 'bayleaf'),
  ('beans', 'vegetable', 'beans'),
  ('beetroot', 'vegetable', 'beetroot'),
  ('bell pepper', 'vegetable', 'bellpepper'),
  ('besan', 'grain', 'besan'),
  ('bhindi', 'vegetable', 'okra'),
  ('black cardamom', 'spice', 'cardamom_black'),
  ('black pepper powder', 'spice', 'powder_pepper'),
  ('black peppercorns', 'spice', 'seeds_pepper'),
  ('black salt', 'spice', 'salt_black'),
  ('bottle gourd', 'vegetable', 'gourd'),
  ('bread', 'grain', 'bread'),
  ('brinjal', 'vegetable', 'brinjal'),
  ('broccoli', 'vegetable', 'broccoli'),
  ('butter', 'dairy', 'butter'),
  ('buttermilk', 'dairy', 'buttermilk'),
  ('cabbage', 'vegetable', 'cabbage'),
  ('cardamom', 'spice', 'cardamom'),
  ('carrot', 'vegetable', 'carrot'),
  ('carrots', 'vegetable', 'carrot'),
  ('cashew nuts', 'nut', 'cashew'),
  ('cauliflower', 'vegetable', 'cauliflower'),
  ('chaat masala', 'spice', 'powder_chaat'),
  ('chana dal', 'legume', 'dal_chana'),
  ('cheese', 'dairy', 'cheese'),
  ('chicken', 'meat', 'chicken'),
  ('cinnamon stick', 'spice', 'cinnamon'),
  ('coconut', 'fruit', 'coconut'),
  ('coconut milk', 'dairy', 'coconut_milk'),
  ('coconut oil', 'oil', 'oil_coconut'),
  ('colocasia', 'vegetable', 'colocasia'),
  ('cooked rice', 'grain', 'rice'),
  ('coriander', 'leafy', 'leaves_coriander'),
  ('coriander leaves', 'leafy', 'leaves_coriander'),
  ('coriander powder', 'spice', 'powder_coriander'),
  ('coriander seeds', 'spice', 'seeds_coriander'),
  ('corn', 'vegetable', 'corn'),
  ('corn flour', 'grain', 'flour_corn'),
  ('cucumber', 'vegetable', 'cucumber'),
  ('cumin powder', 'spice', 'powder_cumin'),
  ('cumin seeds', 'spice', 'seeds_cumin'),
  ('curd', 'dairy', 'curd'),
  ('curry leaves', 'leafy', 'leaves_curry'),
  ('dates', 'fruit', 'dates'),
  ('drumstick', 'vegetable', 'drumstick'),
  ('dry red chilli', 'spice', 'chilli_red'),
  ('egg', 'other', 'egg'),
  ('fennel seeds', 'spice', 'seeds_fennel'),
  ('fish', 'seafood', 'fish'),
  ('french beans', 'vegetable', 'beans'),
  ('fresh coconut', 'fruit', 'coconut'),
  ('fresh cream', 'dairy', 'cream'),
  ('garam masala', 'spice', 'powder_garam'),
  ('garlic', 'vegetable', 'garlic'),
  ('garlic paste', 'spice', 'paste_garlic'),
  ('ghee', 'dairy', 'ghee'),
  ('ginger', 'vegetable', 'ginger'),
  ('ginger garlic paste', 'spice', 'paste_gg'),
  ('ginger paste', 'spice', 'paste_ginger'),
  ('grapes', 'fruit', 'grapes'),
  ('green chilli', 'vegetable', 'chilli_green'),
  ('green chilli paste', 'spice', 'paste_chilli'),
  ('green chillies', 'vegetable', 'chilli_green'),
  ('green peas', 'vegetable', 'peas'),
  ('honey', 'sweetener', 'honey'),
  ('jaggery', 'sweetener', 'jaggery'),
  ('kabuli chana', 'legume', 'chickpea'),
  ('kashmiri red chilli powder', 'spice', 'powder_chilli'),
  ('kasuri methi', 'leafy', 'leaves_methi'),
  ('khoya', 'dairy', 'khoya'),
  ('lemon', 'fruit', 'lemon'),
  ('lemon juice', 'fruit', 'lemon'),
  ('lime', 'fruit', 'lime'),
  ('lime juice', 'fruit', 'lime'),
  ('mace', 'spice', 'mace'),
  ('mango', 'fruit', 'mango'),
  ('masoor dal', 'legume', 'dal_masoor'),
  ('methi leaves', 'leafy', 'leaves_methi'),
  ('methi seeds', 'spice', 'seeds_methi'),
  ('milk', 'dairy', 'milk'),
  ('mint leaves', 'leafy', 'leaves_mint'),
  ('moong dal', 'legume', 'dal_moong'),
  ('mushrooms', 'vegetable', 'mushroom'),
  ('mustard oil', 'oil', 'oil_mustard'),
  ('mustard seeds', 'spice', 'seeds_mustard'),
  ('mutton', 'meat', 'mutton'),
  ('nutmeg', 'spice', 'nutmeg'),
  ('oats', 'grain', 'oats'),
  ('oil', 'oil', 'oil'),
  ('olive oil', 'oil', 'oil_olive'),
  ('onion', 'vegetable', 'onion'),
  ('onions', 'vegetable', 'onion'),
  ('orange', 'fruit', 'orange'),
  ('paneer', 'dairy', 'paneer'),
  ('papaya', 'fruit', 'papaya'),
  ('pav bhaji masala', 'spice', 'powder_pavbhaji'),
  ('peanuts', 'nut', 'peanut'),
  ('pearl onions', 'vegetable', 'onion'),
  ('peas', 'vegetable', 'peas'),
  ('pineapple', 'fruit', 'pineapple'),
  ('pistachios', 'nut', 'pistachio'),
  ('poha', 'grain', 'poha'),
  ('pomegranate', 'fruit', 'pomegranate'),
  ('poppy seeds', 'spice', 'seeds_poppy'),
  ('potato', 'vegetable', 'potato'),
  ('potatoes', 'vegetable', 'potato'),
  ('prawns', 'seafood', 'prawn'),
  ('pumpkin', 'vegetable', 'pumpkin'),
  ('quinoa', 'grain', 'quinoa'),
  ('radish', 'vegetable', 'radish'),
  ('raisins', 'fruit', 'raisin'),
  ('rajma', 'legume', 'rajma'),
  ('rasam powder', 'spice', 'powder_rasam'),
  ('raw banana', 'vegetable', 'banana_raw'),
  ('red chilli', 'spice', 'chilli_red'),
  ('red chilli powder', 'spice', 'powder_chilli'),
  ('red chillies', 'spice', 'chilli_red'),
  ('rice', 'grain', 'rice'),
  ('rice flour', 'grain', 'flour_rice'),
  ('ridge gourd', 'vegetable', 'gourd'),
  ('salt', 'spice', 'salt'),
  ('sambar powder', 'spice', 'powder_sambar'),
  ('sesame oil', 'oil', 'oil_sesame'),
  ('sesame seeds', 'spice', 'seeds_sesame'),
  ('sooji', 'grain', 'sooji'),
  ('soy sauce', 'liquid', 'soysauce'),
  ('spinach', 'leafy', 'spinach'),
  ('spring onion', 'vegetable', 'springonion'),
  ('sprouts', 'legume', 'sprouts'),
  ('star anise', 'spice', 'staranise'),
  ('sugar', 'sweetener', 'sugar'),
  ('sunflower oil', 'oil', 'oil_sunflower'),
  ('sweet corn', 'vegetable', 'corn'),
  ('sweet potato', 'vegetable', 'sweetpotato'),
  ('tamarind', 'fruit', 'tamarind'),
  ('tamarind pulp', 'fruit', 'tamarind'),
  ('tofu', 'dairy', 'tofu'),
  ('tomato', 'vegetable', 'tomato'),
  ('tomato paste', 'vegetable', 'tomato'),
  ('tomato puree', 'vegetable', 'tomato'),
  ('tomatoes', 'vegetable', 'tomato'),
  ('turmeric powder', 'spice', 'powder_turmeric'),
  ('urad dal', 'legume', 'dal_urad'),
  ('vanilla', 'spice', 'vanilla'),
  ('vegetable oil', 'oil', 'oil'),
  ('vermicelli', 'grain', 'vermicelli'),
  ('vinegar', 'liquid', 'vinegar'),
  ('walnuts', 'nut', 'walnut'),
  ('water', 'liquid', 'water'),
  ('whole wheat flour', 'grain', 'flour'),
  ('yam', 'vegetable', 'yam'),
  ('zucchini', 'vegetable', 'zucchini')
)
insert into public.ingredients (name, category, icon_key, is_pantry)
select d.name, d.category, d.icon_key, false
from declared d
where not exists (
  select 1 from public.ingredients i where lower(btrim(i.name)) = d.name)
on conflict do nothing;

-- Repair any that survived but lost their icon or category.
with declared(name, category, icon_key) as (values
  ('ajwain', 'spice', 'seeds_ajwain'),
  ('all purpose flour', 'grain', 'flour'),
  ('almonds', 'nut', 'almond'),
  ('amchur', 'spice', 'powder_amchur'),
  ('apple', 'fruit', 'apple'),
  ('arhar dal', 'legume', 'dal_arhar'),
  ('asafoetida', 'spice', 'powder_hing'),
  ('ash gourd', 'vegetable', 'gourd'),
  ('baking soda', 'other', 'bakingsoda'),
  ('banana', 'fruit', 'banana'),
  ('basmati rice', 'grain', 'rice_basmati'),
  ('bay leaf', 'spice', 'bayleaf'),
  ('bay leaves', 'spice', 'bayleaf'),
  ('beans', 'vegetable', 'beans'),
  ('beetroot', 'vegetable', 'beetroot'),
  ('bell pepper', 'vegetable', 'bellpepper'),
  ('besan', 'grain', 'besan'),
  ('bhindi', 'vegetable', 'okra'),
  ('black cardamom', 'spice', 'cardamom_black'),
  ('black pepper powder', 'spice', 'powder_pepper'),
  ('black peppercorns', 'spice', 'seeds_pepper'),
  ('black salt', 'spice', 'salt_black'),
  ('bottle gourd', 'vegetable', 'gourd'),
  ('bread', 'grain', 'bread'),
  ('brinjal', 'vegetable', 'brinjal'),
  ('broccoli', 'vegetable', 'broccoli'),
  ('butter', 'dairy', 'butter'),
  ('buttermilk', 'dairy', 'buttermilk'),
  ('cabbage', 'vegetable', 'cabbage'),
  ('cardamom', 'spice', 'cardamom'),
  ('carrot', 'vegetable', 'carrot'),
  ('carrots', 'vegetable', 'carrot'),
  ('cashew nuts', 'nut', 'cashew'),
  ('cauliflower', 'vegetable', 'cauliflower'),
  ('chaat masala', 'spice', 'powder_chaat'),
  ('chana dal', 'legume', 'dal_chana'),
  ('cheese', 'dairy', 'cheese'),
  ('chicken', 'meat', 'chicken'),
  ('cinnamon stick', 'spice', 'cinnamon'),
  ('coconut', 'fruit', 'coconut'),
  ('coconut milk', 'dairy', 'coconut_milk'),
  ('coconut oil', 'oil', 'oil_coconut'),
  ('colocasia', 'vegetable', 'colocasia'),
  ('cooked rice', 'grain', 'rice'),
  ('coriander', 'leafy', 'leaves_coriander'),
  ('coriander leaves', 'leafy', 'leaves_coriander'),
  ('coriander powder', 'spice', 'powder_coriander'),
  ('coriander seeds', 'spice', 'seeds_coriander'),
  ('corn', 'vegetable', 'corn'),
  ('corn flour', 'grain', 'flour_corn'),
  ('cucumber', 'vegetable', 'cucumber'),
  ('cumin powder', 'spice', 'powder_cumin'),
  ('cumin seeds', 'spice', 'seeds_cumin'),
  ('curd', 'dairy', 'curd'),
  ('curry leaves', 'leafy', 'leaves_curry'),
  ('dates', 'fruit', 'dates'),
  ('drumstick', 'vegetable', 'drumstick'),
  ('dry red chilli', 'spice', 'chilli_red'),
  ('egg', 'other', 'egg'),
  ('fennel seeds', 'spice', 'seeds_fennel'),
  ('fish', 'seafood', 'fish'),
  ('french beans', 'vegetable', 'beans'),
  ('fresh coconut', 'fruit', 'coconut'),
  ('fresh cream', 'dairy', 'cream'),
  ('garam masala', 'spice', 'powder_garam'),
  ('garlic', 'vegetable', 'garlic'),
  ('garlic paste', 'spice', 'paste_garlic'),
  ('ghee', 'dairy', 'ghee'),
  ('ginger', 'vegetable', 'ginger'),
  ('ginger garlic paste', 'spice', 'paste_gg'),
  ('ginger paste', 'spice', 'paste_ginger'),
  ('grapes', 'fruit', 'grapes'),
  ('green chilli', 'vegetable', 'chilli_green'),
  ('green chilli paste', 'spice', 'paste_chilli'),
  ('green chillies', 'vegetable', 'chilli_green'),
  ('green peas', 'vegetable', 'peas'),
  ('honey', 'sweetener', 'honey'),
  ('jaggery', 'sweetener', 'jaggery'),
  ('kabuli chana', 'legume', 'chickpea'),
  ('kashmiri red chilli powder', 'spice', 'powder_chilli'),
  ('kasuri methi', 'leafy', 'leaves_methi'),
  ('khoya', 'dairy', 'khoya'),
  ('lemon', 'fruit', 'lemon'),
  ('lemon juice', 'fruit', 'lemon'),
  ('lime', 'fruit', 'lime'),
  ('lime juice', 'fruit', 'lime'),
  ('mace', 'spice', 'mace'),
  ('mango', 'fruit', 'mango'),
  ('masoor dal', 'legume', 'dal_masoor'),
  ('methi leaves', 'leafy', 'leaves_methi'),
  ('methi seeds', 'spice', 'seeds_methi'),
  ('milk', 'dairy', 'milk'),
  ('mint leaves', 'leafy', 'leaves_mint'),
  ('moong dal', 'legume', 'dal_moong'),
  ('mushrooms', 'vegetable', 'mushroom'),
  ('mustard oil', 'oil', 'oil_mustard'),
  ('mustard seeds', 'spice', 'seeds_mustard'),
  ('mutton', 'meat', 'mutton'),
  ('nutmeg', 'spice', 'nutmeg'),
  ('oats', 'grain', 'oats'),
  ('oil', 'oil', 'oil'),
  ('olive oil', 'oil', 'oil_olive'),
  ('onion', 'vegetable', 'onion'),
  ('onions', 'vegetable', 'onion'),
  ('orange', 'fruit', 'orange'),
  ('paneer', 'dairy', 'paneer'),
  ('papaya', 'fruit', 'papaya'),
  ('pav bhaji masala', 'spice', 'powder_pavbhaji'),
  ('peanuts', 'nut', 'peanut'),
  ('pearl onions', 'vegetable', 'onion'),
  ('peas', 'vegetable', 'peas'),
  ('pineapple', 'fruit', 'pineapple'),
  ('pistachios', 'nut', 'pistachio'),
  ('poha', 'grain', 'poha'),
  ('pomegranate', 'fruit', 'pomegranate'),
  ('poppy seeds', 'spice', 'seeds_poppy'),
  ('potato', 'vegetable', 'potato'),
  ('potatoes', 'vegetable', 'potato'),
  ('prawns', 'seafood', 'prawn'),
  ('pumpkin', 'vegetable', 'pumpkin'),
  ('quinoa', 'grain', 'quinoa'),
  ('radish', 'vegetable', 'radish'),
  ('raisins', 'fruit', 'raisin'),
  ('rajma', 'legume', 'rajma'),
  ('rasam powder', 'spice', 'powder_rasam'),
  ('raw banana', 'vegetable', 'banana_raw'),
  ('red chilli', 'spice', 'chilli_red'),
  ('red chilli powder', 'spice', 'powder_chilli'),
  ('red chillies', 'spice', 'chilli_red'),
  ('rice', 'grain', 'rice'),
  ('rice flour', 'grain', 'flour_rice'),
  ('ridge gourd', 'vegetable', 'gourd'),
  ('salt', 'spice', 'salt'),
  ('sambar powder', 'spice', 'powder_sambar'),
  ('sesame oil', 'oil', 'oil_sesame'),
  ('sesame seeds', 'spice', 'seeds_sesame'),
  ('sooji', 'grain', 'sooji'),
  ('soy sauce', 'liquid', 'soysauce'),
  ('spinach', 'leafy', 'spinach'),
  ('spring onion', 'vegetable', 'springonion'),
  ('sprouts', 'legume', 'sprouts'),
  ('star anise', 'spice', 'staranise'),
  ('sugar', 'sweetener', 'sugar'),
  ('sunflower oil', 'oil', 'oil_sunflower'),
  ('sweet corn', 'vegetable', 'corn'),
  ('sweet potato', 'vegetable', 'sweetpotato'),
  ('tamarind', 'fruit', 'tamarind'),
  ('tamarind pulp', 'fruit', 'tamarind'),
  ('tofu', 'dairy', 'tofu'),
  ('tomato', 'vegetable', 'tomato'),
  ('tomato paste', 'vegetable', 'tomato'),
  ('tomato puree', 'vegetable', 'tomato'),
  ('tomatoes', 'vegetable', 'tomato'),
  ('turmeric powder', 'spice', 'powder_turmeric'),
  ('urad dal', 'legume', 'dal_urad'),
  ('vanilla', 'spice', 'vanilla'),
  ('vegetable oil', 'oil', 'oil'),
  ('vermicelli', 'grain', 'vermicelli'),
  ('vinegar', 'liquid', 'vinegar'),
  ('walnuts', 'nut', 'walnut'),
  ('water', 'liquid', 'water'),
  ('whole wheat flour', 'grain', 'flour'),
  ('yam', 'vegetable', 'yam'),
  ('zucchini', 'vegetable', 'zucchini')
)
update public.ingredients i
set icon_key = coalesce(i.icon_key, d.icon_key),
    category = coalesce(i.category, d.category)
from declared d
where lower(btrim(i.name)) = d.name
  and (i.icon_key is null or i.category is null);

-- ===========================================================================
-- 2. An alias claimed by two ingredients
--
-- 'matar' sat on both 'green peas' and 'peas', so search resolved to whichever
-- row sorted first. Migration 020 only stripped aliases that shadowed a real
-- name; it did not catch one alias shared across two rows.
--
-- Keep it on the row more recipes actually use; an alias should point at the
-- ingredient people will most often mean.
-- ===========================================================================

with usage as (
  select i.id, i.name, count(ri.id) as uses
  from public.ingredients i
  left join public.recipe_ingredients ri on ri.ingredient_id = i.id
  where 'matar' = any(i.aliases)
  group by i.id, i.name
),
loser as (
  select id from usage order by uses asc, name asc offset 1
)
update public.ingredients i
set aliases = array_remove(i.aliases, 'matar')
where i.id in (select id from loser);

-- Generalise it: no alias may appear on more than one ingredient.
with shared as (
  select a as alias from (
    select unnest(aliases) as a from public.ingredients) x
  group by a having count(*) > 1
),
ranked as (
  select i.id, s.alias,
         row_number() over (
           partition by s.alias
           order by (select count(*) from public.recipe_ingredients ri
                     where ri.ingredient_id = i.id) desc, i.name) as rn
  from public.ingredients i
  join shared s on s.alias = any(i.aliases)
)
update public.ingredients i
set aliases = array_remove(i.aliases, r.alias)
from ranked r
where r.id = i.id and r.rn > 1;

-- ===========================================================================
-- 3. Foreign keys with no index
--
-- Nine of them. Every parent delete and every join scans the child table.
-- Harmless at 1164 recipes, quietly bad at 50,000 — and deleting a user
-- currently scans five tables.
-- ===========================================================================

create index if not exists user_allergies_ingredient_idx
  on public.user_allergies(ingredient_id);
create index if not exists user_staples_ingredient_idx
  on public.user_pantry_staples(ingredient_id);
create index if not exists cooked_history_recipe_idx
  on public.cooked_history(recipe_id);
create index if not exists recipes_author_idx
  on public.recipes(author_id);
create index if not exists meal_plan_recipe_idx
  on public.meal_plan_entries(recipe_id);
create index if not exists shopping_items_recipe_idx
  on public.shopping_list_items(recipe_id);
create index if not exists favorites_recipe_idx
  on public.favorites(recipe_id);
create index if not exists reports_reporter_idx
  on public.reports(reporter_id);
create index if not exists reviews_recipe_idx
  on public.reviews(recipe_id);

commit;

select 'ingredients' as metric, count(*)::text as value from public.ingredients
union all select 'with icon_key', count(*)::text from public.ingredients where icon_key is not null
union all select 'with category', count(*)::text from public.ingredients where category is not null
union all select 'shared aliases remaining', count(*)::text from (
  select a from (select unnest(aliases) a from public.ingredients) x
  group by a having count(*) > 1) t;
