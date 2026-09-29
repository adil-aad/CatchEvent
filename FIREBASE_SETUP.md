# Firebase Setup — CatchEvent

The app code is complete, but it needs **your own** Firebase project to talk to.
Nothing here costs money: CatchEvent uses only Authentication and Firestore,
both of which are on the free Spark plan. (There is no image upload — event
images are pasted as URLs — so Firebase Storage and the Blaze plan are not
needed.)

Work through the five steps below in order. It takes about 10 minutes.

---

## Step 0 — Enable Windows Developer Mode (one time)

Flutter plugins on Windows need symlink support. Until this is on, the Android
build fails with *"Building with plugins requires symlink support."*

```
start ms-settings:developers
```

Turn **Developer Mode** on, then reopen your terminal.

---

## Step 1 — Create the Firebase project

1. Go to <https://console.firebase.google.com> and sign in with a Google account.
2. Click **Create a project** (or *Add project*).
3. Name it `catchevent` (the console will append a suffix to make it unique —
   that is fine).
4. Google Analytics is **not** needed. Turn it off.
5. Wait for provisioning, then click **Continue**.

---

## Step 2 — Enable Email/Password authentication

1. In the left sidebar: **Build → Authentication**.
2. Click **Get started**.
3. Open the **Sign-in method** tab.
4. Click **Email/Password**, toggle **Enable**, and **Save**.

Leave "Email link (passwordless sign-in)" off — the app does not use it.

---

## Step 3 — Create the Firestore database

1. In the left sidebar: **Build → Firestore Database**.
2. Click **Create database**.
3. Choose a location near you (e.g. `eur3` or `nam5`). **This cannot be changed
   later.**
4. Start in **production mode**. The rules in `firestore.rules` (see Step 5)
   replace the defaults.
5. Click **Create**.

You do **not** need to create the `users`, `events`, `registrations` or
`savedEvents` collections by hand. Firestore creates a collection the first time
a document is written to it, so they appear as you sign up and add events.

**No composite indexes are required.** Every query in the app avoids combining
an equality filter with an `orderBy` on a different field, so a fresh database
works as-is.

---

## Step 4 — Connect the Flutter app

This generates `lib/firebase_options.dart` (replacing the placeholder that ships
with the repo) and `android/app/google-services.json`.

Run these in the project folder, `D:\CatchEvent`:

```
dart pub global activate flutterfire_cli
flutterfire configure
```

`flutterfire configure` is interactive:

| Prompt | Answer |
| --- | --- |
| Select a Firebase project | the project from Step 1 |
| Which platforms should your configuration support? | **android** only (space to toggle, Enter to confirm) |
| The Android application id | `com.example.catchevent` |

If `flutterfire` is not found, add the pub cache to your PATH:

```
setx PATH "%PATH%;%LOCALAPPDATA%\Pub\Cache\bin"
```

…then open a new terminal. If it asks you to log in first:

```
dart pub global activate firebase_cli  # only if `firebase` is missing
firebase login
```

> **Note:** `firebase login` opens a browser and must be run by you, not by an
> assistant — it needs an interactive Google sign-in. In Claude Code you can run
> it yourself by typing `! firebase login` at the prompt.

### How to tell it worked

Open `lib/firebase_options.dart`. The `apiKey` should now be a real key starting
with `AIza…` instead of `REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE`. Until then the
app deliberately shows a "Firebase is not configured yet" screen rather than
crashing.

---

## Step 5 — Publish the security rules

`firestore.rules` in the project root enforces the ownership rules server-side
(only an organizer can edit their own events, a student can only touch their own
registrations, and so on). Without it, the production-mode default denies every
read and write and the app will show "Could not load events".

**Option A — paste it into the console (easiest)**

1. **Build → Firestore Database → Rules** tab.
2. Delete what is there, paste the contents of `firestore.rules`.
3. Click **Publish**.

**Option B — deploy with the CLI**

```
firebase login
firebase use --add            # pick your project, alias it "default"
firebase deploy --only firestore:rules
```

---

## Step 6 — Run it

```
flutter pub get
flutter run
```

With an Android emulator running (or a phone connected with USB debugging on),
`flutter run` installs the app.

### First run walkthrough

1. **Sign Up** → pick **Organizer**, create an account.
2. Create an event — paste any image URL, e.g.
   `https://images.unsplash.com/photo-1540575467063-178a50c2df87`
   (or leave it empty for a placeholder).
3. **Log Out**, then **Sign Up** again as a **Student** with a different email.
4. The event appears on Home. Save it, open it, and register.
5. Log back in as the organizer and tap **Students** on the event to see the
   registration.

---

## Troubleshooting

| Symptom | Cause / fix |
| --- | --- |
| "Firebase is not configured yet" screen | Step 4 has not been run, or it wrote to a different folder. |
| "Building with plugins requires symlink support" | Step 0. |
| "Could not load events. Check your connection." | Rules not published (Step 5), or the emulator has no network. |
| `[firebase_auth/configuration-not-found]` | Email/Password was not enabled (Step 2). |
| `PERMISSION_DENIED` in the console logs | Rules not published (Step 5). |
| Build fails on `minSdkVersion` | Firebase Auth needs API 23+. Flutter 3.44 defaults to 24, so this should not happen; if it does, set `minSdk = 24` in `android/app/build.gradle.kts`. |
| Google sign-in prompts in a terminal that cannot open a browser | Run the command yourself with `!` in Claude Code, or in a normal terminal. |

---

## What gets stored where

| Collection | One document per | Key fields |
| --- | --- | --- |
| `users` | account (id = `uid`) | `name`, `email`, `role` |
| `events` | event (auto id) | `title`, `date`, `capacity`, `registeredCount`, `organizerId` |
| `registrations` | student × event (id = `eventId_studentId`) | `eventId`, `studentId`, `studentName`, `studentEmail` |
| `savedEvents` | student × bookmark (id = `userId_eventId`) | `userId`, `eventId` |

The deterministic document ids are what make "register at most once" and
"bookmark at most once" enforceable in a single transaction.
