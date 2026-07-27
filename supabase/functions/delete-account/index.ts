// Deletes the calling user's auth record.
//
// The client cannot do this: removing a user requires the service_role key,
// which must never ship inside an app. So the client deletes nothing directly
// — it calls this, and this verifies the caller from their JWT and deletes
// only themselves.
//
// Deploy:  supabase functions deploy delete-account
//
// SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are injected automatically.
import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (req: Request) => {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) {
    return new Response(JSON.stringify({ error: 'missing authorization' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const url = Deno.env.get('SUPABASE_URL')!;
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

  // Identify the caller from their own token — never from the request body,
  // which would let anyone delete any account.
  const asUser = createClient(url, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await asUser.auth.getUser();
  if (userError || !user) {
    return new Response(JSON.stringify({ error: 'invalid token' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  // profiles cascades to recipes, reviews, favourites, allergies, staples,
  // shopping list and meal plan, so this one delete removes their content.
  const admin = createClient(url, serviceKey);
  await admin.from('profiles').delete().eq('id', user.id);

  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  return new Response(JSON.stringify({ deleted: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
