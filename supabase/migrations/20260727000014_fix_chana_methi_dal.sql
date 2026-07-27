-- Corrections to 013, plus a data-quality pass on "dal".
--
-- 013 merged methi -> methi leaves and chana -> kabuli chana. Inspecting the
-- actual recipes showed both were wrong:
--
--   methi appears only in Konju Curry, Meen Peora, Nartagai Curry and
--   Thandu Keirai Puli Kuzhambu — Kerala and Tamil fish/tamarind curries where
--   vendhayam (fenugreek SEEDS) is the standard tempering, not the greens.
--
--   chana appears mostly in Kala Chana Pilaf, Peshawari Kala Chana, Palak And
--   Kala Chana, Black Chickpeas And Cucumber Masala and Punjabi Black Chickpea
--   Curry — the BLACK chickpea. Only Kabuli Chana Rasam is the white one.
--
-- Recovery is possible because the recipe titles are known, so each affected
-- row can be re-pointed individually.

begin;

-- new pulses this catalogue actually needs -----------------------------------
insert into public.ingredients (name, is_pantry, category, icon_key)
select 'kala chana', false, 'legume', 'chickpea_black'
where not exists (select 1 from public.ingredients where lower(trim(name)) = 'kala chana');

insert into public.ingredients (name, is_pantry, category, icon_key)
select 'horse gram', false, 'legume', 'horsegram'
where not exists (select 1 from public.ingredients where lower(trim(name)) = 'horse gram');

-- helper: move one recipe's link from ingredient A to ingredient B ------------
create temp table moves(recipe_title text, from_name text, to_name text) on commit drop;

insert into moves values
  -- methi: leaves -> seeds
  ('Konju Curry','methi leaves','methi seeds'),
  ('Meen Peora','methi leaves','methi seeds'),
  ('Nartagai Curry','methi leaves','methi seeds'),
  ('Thandu Keirai Puli Kuzhambu','methi leaves','methi seeds'),
  -- chana: kabuli -> kala, where the title says so
  ('Kala Chana Pilaf','kabuli chana','kala chana'),
  ('Peshawari Kala Chana','kabuli chana','kala chana'),
  ('Palak And Kala Chana Sukhi Sabzi','kabuli chana','kala chana'),
  ('Black Chickpeas And Cucumber Masala','kabuli chana','kala chana'),
  ('Punjabi Black Chickpea Curry','kabuli chana','kala chana'),
  ('Bhogichi Bhaji','kabuli chana','kala chana'),
  ('Ghanta Tarkari','kabuli chana','kala chana'),
  -- dal: the six that are not ambiguous
  ('Kollu Puli Kuzhambu','dal','horse gram'),
  ('Murungai Keirai Kollu Kuzhambu','dal','horse gram'),
  ('Sprouted Horse Gram Thoran','dal','horse gram'),
  ('Gahat Rasmi Badi','dal','horse gram'),
  ('Rajma And Horse Gram Stuffed Paratha','dal','horse gram'),
  ('Kandi Pachadi','dal','arhar dal');

create temp table resolved on commit drop as
select r.id as recipe_id, f.id as from_id, t.id as to_id
from moves mv
join public.recipes     r on r.title = mv.recipe_title
join public.ingredients f on lower(trim(f.name)) = mv.from_name
join public.ingredients t on lower(trim(t.name)) = mv.to_name;

-- if the recipe already links to the destination, drop the row being moved
delete from public.recipe_ingredients ri
using resolved x
where ri.recipe_id = x.recipe_id
  and ri.ingredient_id = x.from_id
  and exists (select 1 from public.recipe_ingredients r2
              where r2.recipe_id = x.recipe_id and r2.ingredient_id = x.to_id);

update public.recipe_ingredients ri
   set ingredient_id = x.to_id
  from resolved x
 where ri.recipe_id = x.recipe_id
   and ri.ingredient_id = x.from_id;

commit;

-- Verify:
--   select i.name, count(*) from public.ingredients i
--     join public.recipe_ingredients ri on ri.ingredient_id = i.id
--    where i.name in ('kala chana','kabuli chana','horse gram','arhar dal',
--                     'methi seeds','methi leaves','dal')
--    group by i.name order by 1;
--
-- Expect: kala chana 7, kabuli chana back down, horse gram 5, dal 16,
--         methi seeds +4, methi leaves -4.
