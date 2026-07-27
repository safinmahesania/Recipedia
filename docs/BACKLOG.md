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
| 4 | Cooking history | `cooked_history` written by cook mode; `countFor()` on the service | Nothing reads it. No "you cooked this on 12 Jun", no history screen |
| 5 | Units, language, default cuisine | `units`, `language`, `default_cuisine` columns | No UI. Only reachable by editing the row directly |

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
