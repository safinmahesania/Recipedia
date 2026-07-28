-- Attribution columns, required before importing anything share-alike.
--
-- CC BY-SA is not "free to use" — it is "free to use IF you credit the source
-- and link the licence". Wikibooks Cookbook is CC BY-SA 3.0, so every recipe
-- from it must carry its origin and that origin must be visible in the app.
-- Storing this per recipe rather than as one blanket page is what makes the
-- obligation survive a recipe being shared, exported or shown in isolation.
--
-- Nullable because user submissions have no external source — the author is
-- the user, and author_id already records that.

alter table public.recipes
  add column if not exists source_name text,
  add column if not exists source_url  text,
  add column if not exists license     text;

comment on column public.recipes.source_name is
  'Human-readable origin, e.g. "Wikibooks Cookbook". Null for user submissions.';
comment on column public.recipes.source_url is
  'Canonical link back to the original. Required by CC BY-SA.';
comment on column public.recipes.license is
  'Licence identifier, e.g. "CC BY-SA 3.0". Null means user-submitted.';

create index if not exists recipes_source_idx on public.recipes(source_name);
