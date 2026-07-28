# Full database audit

```bash
python tools/gen_full_audit.py
# paste out/audit.sql into the Supabase SQL Editor
```

Read-only. One result set. **No FAIL rows means the database is sound.**

## Why it is generated

Half these checks assert what the migrations declare — icon mappings, merges,
aliases. Written by hand they drift from the migrations within a week and start
reporting failures against correct data.

That already happened: an earlier hand-maintained version reported 19 merges as
"undone" when migrations 010 and 012 had deliberately reversed them. Nineteen
false failures is worse than no check, because it teaches you to skim the output.

Regenerate after any migration and the assertions follow.

## Sections

| | Covers | The check that matters |
|---|---|---|
| **A schema** | tables, functions, RLS, policies, FK indexes | *RLS on but no policy* — nobody can read the table, including the row owner |
| **B declared** | data vs what migrations say | *merge undone* — an import recreated a merged name, splitting recipes across two rows |
| **C duplicates** | case-insensitive names, aliases, titles | *ingredient name (case-insensitive)* — the column constraint allows `Onion` and `onion` |
| **D integrity** | orphans, impossible states | *recipe with no CORE ingredients* — can never be matched |
| **E content** | can recipes actually be found | *approved recipe with no diet* — invisible to the filter and to hide-unsafe |
| **F user data** | allergies, staples, lists | duplicates in the tables that lack constraints |
| **G security** | admin presence, SECURITY DEFINER | *no admin account* — moderation unreachable |
| **H summary** | counts | *avg core ingredients per recipe* — below 4 and matching is unreliable |

## Reading it

**FAIL** — the app depends on this and it is broken. Fix before shipping.
**WARN** — works today, degrades a feature or will bite later.
**INFO** — a number, not a problem.

Sorted FAIL first. If the first rows are `H summary`, everything passed.

## The three numbers to watch after any import

**`avg core ingredients per recipe`** — the best single predictor of whether
scan works. Recipe count is irrelevant if they are all thin.

**`merge undone`** — should always be zero. Anything here means duplicate
ingredients, and scan silently finding half the recipes it should.

**`approved recipe with no diet` / `no cuisine` / `no category`** — these are
whole features returning nothing. SQL cannot fix them; they need the
auto-tagging classifier.

## When to run

After any import, after any migration, before deploying, and whenever
something behaves oddly and you want to rule the data out first.
