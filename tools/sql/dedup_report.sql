-- ===========================================================================
-- READ-ONLY duplicate report. ONE statement, so the SQL editor shows all of it.
-- Nothing is written. Run, review, then we merge.
-- ===========================================================================
with uses as (
  select ingredient_id, count(*) as n from public.recipe_ingredients group by 1
),
ing as (
  select i.id, lower(trim(i.name)) as nm, i.name, coalesce(u.n, 0) as n
  from public.ingredients i
  left join uses u on u.ingredient_id = i.id
),
-- Known synonym pairs a plural rule cannot catch. keep = the survivor.
pairs(keep, dup, reason) as (values
  ('arhar dal','toor dal','same pulse'),
  ('red chilli powder','chilli powder','same spice'),
  ('kashmiri red chilli powder','kashmiri red chilli','same spice'),
  ('black peppercorns','peppercorns','same, whole'),
  ('black peppercorns','pepper','same, whole'),
  ('black pepper powder','black pepper','same, ground'),
  ('coconut','fresh coconut','same'),
  ('coriander leaves','coriander','same, fresh'),
  ('red chilli','red chillies','plural'),
  ('red chilli','dry red chilli','same, dried'),
  ('green chilli','green chillies','plural')
)
select p.reason,
       k.name as keep_name, k.n as keep_uses,
       d.name as dup_name,  d.n as dup_uses,
       k.n + d.n as combined
from pairs p
join ing k on k.nm = p.keep
join ing d on d.nm = p.dup

union all

-- Automatic singular/plural pairs.
select 'plural (auto)',
       a.name, a.n, b.name, b.n, a.n + b.n
from ing a
join ing b on b.id <> a.id
          and b.nm in (a.nm || 's', a.nm || 'es')
          and a.n >= b.n

order by 6 desc;
