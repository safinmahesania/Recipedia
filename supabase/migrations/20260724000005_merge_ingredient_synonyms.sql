-- Hindi and English names for the same ingredient were imported as separate
-- rows (aloo vs potato), so scanning "potato" missed recipes storing "aloo".
-- This merges synonyms onto one canonical name.

-- Repoints every recipe link from `alias` to `canonical`, then drops the alias.
create or replace function public.merge_ingredient(alias text, canonical text)
returns void
language plpgsql
as $$
declare
  alias_id uuid;
  canon_id uuid;
begin
  select id into alias_id from public.ingredients where name = alias;
  select id into canon_id from public.ingredients where name = canonical;
  if alias_id is null then return; end if;

  -- if the canonical row does not exist yet, just rename the alias
  if canon_id is null then
    update public.ingredients set name = canonical where id = alias_id;
    return;
  end if;

  -- move links that would not collide, drop the rest
  update public.recipe_ingredients ri
    set ingredient_id = canon_id
  where ri.ingredient_id = alias_id
    and not exists (
      select 1 from public.recipe_ingredients x
      where x.recipe_id = ri.recipe_id and x.ingredient_id = canon_id
    );
  delete from public.recipe_ingredients where ingredient_id = alias_id;
  delete from public.ingredients where id = alias_id;
end;
$$;

-- English is the canonical form, since that is what the scan model will output.
select public.merge_ingredient('aloo', 'potato');
select public.merge_ingredient('potatoes', 'potato');
select public.merge_ingredient('palak', 'spinach');
select public.merge_ingredient('pyaz', 'onion');
select public.merge_ingredient('pyaaz', 'onion');
select public.merge_ingredient('onions', 'onion');
select public.merge_ingredient('tamatar', 'tomato');
select public.merge_ingredient('tomatoes', 'tomato');
select public.merge_ingredient('adrak', 'ginger');
select public.merge_ingredient('lehsun', 'garlic');
select public.merge_ingredient('lasun', 'garlic');
select public.merge_ingredient('dhania', 'coriander leaves');
select public.merge_ingredient('coriander', 'coriander leaves');
select public.merge_ingredient('fresh coriander', 'coriander leaves');
select public.merge_ingredient('gobi', 'cauliflower');
select public.merge_ingredient('cauliflower florets', 'cauliflower');
select public.merge_ingredient('gajar', 'carrot');
select public.merge_ingredient('carrots', 'carrot');
select public.merge_ingredient('matar', 'green peas');
select public.merge_ingredient('peas', 'green peas');
select public.merge_ingredient('bhindi', 'okra');
select public.merge_ingredient('ladies finger', 'okra');
select public.merge_ingredient('baingan', 'brinjal');
select public.merge_ingredient('eggplant', 'brinjal');
select public.merge_ingredient('methi leaves', 'fenugreek leaves');
select public.merge_ingredient('methi', 'fenugreek leaves');
select public.merge_ingredient('dahi', 'curd');
select public.merge_ingredient('yogurt', 'curd');
select public.merge_ingredient('yoghurt', 'curd');
select public.merge_ingredient('doodh', 'milk');
select public.merge_ingredient('chawal', 'rice');
select public.merge_ingredient('nimbu', 'lemon');
select public.merge_ingredient('nariyal', 'coconut');
select public.merge_ingredient('grated coconut', 'coconut');
select public.merge_ingredient('fresh coconut', 'coconut');
select public.merge_ingredient('green chillies', 'green chilli');
select public.merge_ingredient('red chillies', 'red chilli');
select public.merge_ingredient('mushrooms', 'mushroom');
select public.merge_ingredient('eggs', 'egg');
select public.merge_ingredient('pearl onions', 'onion');
select public.merge_ingredient('sooji', 'semolina');
select public.merge_ingredient('rava', 'semolina');
select public.merge_ingredient('arhar dal', 'toor dal');
select public.merge_ingredient('besan', 'gram flour');
select public.merge_ingredient('atta', 'wheat flour');
select public.merge_ingredient('whole wheat flour', 'wheat flour');
select public.merge_ingredient('cooked rice', 'rice');
select public.merge_ingredient('basmati rice', 'rice');
select public.merge_ingredient('cashew', 'cashew nuts');

-- fast prefix lookup for the scan autocomplete
create index if not exists ingredients_name_trgm_idx
  on public.ingredients using gin (name gin_trgm_ops);
