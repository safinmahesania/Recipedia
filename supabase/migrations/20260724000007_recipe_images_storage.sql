-- Storage bucket for recipe photos (uploaded from gallery/camera).
-- URL-based images still work too; this only adds the upload path.

insert into storage.buckets (id, name, public)
values ('recipe-images', 'recipe-images', true)
on conflict (id) do nothing;

-- anyone can view images
create policy "recipe images are public"
  on storage.objects for select
  using (bucket_id = 'recipe-images');

-- signed-in users can upload
create policy "authenticated can upload recipe images"
  on storage.objects for insert to authenticated
  with check (bucket_id = 'recipe-images');

-- users can replace/remove their own uploads
create policy "owners manage their recipe images"
  on storage.objects for update to authenticated
  using (bucket_id = 'recipe-images' and owner = auth.uid());
create policy "owners delete their recipe images"
  on storage.objects for delete to authenticated
  using (bucket_id = 'recipe-images' and owner = auth.uid());
