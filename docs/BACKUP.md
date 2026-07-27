# Database backup and restore

A scheduled GitHub Action dumps the `public` schema every night and keeps the
archive for 90 days.

## One-time setup

1. Supabase dashboard → **Project Settings → Database → Connection string →
   URI**. Use the **session pooler** string (port `5432`), not the transaction
   pooler — `pg_dump` needs a session connection.
2. GitHub repo → **Settings → Secrets and variables → Actions → New secret**
   - Name: `SUPABASE_DB_URL`
   - Value: the full URI including the password

Then run it once by hand: **Actions → Database backup → Run workflow**. If it
goes green, the schedule will too.

## What gets produced

| File | Contents | Use |
|---|---|---|
| `recipedia-full-<date>.sql.gz` | `public` schema + all data | Full restore |
| `recipedia-content-<date>.sql.gz` | `categories`, `ingredients`, `recipes`, `recipe_ingredients` — data only | Rebuild the catalogue without user rows |

The workflow fails if a dump comes out under 10 KB, so a broken run is loud
rather than silently archiving an empty file.

## Restore

Download the artifact from the run, then:

```bash
gunzip recipedia-full-2026-07-27.sql.gz
psql "$DATABASE_URL" -f recipedia-full-2026-07-27.sql
```

Content only, into a schema that already exists:

```bash
gunzip recipedia-content-2026-07-27.sql.gz
psql "$DATABASE_URL" -f recipedia-content-2026-07-27.sql
```

## Limits worth knowing

- Artifacts expire after **90 days**. For longer retention, add a step pushing
  to object storage (S3, R2, Backblaze).
- `auth.users` is **not** included — it lives outside `public` and needs the
  service role. Profiles survive; logins do not. For a full disaster recovery
  story, enable Supabase's own PITR backups on a paid plan.
- The dump runs against production. It is read-only, but it does hold a
  connection for its duration.

## Test it

A backup you have never restored is a hypothesis. Restore into a scratch
Supabase project at least once and confirm the recipe count matches.
