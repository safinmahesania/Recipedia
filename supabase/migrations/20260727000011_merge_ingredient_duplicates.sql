-- Merge duplicate ingredients and remove junk rows.
--
-- WHY THIS MATTERS MORE THAN IT LOOKS
-- match_recipes_by_ingredients compares lower(i.name) against the scanned
-- array. "green chilli" and "green chillies" are separate rows, so a user who
-- scans one gets zero credit for recipes that stored the other. Roughly 1,900
-- ingredient uses are currently split across duplicate rows.
--
-- SAFETY
-- Everything runs in one transaction. Rows are RE-POINTED before anything is
-- deleted — recipe_ingredients, user_allergies, user_pantry_staples and
-- shopping_list_items all reference ingredients.id, and several of those
-- cascade on delete. Deleting first would silently destroy user data.

begin;

create temp table merge_pairs(keep_name text, dup_name text) on commit drop;
insert into merge_pairs values
  -- confirmed by the duplicate report
  ('green chilli','green chillies'),
  ('onion','onions'),
  ('red chilli powder','chilli powder'),
  ('coriander leaves','coriander'),
  ('coconut','fresh coconut'),
  ('red chilli','red chillies'),
  ('red chilli','dry red chilli'),
  ('black peppercorns','pepper'),
  ('black peppercorns','peppercorns'),
  ('carrot','carrots'),
  ('black pepper powder','black pepper'),
  ('arhar dal','toor dal'),
  ('kashmiri red chilli powder','kashmiri red chilli'),
  -- found in the uncategorised list, same ingredient under another name
  ('turmeric powder','turmeric'),
  ('cinnamon stick','cinnamon'),
  ('mint leaves','mint'),
  ('methi leaves','fenugreek leaves'),
  ('methi seeds','fenugreek seeds'),
  ('asafoetida','hing'),
  ('amchur','dry mango powder'),
  ('curd','yogurt'),
  ('potato','aloo'),
  ('brinjal','eggplant'),
  ('bhindi','okra'),
  ('bell pepper','capsicum'),
  ('whole wheat flour','atta'),
  ('whole wheat flour','wheat flour'),
  ('all purpose flour','maida'),
  ('sooji','rava'),
  ('sooji','semolina'),
  ('kabuli chana','chickpeas'),
  ('cauliflower','cauliflower florets'),
  ('egg','eggs');

create temp table m on commit drop as
select k.id as keep_id, d.id as dup_id
from merge_pairs g
join public.ingredients k on lower(trim(k.name)) = g.keep_name
join public.ingredients d on lower(trim(d.name)) = g.dup_name
where k.id <> d.id;

-- 1. collapse rows that would collide AFTER the merge --------------------
-- The naive approach ("delete dups where the keeper already exists") is not
-- enough: several duplicates map to the SAME keeper, so two duplicates inside
-- one recipe collide with each other, not with an existing keeper row.
-- red chillies + dry red chilli -> red chilli is the case that broke this.
-- So resolve every row to its FINAL ingredient id first, then keep exactly one
-- row per (recipe, final ingredient), preferring a 'core' row over 'optional'.
with mapped as (
  select ri.ctid as tid, ri.recipe_id, ri.role,
         coalesce(m.keep_id, ri.ingredient_id) as final_id,
         (m.keep_id is not null) as is_moving
  from public.recipe_ingredients ri
  left join m on m.dup_id = ri.ingredient_id
),
ranked as (
  select tid,
         row_number() over (partition by recipe_id, final_id
                            order by (role = 'core') desc, is_moving asc, tid) as rn
  from mapped
)
delete from public.recipe_ingredients ri
using ranked r
where ri.ctid = r.tid and r.rn > 1;

update public.recipe_ingredients ri
   set ingredient_id = m.keep_id
  from m where ri.ingredient_id = m.dup_id;

-- 2. user-owned references ---------------------------------------------
-- Same collision rule applies: two allergies mapping to one keeper.
with mapped as (
  select ua.ctid as tid, ua.user_id,
         coalesce(m.keep_id, ua.ingredient_id) as final_id,
         (m.keep_id is not null) as is_moving
  from public.user_allergies ua
  left join m on m.dup_id = ua.ingredient_id
),
ranked as (
  select tid, row_number() over (partition by user_id, final_id
                                 order by is_moving asc, tid) as rn
  from mapped
)
delete from public.user_allergies ua using ranked r
 where ua.ctid = r.tid and r.rn > 1;

update public.user_allergies ua set ingredient_id = m.keep_id
  from m where ua.ingredient_id = m.dup_id;

with mapped as (
  select up.ctid as tid, up.user_id,
         coalesce(m.keep_id, up.ingredient_id) as final_id,
         (m.keep_id is not null) as is_moving
  from public.user_pantry_staples up
  left join m on m.dup_id = up.ingredient_id
),
ranked as (
  select tid, row_number() over (partition by user_id, final_id
                                 order by is_moving asc, tid) as rn
  from mapped
)
delete from public.user_pantry_staples up using ranked r
 where up.ctid = r.tid and r.rn > 1;

update public.user_pantry_staples up set ingredient_id = m.keep_id
  from m where up.ingredient_id = m.dup_id;

-- no uniqueness here, so a plain re-point is safe
update public.shopping_list_items s set ingredient_id = m.keep_id
  from m where s.ingredient_id = m.dup_id;

-- 3. duplicates are now unreferenced ---------------------------------
delete from public.ingredients i using m where i.id = m.dup_id;

-- 4. junk rows -----------------------------------------------------------
-- "seat", "tyre", "kuch", "nhi" are not ingredients. They have zero uses and
-- would surface in the scan autocomplete. Guarded on 0 uses so nothing real
-- can be caught by this.
delete from public.ingredients i
 where lower(trim(i.name)) in ('seat','tyre','kuch','nhi')
   and not exists (select 1 from public.recipe_ingredients ri where ri.ingredient_id = i.id);

commit;

-- Verify afterwards:
--   select count(*) from public.ingredients;                  -- expect ~160
--   select name from public.ingredients where name ilike '%chilli%' order by 1;
