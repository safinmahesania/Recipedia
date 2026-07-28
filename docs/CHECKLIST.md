# Recipedia — build and test checklist

Two lists. **Build** is maintained by Claude and ticked as work lands.
**Testing** is ticked only when you confirm a test has passed on a device.

Legend: `[x]` done · `[ ]` not started · `[~]` partial, see note

---

# Part 1 — Build

## 1. Foundation

- [x] Design tokens: colours, sizes, type, shadows
- [x] `ThemeExtension` wired via `context.tokens`
- [x] Light and dark themes, WCAG AA text contrast
- [x] Bundled fonts — Plus Jakarta Sans + Inter
- [x] Phosphor icon font with real fill weights for selected states
- [x] 140 ingredient and dish illustrations, three-tier fallback
- [x] Skeletons, empty states, haptics, page transitions
- [x] All `AppColors` references converted to tokens (10 legitimate left)

## 2. Database

- [x] Schema, 15 migrations
- [x] RLS on every table
- [x] `match_recipes_for_user` — staples excluded, allergens flagged
- [x] `profile_stats`, `distinct_diets`, `distinct_cuisines`
- [x] Ingredient dedup and `icon_key` / `category` backfill
- [x] Storage buckets: `recipe-images`, `avatars` (per-user folder policy)
- [x] `delete-account` Edge Function written
- [ ] `delete-account` Edge Function **deployed**
- [x] Nightly backup workflow
- [ ] Backup secret `SUPABASE_DB_URL` set, first run green
- [ ] Restore tested into a scratch project

## 3. Authentication

- [x] Login, signup, forgot password
- [x] Welcome screen
- [x] Mail-sent screen with resend cooldown
- [x] Splash routes on session and onboarding state
- [x] Login copy matches kit — "Welcome back", "Log in to pick up where you left off.", "New here?"
- [x] Signup as onboarding step 1 of 4
- [x] Password strength meter on signup
- [~] Terms and Privacy checkbox on signup — gates the button; links inert until a policy is hosted and url_launcher added
- [ ] Google sign-in — needs OAuth credentials
- [ ] Apple sign-in — needs OAuth credentials
- [x] Password reset completes — recovery event opens a set-password screen

## 4. Onboarding

- [x] Diet step with live recipe counts
- [x] Allergies step with search and common shortlist
- [x] Pantry staples step
- [x] Confirmation step with summary stats
- [x] Saves per step, not batched
- [x] Routes on null `diet_preference`
- [x] Steps labelled N of 4
- [x] Staples payoff counted against the real catalogue, not estimated

## 5. Core screens

- [x] Home — 7 sections
- [x] Recipes grid, search, filters, pagination
- [x] Recipe detail with numbered steps
- [x] Cook mode with detected timers
- [x] Scan (ingredient entry) and scan results
- [x] Saved with collections
- [x] Profile

## 6. Features

- [x] Ingredient matching, ready vs almost
- [x] Pantry staples excluded from missing
- [x] Allergy hide / warn
- [x] Shopping list, grouped by recipe
- [x] Move checked items to pantry
- [x] Meal planner with shop-for-the-week
- [x] Collections — create, assign, rename, delete
- [x] Cooking history with stats and detail badge
- [x] Reviews and ratings
- [x] Recipe submission with three photo sources
- [x] Submission tracking with filter tabs
- [x] Admin: dashboard, pending, users, reviews, reports
- [x] Edit profile — name, username, bio, avatar
- [x] Notification preferences stored
- [x] Diet and cuisine applied as filter defaults
- [ ] Automatic ingredient detection — needs a trained TFLite model
- [x] Ingredient autocomplete — ranked, alias-aware, debounced
- [ ] Push delivery — needs Firebase
- [ ] Units metric/imperial — needs quantity parsing, see BACKLOG
- [ ] Language — needs i18n extraction, see BACKLOG

## 7. Quality

- [x] CI: analyze + test on every branch
- [x] `design_system_test`
- [x] `getx_reactivity_test`
- [x] `static_safety_test` — paint asserts, escaped interpolation, icon mapping, PostgREST embeds, layering rules
- [x] `recipe_steps_test` — step splitting, timer detection, cook-time parsing
- [x] `widgets_test` — RecipeCard, AppTextField, IngredientIcon, AppIcon, skeletons
- [x] `flutter analyze` clean
- [x] Widget and unit tests — shared widgets, and the parsing that drives timers, steps and sorting
- [ ] Integration test: scan → shopping list → pantry

## 8. Release

- [ ] Recipe photography licensed
- [ ] `wakelock_plus` so cook mode stays awake
- [ ] `url_launcher` for policy links and "Open mail app"
- [ ] Privacy policy and terms hosted
- [x] App icon and splash assets — Android; iOS pending the `ios/` target
- [ ] `ios/` target
- [ ] `web/` target
- [ ] Play Store listing
- [ ] App Store listing

---

# Part 2 — Testing

Tell me the result and I tick it. `[P]` pass · `[F]` fail · `[ ]` untested.

## A. Authentication

