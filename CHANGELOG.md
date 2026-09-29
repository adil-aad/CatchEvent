# Changelog

All notable changes to CatchEvent, newest first. Each heading below corresponds
to one commit, in the order the app was built (following the development order
in `Project.md` §24).

---

## Unreleased — initial implementation

### Setup decisions

Three choices were made up front, in answer to questions about the project:

| Question | Decision | Consequence |
| --- | --- | --- |
| Firebase backend | Not created yet — set up guided by docs | `FIREBASE_SETUP.md` walks through it; the app ships with a placeholder `firebase_options.dart` and shows a setup screen until `flutterfire configure` is run |
| Event images | Pasted **image URL**, not an upload | No Firebase Storage, so no Blaze (paid) plan is needed. `widgets/event_image.dart` is the only place that loads an image, so switching to Storage later is a one-file change |
| Target platform | Android emulator / device | `flutterfire configure` only needs the `android` platform |

### Dependencies

Added via `flutter pub add`:

- `firebase_core` ^4.15.0
- `firebase_auth` ^6.7.0
- `cloud_firestore` ^6.10.0
- `provider` ^6.1.5+1 — state management
- `intl` ^0.20.3 — date and time formatting

`firebase_storage` and `image_picker` were deliberately **not** added.

### `lib/utils/` — constants, validation, errors

- `constants.dart` — app name, Firestore collection names, the two role
  strings, and the eight event categories (plus `All` for the filter row).
  Also holds the `REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE` sentinel, because the
  generated `firebase_options.dart` gets overwritten and cannot own it.
- `validators.dart` — `required`, `name`, `email`, `password` (min 6),
  `capacity` (positive whole number), `imageUrl` (optional, must be http(s)).
- `app_exception.dart` — a small exception carrying a message that is already
  fit to show a user. Services throw it; providers turn it into a string for
  the UI. *(Not in the Project.md folder list; added to keep Firebase error
  handling out of the widgets.)*

### `lib/models/` — Firestore data

- `user_model.dart` — `uid`, `name`, `email`, `role`, `createdAt`.
- `event_model.dart` — the full event, plus the display helpers the UI needs
  (`shortDate`, `longDate`, `timeRange`, `isUpcoming`, `isFull`, `spotsLeft`).
  `date` is stored as `yyyy-MM-dd` and times as `HH:mm`, per the schema; ISO
  date strings sort chronologically as plain strings, so Firestore `orderBy`
  on `date` still works.
- `registration_model.dart` — links a student to an event, and copies the
  student's name and email so the organizer's list needs no extra reads.

**Added field:** `registeredCount` on the event document. Firestore cannot read
a *query* inside a transaction, only a single document — so the running total
lives on the event itself. That is what allows "event is full" to be checked
and the seat to be taken atomically. It is deliberately excluded from
`toMap()`, so an organizer editing an event can never overwrite the live count.

### `lib/services/` — all Firebase access

- `auth_service.dart` — sign up (creates the auth account *and* the
  `users/{uid}` document), sign in, sign out, profile fetch, and a mapping from
  Firebase error codes to readable messages.
- `event_service.dart` — one `events` stream ordered by date, create, update
  and delete (each ownership-checked), and the `savedEvents` bookmarks.
  Deleting an event also batch-deletes its registrations and bookmarks, so no
  orphaned rows are left behind.
- `registration_service.dart` — register and unregister inside a Firestore
  **transaction**, and the two registration streams.

Two design rules run through this layer:

1. **No composite indexes.** No query combines an equality filter with an
   `orderBy` on a different field, so the app runs against a brand-new
   Firestore database with no index setup. Small result sets are sorted in Dart.
2. **Deterministic document ids** — `registrations/{eventId}_{studentId}` and
   `savedEvents/{userId}_{eventId}`. A join row can then be read by reference
   inside a transaction, and registering or bookmarking twice is the same write
   rather than a duplicate.

`storage_service.dart` from the Project.md folder list was skipped: with URL
images there is nothing to upload.

### `lib/providers/` — state management

- `auth_provider.dart` — owns the signed-in user and an `AuthStatus`
  (`unknown` → splash, `unauthenticated` → login, `authenticated` → home).
  Subscribes to `authStateChanges`, so a restored session on launch and a
  sign-out from anywhere both route the UI on their own.
