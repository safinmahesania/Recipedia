-- Recipedia — TEST data for exercising the recent features.
-- Every recipe title starts with [TEST] so cleanup is one statement (bottom).
-- Run in Supabase SQL Editor. Safe to run once; re-running makes duplicates.
--
-- Covers: scan matching (core/optional/pantry), admin pending queue
-- (approve/reject), reviews, and the reports moderation queue.

do $$
declare
  v_admin uuid;   -- an admin profile (for approved recipes + moderation)
  v_user  uuid;   -- a normal user (for pending submissions + reviews)
  cat_main uuid;
  cat_bev  uuid;

  -- recipe ids
  r_aloo uuid := gen_random_uuid();
  r_egg  uuid := gen_random_uuid();
  r_paneer uuid := gen_random_uuid();
  r_juice uuid := gen_random_uuid();
  r_pending1 uuid := gen_random_uuid();
  r_pending2 uuid := gen_random_uuid();
  r_rejected uuid := gen_random_uuid();

begin
  -- pick actors
  select id into v_admin from public.profiles where role = 'admin' limit 1;
  select id into v_user  from public.profiles where role = 'user'  limit 1;
  if v_admin is null then
    select id into v_admin from public.profiles limit 1;   -- fall back to any profile
  end if;
  if v_user is null then v_user := v_admin; end if;
  if v_admin is null then
    raise exception 'No profiles found. Sign up at least one user first.';
  end if;

  -- categories (reuse if present)
  select id into cat_main from public.categories where name = 'Main Course' limit 1;
  if cat_main is null then
    insert into public.categories(name, kind) values('Main Course','food') returning id into cat_main;
  end if;
  select id into cat_bev from public.categories where name = 'Juices' limit 1;
  if cat_bev is null then
    insert into public.categories(name, kind) values('Juices','beverage') returning id into cat_bev;
  end if;

  -- ingredients (idempotent via ON CONFLICT on unique name)
  insert into public.ingredients(name, is_pantry) values
    ('potato', false), ('spinach', false), ('tomato', false), ('onion', false),
    ('egg', false), ('paneer', false), ('mango', false), ('milk', false),
    ('ginger', false), ('garlic', false),
    ('salt', true), ('oil', true), ('sugar', true), ('turmeric powder', true)
  on conflict (name) do nothing;

  -- ===================== APPROVED (browse + scan) =====================
  insert into public.recipes(id,title,instructions,cook_time,diet,category_id,author_id,status) values
    (r_aloo,'[TEST] Aloo Palak','Cook potato and spinach with spices.','30 min','Vegetarian',cat_main,v_admin,'approved'),
    (r_egg,'[TEST] Egg Curry','Boil eggs, simmer in onion-tomato gravy.','40 min','Non Vegetarian',cat_main,v_admin,'approved'),
    (r_paneer,'[TEST] Paneer Butter Masala','Paneer in a tomato butter gravy.','35 min','Vegetarian',cat_main,v_admin,'approved'),
    (r_juice,'[TEST] Mango Juice','Blend mango with milk and sugar.','5 min','Vegetarian',cat_bev,v_admin,'approved');

  -- link ingredients (core drives scan matching; pantry never blocks)
  -- Aloo Palak: core potato+spinach, optional tomato, pantry salt+oil
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_aloo, id, 'core'     from public.ingredients where name in ('potato','spinach');
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_aloo, id, 'optional' from public.ingredients where name in ('tomato');
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_aloo, id, 'core'     from public.ingredients where name in ('salt','oil');
  -- Egg Curry: core egg+onion+tomato
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_egg, id, 'core' from public.ingredients where name in ('egg','onion','tomato');
  -- Paneer: core paneer+tomato, optional onion
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_paneer, id, 'core'     from public.ingredients where name in ('paneer','tomato');
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_paneer, id, 'optional' from public.ingredients where name in ('onion');
  -- Mango Juice: core mango+milk, pantry sugar
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_juice, id, 'core' from public.ingredients where name in ('mango','milk','sugar');

  -- ===================== PENDING (admin approve/reject queue) =====================
  insert into public.recipes(id,title,instructions,cook_time,diet,category_id,author_id,status) values
    (r_pending1,'[TEST] Pending Veg Pulao','Rice cooked with vegetables.','25 min','Vegetarian',cat_main,v_user,'pending'),
    (r_pending2,'[TEST] Pending Garlic Bread','Toasted bread with garlic butter.','15 min','Vegetarian',cat_main,v_user,'pending');
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_pending1, id, 'core' from public.ingredients where name in ('onion','ginger');
  insert into public.recipe_ingredients(recipe_id,ingredient_id,role)
    select r_pending2, id, 'core' from public.ingredients where name in ('garlic');

  -- ===================== REJECTED (shows reason to author) =====================
  insert into public.recipes(id,title,instructions,cook_time,diet,category_id,author_id,status,rejection_reason) values
    (r_rejected,'[TEST] Rejected Recipe','Incomplete instructions.','10 min','Vegetarian',cat_main,v_user,'rejected','Please add clearer steps and a photo.');

  -- ===================== REVIEWS =====================
  insert into public.reviews(user_id,recipe_id,rating,comment) values
    (v_user, r_aloo, 5, 'Turned out great!'),
    (v_user, r_egg, 4, 'Tasty but a bit spicy.'),
    (v_admin, r_paneer, 5, 'Restaurant quality.')
  on conflict (user_id,recipe_id) do nothing;

  -- ===================== REPORTS (moderation queue) =====================
  insert into public.reports(reporter_id,target_type,target_id,reason) values
    (v_user, 'recipe', r_egg, 'Ingredient list looks wrong.'),
    (v_user, 'review', r_aloo, 'Spam comment.');

  raise notice 'Test data inserted. Admin=%, User=%', v_admin, v_user;
end $$;

-- ============================== CLEANUP ==============================
-- Run this later to remove ALL test data in one go:
--
-- delete from public.reports where target_id in (select id from public.recipes where title like '[TEST]%');
-- delete from public.reviews where recipe_id in (select id from public.recipes where title like '[TEST]%');
-- delete from public.recipes where title like '[TEST]%';
-- (recipe_ingredients rows cascade automatically)