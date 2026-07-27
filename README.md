# Recipedia

**Find recipes from the ingredients you already have.**

Most recipe apps start with a dish and send you shopping. Recipedia starts with
your kitchen: tell it what you have, and it ranks 1,000+ Indian recipes by how
much of each one you can already make — then shows you what you're one
ingredient away from.

Flutter · Supabase · GetX

---

## Contents

- [Features](#features)
- [Screens](#screens)
- [Architecture](#architecture)
- [Tech stack](#tech-stack)
- [Getting started](#getting-started)
- [Environment variables](#environment-variables)
- [Database](#database)
- [Design system](#design-system)
- [Project structure](#project-structure)
- [Testing and CI](#testing-and-ci)
- [Conventions and gotchas](#conventions-and-gotchas)
- [Roadmap](#roadmap)
- [Credits](#credits)

---

## Features

### Cooking

- **Ingredient matching** — enter what you have; recipes are ranked by coverage
  and split into *Ready to cook* and *Almost there*, with the missing items named.
- **Pantry staples** — mark salt, oil, turmeric and the rest once. They stop
  counting as missing, which changes results dramatically.
- **Allergy awareness** — flagged recipes are either hidden or warned about,
  your choice. Enforced in Postgres, not just in the UI.
- **Cook mode** — full-screen, one step at a time, with timers detected from the
  instruction text ("simmer 10–12 minutes" offers a 12-minute timer).
- **Shopping list** — add what a recipe is missing in one tap, grouped by the
  recipe it came from. Checked items move into your pantry, so the next match is
  accurate without re-entering anything.
- **Meal planner** — a week of meals, plus one-tap "shop for this week" that
  subtracts your pantry and staples from everything planned.

### Discovery

- Search, filter by diet / cuisine / course with live counts
- Save recipes into collections, works offline
- Ratings and reviews
- Home surfaces what you can cook now, quick recipes, cuisines and recent views

### Contribution and moderation

- Submit recipes with photo upload or URL; track approval status
- Admin dashboard with pending queue, user management and a moderation queue
- Row Level Security on every table — the admin UI is a convenience, not the
  access control

---

## Screens

| Area | Screens |
|---|---|
| Auth | Welcome, Login, Signup, Forgot password, Mail sent |
| Onboarding | Diet, allergies, pantry staples, confirmation |
| Core | Home, Recipes, Recipe detail, Cook mode, Scan, Scan results, Saved |
| Personal | Profile, Diet & allergies, My reviews, Account & security, Shopping list, Meal planner |
| Contribution | Submit recipe, My submissions, Write a review |
| Admin | Dashboard, Pending approvals, All recipes, Users, Reviews, Reports |

---

## Architecture

MVC with a strict one-way dependency chain:

```
View  ──▶  Controller  ──▶  Service  ──▶  Supabase
 │            │               │
 UI       state, no UI     data only, no state
```

**The rules that keep it honest:**

- **Services never import Flutter.** No widgets, no navigation, no snackbars.
  A service returns data or throws.
- **Controllers never build UI.** They hold observable state and call services.
- **Views never call Supabase directly.** If a screen needs data, a service grows
  a method.
- **Business rules that matter live in Postgres.** Ingredient matching, allergy
  filtering and permissions are RPCs and RLS policies, so they can't be bypassed
  by a modified client.

---

## Tech stack

| Layer | Choice |
|---|---|
| Framework | Flutter (Dart SDK ≥ 3.0) |
| State / routing / DI | GetX |
| Backend | Supabase — Postgres, Auth, Storage, Edge Functions |
| Images | `cached_network_image` + generated SVG placeholders |
| Vector rendering | `flutter_svg` |
| Local cache | `shared_preferences` |
| Lints | `flutter_lints` |

No paid APIs. No third-party recipe service.

---

## Getting started

### Prerequisites

- Flutter (stable channel)
- A Supabase project
- Supabase CLI, for migrations

### 1. Clone and install

```bash
git clone https://github.com/safinmahesania/Recipedia.git
cd Recipedia
flutter pub get
```

### 2. Set up the database

```bash
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

This applies all 14 migrations in order: schema, RLS policies, matching RPCs,
storage buckets, and the ingredient icon/category data.

Optional sample data for local testing:

```bash
psql "$DATABASE_URL" -f supabase/seed/seed_sample_data.sql
```

### 3. Deploy the Edge Function

Account deletion needs the service-role key, which must never ship in an app,
so it runs server-side:

```bash
supabase functions deploy delete-account
```

Without this, deleting an account still removes all user data (the `profiles`
row cascades) but leaves the auth record behind.

### 4. Run

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

> **Tip:** save these in `.vscode/launch.json` or a shell alias — the app cannot
> reach the backend without them, and the failure looks like an empty screen
> rather than an error.

### Release build

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

---

## Environment variables

| Variable | Where to find it |
|---|---|
| `SUPABASE_URL` | Supabase dashboard → Project Settings → API |
| `SUPABASE_ANON_KEY` | Same page. Publishable/anon key only — **never** the service-role key |

Credentials are injected at compile time via `--dart-define` and read with
`String.fromEnvironment`. There is no `.env` file and no key committed to the
repository.

---

## Database

### Tables

| Table | Purpose |
|---|---|
| `profiles` | User profile, role, diet preference, notification and theme settings |
| `recipes` | Recipe content, status (`pending` / `approved` / `rejected`), author |
| `ingredients` | Canonical ingredient list, with `icon_key` and `category` for artwork |
| `recipe_ingredients` | Join table with `role` (`core` / `optional`) and quantity |
| `categories` | Course taxonomy |
| `favorites` / `collections` | Saved recipes, optionally grouped |
| `reviews` | One rating and comment per user per recipe |
| `reports` | Polymorphic moderation queue (`target_type` + `target_id`) |
| `user_allergies` | Ingredients to avoid |
| `user_pantry_staples` | Ingredients that never count as missing |
| `shopping_list_items` | Known ingredient or free text, optionally linked to a recipe |
| `meal_plan_entries` | Date + slot + recipe |
| `cooked_history` | What was actually cooked, and when |

### Functions

| Function | What it does |
|---|---|
| `match_recipes_for_user(scanned)` | The core matcher. Excludes the caller's pantry staples, returns match and missing counts plus `has_allergen`. |
| `match_recipes_by_ingredients(scanned)` | Earlier, user-agnostic version. Superseded — safe to drop. |
| `profile_stats(user_id)` | Saved / submitted / review counts in one round trip |
| `distinct_diets()` / `distinct_cuisines()` | Filter options with live recipe counts |
| `merge_ingredient(from, to)` | Repoints every reference before deleting a duplicate |
| `is_admin()` | Used inside RLS policies |
| `handle_new_user()` | Trigger creating a profile on signup |

### Security

Row Level Security is enabled on every table. Users read approved recipes and
write only their own rows; admins are granted more through `is_admin()`. The
client is never trusted for authorisation.

---

## Design system

Everything is driven by tokens — no raw colours in screens.

| File | Holds |
|---|---|
| `lib/constants/app_colors.dart` | Palette, both modes, plus the category tint ramp |
| `lib/constants/app_sizes.dart` | Spacing, radii, durations, shadows |
| `lib/constants/app_text_styles.dart` | Type scale |
| `lib/theme/app_tokens.dart` | `ThemeExtension` — read via `context.tokens` |
| `lib/theme/app_theme.dart` | Assembles light and dark `ThemeData` |

**Typography** — Plus Jakarta Sans for display, Inter (18pt optical size) for UI.
Both bundled; no network fetch.

**Icons** — Tabler, shipped as SVG and tinted at runtime through `AppIcon`.
Their viewBox is padded to `-2 -2 28 28` so optical weight matches Material's
inset glyphs.

**Illustrations** — 140 hand-built SVGs, ~52 KB total, replacing recipe
photography that isn't licensed yet. Ingredients resolve in three tiers:
exact `icon_key` → `category` fallback → letter chip. Recipe placeholders are
seeded on the recipe id, so a recipe keeps the same tint and dish drawing
everywhere it appears.

**Dark mode** — not an inversion. Light uses borderless cards with soft
shadows; dark switches to raised panels with hairline borders, because shadows
are invisible on dark surfaces. The accent shifts from mint to gold at night.

All text colours meet WCAG AA.

---

## Project structure

```
lib/
├── constants/     colours, sizes, type, strings, generated asset manifests
├── controllers/   GetX controllers — state only
├── models/        typed models
├── services/      Supabase access — no Flutter imports
├── shared/        reusable widgets and pure helpers
├── theme/         tokens and ThemeData
└── views/         screens, grouped by feature

assets/
├── icons/         Tabler icon set (SVG)
├── ing/           ingredient illustrations
└── dish/          recipe placeholders, light and dark cuts

supabase/
├── migrations/    schema, RLS, RPCs — applied in order
├── functions/     Edge Functions
└── seed/          optional sample data

tools/             asset generators (regenerate, don't hand-edit assets)
test/              unit and static-analysis tests
```

---

## Testing and CI

```bash
flutter analyze     # must be clean — CI fails on any issue
flutter test
```

GitHub Actions runs analyze and test on every branch, and builds a debug APK on
`main`.

Two tests earn their place:

- **`design_system_test.dart`** — the tint ramp stays in bounds and both themes
  register the token extension.
- **`getx_reactivity_test.dart`** — fails the build if a widget reads a GetX
  observable without its own `Obx`. See below for why.

---

## Conventions and gotchas

Things that cost real debugging time here. Worth reading before contributing.

**`Obx` only tracks what it reads during its own build.** A child widget's
`build()` runs outside that scope, so passing a controller into a child does
*not* extend the subscription. The widget renders once with the initial value
and never updates — silently, with no warning from the analyzer. Any widget
reading `.value` needs its own `Obx`. There is a test enforcing this.

**PostgREST can only embed across a real foreign key.** `reports` is
polymorphic (`target_type` + a bare `target_id`), so `reports.select('recipes(...)')`
fails at runtime with `PGRST200`. Resolve those in a second query.

**`BoxDecoration` has assertions the analyzer can't see.** `color` and
`gradient` are mutually exclusive, and a `borderRadius` requires uniform border
colours. Both compile fine and crash on paint.

**Assets and fonts need a full rebuild.** Hot reload will not pick them up —
run `flutter clean` when either changes.

**Don't hand-edit files in `assets/`.** They're generated by the scripts in
`tools/`, along with their manifests in `lib/constants/`. Edit the generator and
re-run it, or the manifest and files drift apart.

**`flutter analyze` passing is not the same as working.** Every serious bug in
this project so far — invalid embeds, paint assertions, unsubscribed
observables — was invisible to static analysis. Open the screen.

---

## Roadmap

**Before launch**
- Recipe photography licensing (the placeholders are a stopgap)
- Automated database backups
- Deploy the `delete-account` Edge Function

**Next**
- On-device ingredient detection (TFLite) — the scan UI is built and waiting
- Push notifications (FCM) for submission status and replies
- `wakelock_plus` so cook mode doesn't sleep mid-recipe
- Google and Apple sign-in
- iOS and web targets

---

## Credits

- **Icons** — [Tabler Icons](https://tabler.io/icons), MIT
- **Fonts** — [Inter](https://rsms.me/inter/) and
  [Plus Jakarta Sans](https://github.com/tokotype/PlusJakartaSans), SIL Open Font License
- **Illustrations** — built for this project

---

## License

Not yet licensed. All rights reserved.
