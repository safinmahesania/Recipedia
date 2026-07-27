-- Round 2: three merges the earlier rules missed, then art for the long tail.
--
-- The plural detector in the duplicate report guarded on "singular has at least
-- as many uses as plural", which silently skipped any pair where the plural was
-- more common. It also could not handle irregular plurals. These three slipped
-- through and are still splitting matches in the scan RPC.

begin;

create temp table merge_pairs(keep_name text, dup_name text) on commit drop;
insert into merge_pairs values
  ('tomato','tomatoes'),      -- 119 / 139
  ('potato','potatoes'),      --  38 /  89
  ('bay leaf','bay leaves');  --  97 /  36, irregular plural

create temp table m on commit drop as
select k.id as keep_id, d.id as dup_id
from merge_pairs g
join public.ingredients k on lower(trim(k.name)) = g.keep_name
join public.ingredients d on lower(trim(d.name)) = g.dup_name
where k.id <> d.id;

with mapped as (
  select ri.ctid as tid, ri.recipe_id, ri.role,
         coalesce(m.keep_id, ri.ingredient_id) as final_id,
         (m.keep_id is not null) as is_moving
  from public.recipe_ingredients ri
  left join m on m.dup_id = ri.ingredient_id
),
ranked as (
  select tid, row_number() over (partition by recipe_id, final_id
                                 order by (role = 'core') desc, is_moving asc, tid) as rn
  from mapped
)
delete from public.recipe_ingredients ri using ranked r
 where ri.ctid = r.tid and r.rn > 1;

update public.recipe_ingredients ri set ingredient_id = m.keep_id
  from m where ri.ingredient_id = m.dup_id;

with mapped as (
  select ua.ctid as tid, ua.user_id,
         coalesce(m.keep_id, ua.ingredient_id) as final_id,
         (m.keep_id is not null) as is_moving
  from public.user_allergies ua left join m on m.dup_id = ua.ingredient_id
),
ranked as (select tid, row_number() over (partition by user_id, final_id
                                          order by is_moving asc, tid) as rn from mapped)
delete from public.user_allergies ua using ranked r where ua.ctid = r.tid and r.rn > 1;
update public.user_allergies ua set ingredient_id = m.keep_id
  from m where ua.ingredient_id = m.dup_id;

with mapped as (
  select up.ctid as tid, up.user_id,
         coalesce(m.keep_id, up.ingredient_id) as final_id,
         (m.keep_id is not null) as is_moving
  from public.user_pantry_staples up left join m on m.dup_id = up.ingredient_id
),
ranked as (select tid, row_number() over (partition by user_id, final_id
                                          order by is_moving asc, tid) as rn from mapped)
delete from public.user_pantry_staples up using ranked r where up.ctid = r.tid and r.rn > 1;
update public.user_pantry_staples up set ingredient_id = m.keep_id
  from m where up.ingredient_id = m.dup_id;

update public.shopping_list_items s set ingredient_id = m.keep_id
  from m where s.ingredient_id = m.dup_id;

delete from public.ingredients i using m where i.id = m.dup_id;

-- ---------------------------------------------------------------------------
-- Art for the long tail. Nothing here is a merge; these are real, distinct
-- ingredients that simply had no category or icon yet.
-- ---------------------------------------------------------------------------
with m2(name, category, icon_key) as (values
  ('basmati rice','grain','rice_basmati'),
  ('cooked rice','grain','rice'),
  ('poha','grain','poha'),
  ('oats','grain','oats'),
  ('quinoa','grain','quinoa'),
  ('vermicelli','grain','vermicelli'),
  ('bread','grain','bread'),
  ('sooji','grain','sooji'),
  ('all purpose flour','grain','flour'),
  ('rice flour','grain','flour_rice'),
  ('corn flour','grain','flour_corn'),
  ('besan','grain','besan'),
  ('pearl onions','vegetable','onion'),
  ('cauliflower','vegetable','cauliflower'),
  ('cabbage','vegetable','cabbage'),
  ('broccoli','vegetable','broccoli'),
  ('cucumber','vegetable','cucumber'),
  ('beetroot','vegetable','beetroot'),
  ('radish','vegetable','radish'),
  ('pumpkin','vegetable','pumpkin'),
  ('zucchini','vegetable','zucchini'),
  ('mushrooms','vegetable','mushroom'),
  ('drumstick','vegetable','drumstick'),
  ('bottle gourd','vegetable','gourd'),
  ('ridge gourd','vegetable','gourd'),
  ('ash gourd','vegetable','gourd'),
  ('colocasia','vegetable','colocasia'),
  ('yam','vegetable','yam'),
  ('sweet potato','vegetable','sweetpotato'),
  ('spring onion','vegetable','springonion'),
  ('peas','vegetable','peas'),
  ('sweet corn','vegetable','corn'),
  ('corn','vegetable','corn'),
  ('french beans','vegetable','beans'),
  ('raw banana','vegetable','banana_raw'),
  ('tomato paste','vegetable','tomato'),
  ('apple','fruit','apple'),
  ('banana','fruit','banana'),
  ('orange','fruit','orange'),
  ('pineapple','fruit','pineapple'),
  ('papaya','fruit','papaya'),
  ('grapes','fruit','grapes'),
  ('pomegranate','fruit','pomegranate'),
  ('dates','fruit','dates'),
  ('raisins','fruit','raisin'),
  ('lime','fruit','lime'),
  ('lime juice','fruit','lime'),
  ('tamarind pulp','fruit','tamarind'),
  ('butter','dairy','butter'),
  ('cheese','dairy','cheese'),
  ('buttermilk','dairy','buttermilk'),
  ('khoya','dairy','khoya'),
  ('tofu','dairy','tofu'),
  ('sesame seeds','spice','seeds_sesame'),
  ('star anise','spice','staranise'),
  ('black cardamom','spice','cardamom_black'),
  ('mace','spice','mace'),
  ('nutmeg','spice','nutmeg'),
  ('vanilla','spice','vanilla'),
  ('black salt','spice','salt_black'),
  ('sambar powder','spice','powder_sambar'),
  ('rasam powder','spice','powder_rasam'),
  ('chaat masala','spice','powder_chaat'),
  ('pav bhaji masala','spice','powder_pavbhaji'),
  ('garlic paste','spice','paste_garlic'),
  ('ginger paste','spice','paste_ginger'),
  ('green chilli paste','spice','paste_chilli'),
  ('masoor dal','legume','dal_masoor'),
  ('rajma','legume','rajma'),
  ('kabuli chana','legume','chickpea'),
  ('sprouts','legume','sprouts'),
  ('almonds','nut','almond'),
  ('pistachios','nut','pistachio'),
  ('walnuts','nut','walnut'),
  ('olive oil','oil','oil_olive'),
  ('sunflower oil','oil','oil_sunflower'),
  ('vegetable oil','oil','oil'),
  ('mutton','meat','mutton'),
  ('prawns','seafood','prawn'),
  ('egg','other','egg'),
  ('honey','sweetener','honey'),
  ('vinegar','liquid','vinegar'),
  ('soy sauce','liquid','soysauce'),
  ('baking soda','other','bakingsoda')
)
update public.ingredients i
   set category = m2.category,
       icon_key = m2.icon_key
  from m2
 where lower(trim(i.name)) = m2.name;

commit;

-- Verify:
--   select count(*) from public.ingredients;                          -- ~157
--   select count(*) from public.ingredients where icon_key is null;   -- the remainder
--   select name from public.ingredients where icon_key is null order by 1;
