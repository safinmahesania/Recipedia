-- The last three ingredients without art.
--
-- RECOMMENDATIONS, with the reasoning. Each is one line to change if you
-- disagree — see the notes above each block.

begin;

-- ---------------------------------------------------------------------------
-- 1. methi (4 uses) -> methi leaves
--
-- In Indian recipe writing, bare "methi" almost always means the fresh greens
-- (aloo methi, methi thepla, methi paratha). When the seeds are meant, recipes
-- say "methi dana" or "methi seeds", because the seeds are a tempering spice
-- that has to be specified. You already store "methi seeds" separately, which
-- supports that reading.
--
-- To send it to seeds instead, change 'methi leaves' to 'methi seeds'.
-- ---------------------------------------------------------------------------

-- ---------------------------------------------------------------------------
-- 2. chana (11 uses) -> kabuli chana
--
-- Bare "chana" refers to the whole pulse, not the split lentil — "chana dal"
-- is always written in full when the split gram is meant. Merging into
-- kabuli chana keeps whole-chickpea recipes together.
--
-- To send it to the split lentil instead, change 'kabuli chana' to 'chana dal'.
-- ---------------------------------------------------------------------------

create temp table merge_pairs(keep_name text, dup_name text) on commit drop;
insert into merge_pairs values
  ('methi leaves','methi'),
  ('kabuli chana','chana');

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
  from public.recipe_ingredients ri left join m on m.dup_id = ri.ingredient_id
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
-- 3. dal (22 uses) -> KEPT as a generic pulse, deliberately not merged.
--
-- 22 uses is too many to fold into one pulse on a guess, and folding it into
-- (say) arhar dal would mislabel every recipe that meant moong or masoor.
-- It gets legume art so nothing renders blank.
--
-- The real fix is a data-quality pass: run inspect_three.sql, look at those 22
-- recipes, and assign the pulse each one actually calls for. Until then, be
-- aware "dal" matches only itself in the scan — a user scanning "toor dal"
-- gets no credit for a recipe that just says "dal".
-- ---------------------------------------------------------------------------
update public.ingredients
   set category = 'legume', icon_key = 'dal'
 where lower(trim(name)) = 'dal';

commit;

-- Verify: should return zero rows.
--   select name from public.ingredients where icon_key is null;
