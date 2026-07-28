# Backlog

Parked work, ordered. Anything here is known and deliberate, not forgotten.

## Features — schema exists, UI does not

Each of these has database columns or a service already in place. The work is
the screen, not the plumbing.

| # | Feature | What's already there | What's missing |
|---|---|---|---|
| 1 | ~~Collections: add a recipe~~ | ~~`collections` table, full service, filter bar~~ | **Done** |
| 2 | Edit profile | `username`, `bio`, `avatar_url` on `profiles`; model reads them | No edit screen. Name, username, bio and avatar cannot be changed. Avatar also needs a storage bucket — only `recipe-images` exists |
| 3 | Notification preferences | `notify_new_recipes`, `notify_submission_status`, `notify_review_replies` columns | Profile tile is a placeholder. Toggles can persist now and drive FCM later |
| 4 | ~~Cooking history~~ | ~~written by cook mode~~ | **Done** — history screen, stats, and a badge on recipe detail |
| 5 | ~~Default cuisine~~ | ~~`default_cuisine` column~~ | **Done** — picker added, applied as a filter default |

### Deliberately not built

**Units (`metric` / `imperial`)** — there is no conversion logic anywhere, and
quantities are free text ("2 cups", "a handful", "500 g"). A toggle would change
a stored value and nothing on screen. Real support means parsing and converting
those strings, which is a feature in itself. Better absent than lying.

**Language** — the app has no i18n: no `flutter_localizations`, no ARB files,
every string is a hard-coded literal. A picker offering only English is theatre.
Doing this properly means extracting ~600 strings first.

Both columns stay in the schema; they cost nothing and the work is scoped
above whenever it's wanted.

## Machine learning

| # | Model | Data | Status |
|---|---|---|---|
| 1 | Ingredient recognition (scan) | needs an image dataset | Training pipeline ready in `ml/`. Run it, drop the two files into `assets/ml/`, wire `_runModel` |
| 2 | Instruction cleanup to numbered steps | 1032 recipes, in hand | Next — parse once into a `steps` column instead of at every render |
| 3 | Ingredient embeddings -> substitutions | 10,307 recipe_ingredients rows | After the cleanup. Unsupervised, no labelling, directly serves "cook what you have" |
| 4 | Auto-tagging (diet / cuisine / course) | 1032 already-labelled recipes | Parked. Strongest academic story, moderate product value |
| 5 | Recipe recommendation | needs ~500 active users | Blocked on user volume, not code. Use popularity counts until then |
| 6 | Cook time estimation | labels exist but are free text and noisy | Not worth it — a rule beats a model on this data |

## Blocked on external work

| Feature | Blocker |
|---|---|
| Automatic ingredient detection | TFLite model not trained. Scan UI is built and waiting; `ScanService.isModelAvailable` flips it on |
| Push notifications | Firebase project + `firebase_messaging` |
| Cook mode staying awake | `wakelock_plus` dependency — two lines once added |
| Policy links, "Open mail app" | `url_launcher` dependency |
| Full account deletion | `supabase functions deploy delete-account` |
| Google / Apple sign-in | OAuth credentials |

## Before launch

- Recipe photography licensing — illustrations are a stopgap
- Automated database backups
- iOS and web targets (`ios/` and `web/` do not exist yet)

## Small UI fixes

_To be filled in — send the list and it goes here._

- [ ]
