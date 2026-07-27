-- Ingredient categories and icon keys.
--
-- Two columns drive a three-tier fallback in the app so an ingredient can
-- never render blank:
--   1. icon_key  -> a specific drawing            (assets/ing/$icon_key.svg)
--   2. category  -> a generic drawing             (assets/ing/cat_$category.svg)
--   3. neither   -> first letter on a category tint
--
-- The backfill below covers the 80 most-used ingredient names, which is 90.3%
-- of all ingredient occurrences in the current catalogue. The head of this
-- distribution is stable, so that percentage holds as recipes are added.

alter table public.ingredients
  add column if not exists category text,
  add column if not exists icon_key text;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'ingredients_category_check') then
    alter table public.ingredients add constraint ingredients_category_check
      check (category is null or category in (
        'vegetable','fruit','leafy','herb','dairy','spice','grain',
        'legume','nut','oil','meat','seafood','sweetener','liquid','other'));
  end if;
end $$;

create index if not exists ingredients_category_idx on public.ingredients(category);

-- ---------------------------------------------------------------------------
-- Backfill. Matched on lower(trim(name)) so casing and stray spaces don't miss.
-- ---------------------------------------------------------------------------
with m(name, category, icon_key) as (values
  ('salt','spice','salt'),
  ('water','liquid','water'),
  ('sugar','sweetener','sugar'),
  ('jaggery','sweetener','jaggery'),
  ('tamarind','fruit','tamarind'),
  ('oil','oil','oil'),
  ('mustard oil','oil','oil_mustard'),
  ('coconut oil','oil','oil_coconut'),
  ('sesame oil','oil','oil_sesame'),
  ('ghee','dairy','ghee'),
  ('turmeric powder','spice','powder_turmeric'),
  ('red chilli powder','spice','powder_chilli'),
  ('kashmiri red chilli powder','spice','powder_chilli'),
  ('coriander powder','spice','powder_coriander'),
  ('cumin powder','spice','powder_cumin'),
  ('garam masala','spice','powder_garam'),
  ('amchur','spice','powder_amchur'),
  ('black pepper powder','spice','powder_pepper'),
  ('asafoetida','spice','powder_hing'),
  ('cumin seeds','spice','seeds_cumin'),
  ('mustard seeds','spice','seeds_mustard'),
  ('coriander seeds','spice','seeds_coriander'),
  ('fennel seeds','spice','seeds_fennel'),
  ('methi seeds','spice','seeds_methi'),
  ('ajwain','spice','seeds_ajwain'),
  ('poppy seeds','spice','seeds_poppy'),
  ('black peppercorns','spice','seeds_pepper'),
  ('cinnamon stick','spice','cinnamon'),
  ('cardamom','spice','cardamom'),
  ('bay leaf','spice','bayleaf'),
  ('bay leaves','spice','bayleaf'),
  ('ginger','vegetable','ginger'),
  ('garlic','vegetable','garlic'),
  ('ginger garlic paste','spice','paste_gg'),
  ('onion','vegetable','onion'),
  ('onions','vegetable','onion'),
  ('tomato','vegetable','tomato'),
  ('tomatoes','vegetable','tomato'),
  ('tomato puree','vegetable','tomato'),
  ('green chilli','vegetable','chilli_green'),
  ('green chillies','vegetable','chilli_green'),
  ('red chilli','spice','chilli_red'),
  ('red chillies','spice','chilli_red'),
  ('dry red chilli','spice','chilli_red'),
  ('potato','vegetable','potato'),
  ('potatoes','vegetable','potato'),
  ('carrot','vegetable','carrot'),
  ('carrots','vegetable','carrot'),
  ('brinjal','vegetable','brinjal'),
  ('bhindi','vegetable','okra'),
  ('bell pepper','vegetable','bellpepper'),
  ('green peas','vegetable','peas'),
  ('beans','vegetable','beans'),
  ('curry leaves','leafy','leaves_curry'),
  ('coriander leaves','leafy','leaves_coriander'),
  ('coriander','leafy','leaves_coriander'),
  ('mint leaves','leafy','leaves_mint'),
  ('methi leaves','leafy','leaves_methi'),
  ('kasuri methi','leafy','leaves_methi'),
  ('spinach','leafy','spinach'),
  ('fresh coconut','fruit','coconut'),
  ('coconut','fruit','coconut'),
  ('coconut milk','dairy','coconut_milk'),
  ('lemon','fruit','lemon'),
  ('lemon juice','fruit','lemon'),
  ('mango','fruit','mango'),
  ('curd','dairy','curd'),
  ('milk','dairy','milk'),
  ('fresh cream','dairy','cream'),
  ('paneer','dairy','paneer'),
  ('urad dal','legume','dal_urad'),
  ('chana dal','legume','dal_chana'),
  ('arhar dal','legume','dal_arhar'),
  ('moong dal','legume','dal_moong'),
  ('rice','grain','rice'),
  ('whole wheat flour','grain','flour'),
  ('cashew nuts','nut','cashew'),
  ('peanuts','nut','peanut'),
  ('chicken','meat','chicken'),
  ('fish','seafood','fish')
)
update public.ingredients i
   set category = m.category,
       icon_key = m.icon_key
  from m
 where lower(trim(i.name)) = m.name;

-- Everything unmatched still gets a usable fallback rather than nothing.
update public.ingredients
   set category = 'other'
 where category is null;

-- ---------------------------------------------------------------------------
-- How well did it land?
-- ---------------------------------------------------------------------------
-- select category, count(*), count(icon_key) as with_specific_art
--   from public.ingredients group by category order by 2 desc;