- [ ] A1 Sign up with a new email
- [ ] A2 Confirmation email arrives; link logs you in
- [ ] A3 Resend works after the 60s cooldown
- [ ] A4 Log in with correct credentials
- [ ] A5 Log in with wrong password shows a clear error
- [ ] A6 Forgot password sends a link
- [ ] A7 Log out returns to Welcome
- [ ] A8 Killing and reopening the app keeps the session

## B. Onboarding

- [ ] B1 A new account lands on onboarding, not Home
- [ ] B2 Diet options show real recipe counts
- [ ] B3 Continue is blocked until a diet is chosen
- [ ] B4 Allergy search finds ingredients
- [ ] B5 Skip works on allergies and staples
- [ ] B6 Back preserves earlier answers
- [ ] B7 Finishing lands on Home
- [ ] B8 Reopening the app does not repeat onboarding

## C. Scan and matching

- [ ] C1 Typing an ingredient shows autocomplete
- [ ] C2 Added ingredients appear as chips
- [ ] C3 Staples row shows what was marked in onboarding
- [ ] C4 Find recipes returns results
- [ ] C5 Ready / Almost tab counts are correct
- [ ] C6 Marking salt and oil as staples moves recipes from Almost to Ready
- [ ] C7 An allergen recipe is hidden when Hide unsafe is on
- [ ] C8 Turning Hide unsafe off shows it with a warning
- [ ] C9 Pantry added in Scan appears on Home

## D. Recipes

- [ ] D1 Grid loads and paginates
- [ ] D2 Search returns sensible results
- [ ] D3 Filters apply and combine
- [ ] D4 Saved diet pre-selects on opening Recipes
- [ ] D5 Clearing that filter keeps it cleared for the session
- [ ] D6 Recipe detail loads with ingredients and steps
- [ ] D7 Ingredient illustrations render, not letter chips
- [ ] D8 Offline: a previously opened recipe still loads

## E. Cook mode

- [ ] E1 Start cooking opens on every recipe
- [ ] E2 Single-paragraph recipes still open
- [ ] E3 Steps advance and go back
- [ ] E4 A timer is offered where the step mentions a duration
- [ ] E5 Timer counts down, pauses, resets
- [ ] E6 Haptic fires at zero
- [ ] E7 Ingredients sheet opens
- [ ] E8 Done cooking opens the review screen
- [ ] E9 The cook is recorded in Cooking history

## F. Shopping and planning

- [ ] F1 Add missing from a scan result
- [ ] F2 Items group under their recipe
- [ ] F3 Checking an item is instant
- [ ] F4 Move checked to pantry empties them and updates the pantry
- [ ] F5 Add a custom item
- [ ] F6 Swipe deletes
- [ ] F7 Planner: add a recipe to a slot
- [ ] F8 Planner: week navigation
- [ ] F9 Shop for this week adds only what is missing

## G. Saved and collections

- [ ] G1 Save and unsave from detail
- [ ] G2 Saved list shows saved recipes
- [ ] G3 Create a collection
- [ ] G4 Long-press a recipe to add it to a collection
- [ ] G5 Collection filter shows only its recipes
- [ ] G6 Rename a collection
- [ ] G7 Delete a collection; its recipes stay saved
- [ ] G8 Sort and search work

## H. Profile

- [ ] H1 Stats are correct
- [ ] H2 Edit profile saves name, username, bio
- [ ] H3 Avatar upload works and persists
- [ ] H4 Diet and allergies changes apply to the next scan
- [ ] H5 Notification toggles persist across restart
- [ ] H6 Cooking history lists cooked recipes
- [ ] H7 My reviews lists and edits reviews
- [ ] H8 Theme switch persists
- [ ] H9 Delete account removes data and signs out

## I. Contribution

- [ ] I1 Submit a recipe with a gallery photo
- [ ] I2 Submit with a camera photo
- [ ] I3 Submit with a pasted URL
- [ ] I4 Submission appears as Pending
- [ ] I5 Filter tabs count correctly
- [ ] I6 Edit and resubmit a rejected recipe
- [ ] I7 Delete a submission
- [ ] I8 Post a review with rating and tags

## J. Admin

- [ ] J1 Admin portal is hidden from non-admins
- [ ] J2 Dashboard counts are correct
- [ ] J3 Pending shows meta chips and oldest first
- [ ] J4 Approve publishes the recipe
- [ ] J5 Reject sends the reason to the author
- [ ] J6 Users search and tabs work
- [ ] J7 Reports open the reported recipe
- [ ] J8 Resolve and dismiss work

## K. Cross-cutting

- [ ] K1 Every screen in dark mode
- [ ] K2 Every screen at small phone width
- [ ] K3 Every screen at large text size
- [ ] K4 Airplane mode degrades gracefully
- [ ] K5 No screen shows raw template text
- [ ] K6 Back navigation never dead-ends
- [ ] K7 Pull to refresh where present
- [ ] K8 No unbounded loading spinners

---

## Small UI fixes

Send them and they land here.

- [ ]
