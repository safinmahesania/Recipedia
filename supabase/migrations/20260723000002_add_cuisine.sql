-- Firebase data carries a cuisine (e.g. "South Indian") separate from the
-- course (e.g. "Breakfast"). Course maps to categories; cuisine gets its own
-- column so it can be filtered on later.
alter table public.recipes add column if not exists cuisine text;
create index if not exists recipes_cuisine_idx on public.recipes(cuisine);
