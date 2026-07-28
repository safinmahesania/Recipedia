-- Repairs what the verification found after the Wikibooks import.
--
-- Run tools/verify_database.sql and verify_duplicates.sql again afterwards;
-- the counts should drop sharply.

begin;

-- ===========================================================================
-- 1. Aliases that landed on nothing
--
-- Migration 016 attached aliases to names like 'wheat flour' and 'okra'. Those
-- rows do not exist: migrations 010/012 chose 'whole wheat flour' and 'bhindi'
-- as canonical instead. The update matched zero rows, so ~18 regional names —
-- atta, kali mirch, bhindi — are unsearchable, which was the whole point of
-- that migration.
-- ===========================================================================

with corrections(target, extra) as (values
  ('methi leaves',      array['methi','kasuri methi','fenugreek leaves']),
  ('besan',             array['gram flour','chickpea flour']),
  ('mushrooms',         array['mushroom','khumb']),
  ('sooji',             array['semolina','rava','suji']),
  ('arhar dal',         array['toor dal','tur dal','pigeon pea']),
  ('whole wheat flour', array['atta','gehun ka atta','wheat flour']),
  ('bhindi',            array['okra','ladies finger','lady finger']),
  ('ajwain',            array['carom seeds','ajowan']),
  ('pepper',            array['kali mirch','black pepper']),
  ('green peas',        array['matar','hara matar'])
)
update public.ingredients i
set aliases = (
  select array(
    select distinct unnest(i.aliases || c.extra)
    except select lower(i.name)
  )
)
from corrections c
where lower(i.name) = c.target;

-- ===========================================================================
-- 2. Ambiguous aliases
--
-- 'matar' was claimed by both 'green peas' and 'peas', so search resolved to
-- whichever sorted first. And five aliases duplicate a real ingredient name,
-- which means typing that name finds a different row than the one you meant.
-- An alias must never shadow a real ingredient.
-- ===========================================================================

update public.ingredients i
set aliases = array(
  select a from unnest(i.aliases) a
  where not exists (
    select 1 from public.ingredients j
    where lower(j.name) = a and j.id <> i.id)
);

-- ===========================================================================
-- 3. Declared data that drifted
-- ===========================================================================

update public.ingredients
set icon_key = 'bayleaf', category = 'spice'
where lower(name) = 'bay leaves';

insert into public.ingredients (name, category, icon_key, is_pantry)
values ('dry red chilli', 'spice', 'chilli_red', false)
on conflict (name) do nothing;

-- ===========================================================================
-- 4. Recipes that can never match
--
-- Four recipes have no ingredients at all. match_recipes_for_user cannot
-- return them under any input, so they are dead weight that still shows up in
-- browse and search.
-- ===========================================================================

delete from public.recipes r
where not exists (
  select 1 from public.recipe_ingredients ri where ri.recipe_id = r.id);

-- ===========================================================================
-- 5. Diet, inferred from ingredients
--
-- 1146 of 1168 recipes have no diet, so the diet filter and the "hide unsafe"
-- path are effectively dead. Wikibooks carries no diet field.
--
-- Inference errs toward non-vegetarian on purpose: labelling a meat dish as
-- vegetarian is a real harm to someone relying on it, while the reverse is an
-- inconvenience. Anything with no signal is left NULL rather than guessed
-- Vegetarian — an unlabelled recipe is honest, a wrongly-labelled one is not.
-- ===========================================================================

with signals as (
  select r.id,
         bool_or(i.name ~* '\y(chicken|beef|pork|lamb|mutton|bacon|ham|sausage|'
                            'turkey|duck|veal|venison|goat|prawn|shrimp|fish|'
                            'salmon|tuna|cod|haddock|anchovy|crab|lobster|squid|'
                            'mussel|oyster|clam|scallop|gelatin|lard|chorizo|'
                            'pepperoni|salami|pancetta|prosciutto|meat|mince)\y')
           as has_meat,
         bool_or(i.name ~* '\y(egg|eggs|mayonnaise)\y') as has_egg
  from public.recipes r
  join public.recipe_ingredients ri on ri.recipe_id = r.id
  join public.ingredients i on i.id = ri.ingredient_id
  group by r.id
)
update public.recipes r
set diet = case
             when s.has_meat then 'Non Vegetarian'
             when s.has_egg  then 'Eggetarian'
             else 'Vegetarian'
           end
from signals s
where s.id = r.id
  and (r.diet is null or btrim(r.diet) = '');

-- ===========================================================================
-- 6. External image URLs
--
-- Third-party hosts hotlink-block and hang rather than erroring, which is why
-- recipe headers appeared blank. The illustration system already covers every
-- recipe deterministically, so dropping these loses nothing and removes the
-- last third-party image dependency.
-- ===========================================================================

update public.recipes
set image_url = null
where image_url is not null
  and btrim(image_url) <> ''
  and image_url not like '%supabase%';

-- ===========================================================================
-- 7. Ingredients nothing references
--
-- 165 rows no recipe uses. They clutter autocomplete and the staples picker
-- with things that can never match anything.
-- ===========================================================================

delete from public.ingredients i
where not exists (select 1 from public.recipe_ingredients ri
                  where ri.ingredient_id = i.id)
  and not exists (select 1 from public.user_pantry_staples s
                  where s.ingredient_id = i.id)
  and not exists (select 1 from public.user_allergies a
                  where a.ingredient_id = i.id)
  and not exists (select 1 from public.shopping_list_items sl
                  where sl.ingredient_id = i.id);

commit;

-- What changed
select 'recipes'                as metric, count(*)::text from public.recipes
union all select 'with diet',    count(*)::text from public.recipes where diet is not null
union all select 'with cuisine', count(*)::text from public.recipes where cuisine is not null
union all select 'ingredients',  count(*)::text from public.ingredients
union all select 'with aliases', count(*)::text from public.ingredients where cardinality(aliases) > 0
union all select 'external images', count(*)::text from public.recipes
  where image_url is not null and image_url not like '%supabase%';