- `event_provider.dart` — a single Firestore subscription backs every event
  screen; home, Saved, My Events and the organizer list are all derived from it
  in Dart. Holds the search text and category filter. Bookmarking updates local
  state immediately and reverts if the write fails.
- `registration_provider.dart` — which events the student is registered for,
  plus per-event pending state so only the tapped button shows a spinner.

### `lib/widgets/` — shared UI

- `custom_text_field.dart`, `custom_button.dart` (inline spinner, disabled
  while loading so a form cannot submit twice), `category_chip.dart`.
- `event_card.dart` — the card from Project.md §6.
- `event_image.dart` — loads an event image URL with a placeholder for empty,
  loading and broken URLs. *(Added: the single seam for image loading.)*
- `event_list_view.dart` — `EventCardTile` (the one place a card is wired to
  provider state and the details route), plus scrolling, embedded and
  empty-state variants. *(Added: so every event list behaves identically.)*
- `event_form.dart` — the create/edit form, shared by both organizer screens
  so the fields, pickers and validation exist once. *(Added.)*

### `lib/screens/` — the screens

- `auth/login_screen.dart`, `auth/register_screen.dart` — name, email,
  password and a student/organizer segmented button. The chosen role is written
  to `users/{uid}.role`, which is what decides the home screen.
- `student/student_home_screen.dart` — bottom navigation shell plus the Home
  tab: search field, category chips, upcoming events.
- `student/event_details_screen.dart` — takes an event *id* and reads the event
  back from the provider, so the "Registered: 24 / 50" counter updates live and
  the screen reacts if the organizer deletes the event.
- `student/saved_events_screen.dart`, `student/my_events_screen.dart`
  (Upcoming / Past sections).
- `organizer/organizer_home_screen.dart` — My Events / Create Event / Profile,
  with Edit, Students and Delete on each event. "Create Event" pushes a route
  rather than being a stacked tab, so the form starts empty every time.
- `organizer/create_event_screen.dart`, `organizer/edit_event_screen.dart`,
  `organizer/registrations_screen.dart`.
- `profile_screen.dart` — account details, role-appropriate counters and log
  out. *(Project.md lists only `student_profile_screen.dart`; one screen serves
  both navigation bars instead of duplicating it.)*

### `lib/main.dart` — wiring

Firebase init, the Material 3 theme, the `MultiProvider` tree and the auth
gate. The event and registration providers are `ChangeNotifierProxyProvider`s
on `AuthProvider`, so their Firestore subscriptions start on login and are torn
down on logout.

If `flutterfire configure` has not been run, `main` detects the placeholder API
key and shows a setup screen with the commands to run — rather than crashing
with an opaque Firebase error.

### Fixes found in review

Three bugs were found and fixed while reviewing the finished code:

1. **Sign-up could sign itself back out.** Firebase signs a new account in the
   instant it is created, which fires `authStateChanges` *before* the
   `users/{uid}` profile document has been written. The auth listener would look
   up the not-yet-written profile, find nothing, and sign the brand-new account
   out. `AuthProvider` now suppresses the listener while an explicit
   sign-up/sign-in is in flight — and if one fails partway, discards the
   half-made session instead of stranding the user in an account with no
   profile.
2. **Valid image URLs were rejected.** The URL validator required
   `hasAbsolutePath`, which is false for a bare host like
   `https://example.com`. It now checks the scheme and host instead.
3. `organizer_home_screen.dart` called a `.sized()` helper that does not
   exist; replaced with a plain `SizedBox`.

### Documentation and security rules

- `FIREBASE_SETUP.md` — the console and CLI steps, a first-run walkthrough, and
  a troubleshooting table.
- `firestore.rules` — the same rules the UI enforces, enforced again on the
  server: signed-in reads only, organizer-owns-event for edit and delete,
  students able to move `registeredCount` by at most one and never past
  capacity, and private bookmarks.

### Not implemented (out of scope per Project.md §23)

Chat, payments, QR attendance, push notifications, AI recommendations,
analytics, a social feed, ticketing, maps, an admin dashboard, comments and
ratings.

### Known environment requirement

Windows needs **Developer Mode** enabled for Flutter plugin builds
(`start ms-settings:developers`). Without it the Android build fails with
*"Building with plugins requires symlink support."*
