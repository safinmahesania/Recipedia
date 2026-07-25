-- Users submitting recipes need to create ingredients that don't exist yet
-- (e.g. a new vegetable). The old policy allowed only admins to insert into
-- ingredients, so a normal user's submission failed at the ingredient step —
-- after the recipe row was already inserted, leaving orphaned recipes.

-- allow any signed-in user to add an ingredient (read stays public;
-- admin keeps full control for edits/deletes)
drop policy if exists ingredients_admin on public.ingredients;

create policy ingredients_insert on public.ingredients
  for insert to authenticated
  with check (true);

create policy ingredients_admin on public.ingredients
  for update using (is_admin()) with check (is_admin());

create policy ingredients_admin_delete on public.ingredients
  for delete using (is_admin());

-- (ingredients_read from the initial schema still allows public select)
