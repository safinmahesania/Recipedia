-- Resolves a contradiction that has been in the migration history since 010,
-- and restores aliases lost when 020 deleted rows that 021 later recreated.
--
-- THE CONTRADICTION
--
--   005  merge_ingredient('carrots', 'carrot')      -- one row, correct
--   010  declares an icon for 'carrots'             -- recreates it, undoing 005
--   016  declares 'carrots' as an ALIAS on 'carrot' -- now it is both
--
-- Seven names are in this state. The right answer is 005's: one row per
-- ingredient, with the plural kept as an alias so search still finds it.
-- Migration 010 was wrong to re-declare them and 021 faithfully restored that
-- mistake.
--
-- THE LOST ALIASES
--
-- 020 deleted 164 ingredient rows; 021 recreated them from the icon
-- declarations, which carry no alias data. So the restored rows came back
-- without the regional names 016 had attached — atta, baingan, kaju, toor dal.
-- Reapplied below.

begin;

-- ===========================================================================
-- 1. Collapse the seven plural duplicates
--
-- merge_ingredient repoints recipe_ingredients, user_allergies, staples and
-- shopping list rows before deleting, so nothing loses its ingredient.
-- ===========================================================================

do $$
declare r record;
begin
  for r in (
    select * from (values
  ('carrots', 'carrot'),
  ('coriander', 'coriander leaves'),
  ('fresh coconut', 'coconut'),
  ('green chillies', 'green chilli'),
  ('onions', 'onion'),
  ('potatoes', 'potato'),
  ('tomatoes', 'tomato')
    ) as t(src, dst)
  ) loop
    if exists (select 1 from public.ingredients where lower(name) = r.src)
       and exists (select 1 from public.ingredients where lower(name) = r.dst)
    then
      perform public.merge_ingredient(r.src, r.dst);
      raise notice 'merged % into %', r.src, r.dst;
    end if;
  end loop;
end $$;

-- ===========================================================================
-- 2. Reapply every declared alias
--
-- Skips any alias that is still a real ingredient name, so this cannot
-- recreate the collision it is fixing.
-- ===========================================================================

with declared(name, alias_list) as (values
  ('ajwain', array['ajowan', 'carom seeds']),
  ('almonds', array['badam']),
  ('arhar dal', array['pigeon pea', 'toor dal', 'tur dal']),
  ('asafoetida', array['hing']),
  ('bay leaf', array['tej patta']),
  ('besan', array['chickpea flour', 'gram flour']),
  ('bhindi', array['ladies finger', 'lady finger', 'okra']),
  ('bitter gourd', array['karela']),
  ('black pepper', array['kali mirch']),
  ('bottle gourd', array['doodhi', 'lauki']),
  ('brinjal', array['aubergine', 'baingan', 'eggplant']),
  ('butter', array['makhan']),
  ('cabbage', array['patta gobi']),
  ('cardamom', array['elaichi']),
  ('carom seeds', array['ajwain']),
  ('carrot', array['carrots', 'gajar']),
  ('cashew nuts', array['cashew', 'kaju']),
  ('cauliflower', array['cauliflower florets', 'gobi', 'phool gobi']),
  ('cinnamon', array['dalchini']),
  ('clove', array['laung']),
  ('coconut', array['fresh coconut', 'grated coconut', 'nariyal']),
  ('coriander leaves', array['cilantro', 'coriander', 'dhania', 'dhaniya', 'fresh coriander', 'hara dhaniya', 'kothmir']),
  ('cumin seeds', array['jeera', 'zeera']),
  ('curd', array['dahi', 'yoghurt', 'yogurt']),
  ('curry leaves', array['curry patta', 'kadi patta']),
  ('drumstick', array['moringa', 'sahjan']),
  ('egg', array['eggs']),
  ('fennel seeds', array['saunf']),
  ('fenugreek leaves', array['kasuri methi', 'methi', 'methi leaves']),
  ('garlic', array['lasan', 'lasun', 'lehsun']),
  ('ghee', array['clarified butter']),
  ('ginger', array['adrak']),
  ('gram flour', array['besan']),
  ('green chilli', array['green chillies', 'hari mirch', 'mirchi']),
  ('green peas', array['hara matar', 'matar', 'peas']),
  ('jaggery', array['gud', 'gur']),
  ('lemon', array['lime', 'nimbu']),
  ('methi leaves', array['fenugreek leaves', 'kasuri methi', 'methi']),
  ('milk', array['doodh']),
  ('mushroom', array['mushrooms']),
  ('mushrooms', array['khumb', 'mushroom']),
  ('mustard seeds', array['rai', 'sarson']),
  ('oil', array['tel']),
  ('okra', array['bhindi', 'ladies finger']),
  ('onion', array['kanda', 'onions', 'pearl onions', 'pyaaz', 'pyaz']),
  ('paneer', array['cottage cheese']),
  ('peanuts', array['groundnut', 'moongphali']),
  ('peas', array['matar']),
  ('pepper', array['black pepper', 'kali mirch']),
  ('poppy seeds', array['khus khus']),
  ('potato', array['aloo', 'alu', 'potatoes']),
  ('raw banana', array['kaccha kela']),
  ('red chilli', array['red chillies']),
  ('red chilli powder', array['lal mirch', 'lal mirch powder']),
  ('rice', array['basmati rice', 'chawal', 'cooked rice']),
  ('salt', array['namak']),
  ('semolina', array['rava', 'sooji']),
  ('sesame seeds', array['til']),
  ('sooji', array['rava', 'semolina', 'suji']),
  ('spinach', array['palak']),
  ('sugar', array['cheeni', 'shakkar']),
  ('tomato', array['tamatar', 'tomatoes']),
  ('toor dal', array['arhar dal']),
  ('turmeric powder', array['haldi']),
  ('wheat flour', array['atta', 'gehun ka atta', 'whole wheat flour']),
  ('whole wheat flour', array['atta', 'gehun ka atta', 'wheat flour'])
)
update public.ingredients i
set aliases = (
  select array(
    select distinct a
    from unnest(i.aliases || d.alias_list) a
    where a <> lower(i.name)
      and not exists (
        select 1 from public.ingredients j
        where lower(j.name) = a and j.id <> i.id)
  )
)
from declared d
where lower(btrim(i.name)) = d.name;

-- ===========================================================================
-- 3. Belt and braces: no alias may survive that shadows a real name
-- ===========================================================================

update public.ingredients i
set aliases = array(
  select a from unnest(i.aliases) a
  where not exists (
    select 1 from public.ingredients j
    where lower(j.name) = a and j.id <> i.id)
)
where exists (
  select 1 from unnest(i.aliases) a
  join public.ingredients j on lower(j.name) = a and j.id <> i.id);

commit;

select 'ingredients' as metric, count(*)::text as value from public.ingredients
union all select 'with aliases', count(*)::text from public.ingredients
  where cardinality(aliases) > 0
union all select 'total aliases', coalesce(sum(cardinality(aliases)),0)::text
  from public.ingredients
union all select 'aliases shadowing a real name', count(*)::text from (
  select 1 from public.ingredients i
  join public.ingredients j on lower(j.name) = any(i.aliases) and j.id <> i.id) t;
