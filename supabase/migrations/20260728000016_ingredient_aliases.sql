-- Restore searchability for names the synonym merge removed.
--
-- Migration 5 merged 'aloo' into 'potato' and deleted the 'aloo' row. The data
-- model got cleaner and the search got worse: typing a regional name now
-- returns nothing, which is the name a lot of people would actually type.
--
-- Aliases live on the surviving row so there is still one canonical ingredient
-- per concept — the merge was right, the search just lost the vocabulary.

alter table public.ingredients
  add column if not exists aliases text[] not null default '{}';

with alias_data(canonical, alias_list) as (
  values
  ('almonds', array['badam']),
  ('asafoetida', array['hing']),
  ('bay leaf', array['tej patta']),
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
  ('green peas', array['matar', 'peas']),
  ('jaggery', array['gud', 'gur']),
  ('lemon', array['lime', 'nimbu']),
  ('milk', array['doodh']),
  ('mushroom', array['mushrooms']),
  ('mustard seeds', array['rai', 'sarson']),
  ('oil', array['tel']),
  ('okra', array['bhindi', 'ladies finger']),
  ('onion', array['kanda', 'onions', 'pearl onions', 'pyaaz', 'pyaz']),
  ('paneer', array['cottage cheese']),
  ('peanuts', array['groundnut', 'moongphali']),
  ('peas', array['matar']),
  ('poppy seeds', array['khus khus']),
  ('potato', array['aloo', 'alu', 'potatoes']),
  ('raw banana', array['kaccha kela']),
  ('red chilli', array['red chillies']),
  ('red chilli powder', array['lal mirch', 'lal mirch powder']),
  ('rice', array['basmati rice', 'chawal', 'cooked rice']),
  ('salt', array['namak']),
  ('semolina', array['rava', 'sooji']),
  ('sesame seeds', array['til']),
  ('spinach', array['palak']),
  ('sugar', array['cheeni', 'shakkar']),
  ('tomato', array['tamatar', 'tomatoes']),
  ('toor dal', array['arhar dal']),
  ('turmeric powder', array['haldi']),
  ('wheat flour', array['atta', 'gehun ka atta', 'whole wheat flour'])
)
update public.ingredients i
set aliases = (
  select array(
    select distinct unnest(a.alias_list)
    except select lower(i.name)
  )
)
from alias_data a
where lower(i.name) = a.canonical;

-- Trigram index so a contains-match on either name or alias stays cheap as the
-- catalogue grows.
create extension if not exists pg_trgm;
create index if not exists ingredients_name_trgm
  on public.ingredients using gin (name gin_trgm_ops);

comment on column public.ingredients.aliases is
  'Regional and colloquial names merged away in migration 5, kept searchable.';
