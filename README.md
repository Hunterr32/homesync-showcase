# HomeSync

**A native iPhone app for sharing household chores. Built in SwiftUI with real-time sync through Firebase.**

> 📱 Status: built July–September 2026. The source code is private; this page shows the app and how it was built.

### ▶ [Try the interactive demo](https://hunterr32.github.io/homesync-demo/)

The demo shows what the app looks like on an iPhone, using made-up sample data. It is **not connected to Firebase** or any account, and **nothing you do in it is saved**.

<!-- MEDIA TODO: add an App Store / TestFlight link here once available -->
<!-- MEDIA TODO: add a 30–60 second screen recording and 3–4 iPhone screenshots to media/ (home list, dashboard calendar, room view, SyncdUp) -->

---

## The app

Everyone in a household signs in, joins the same **home** (protected by a password), and shares one live view of:

- **Rooms and their status.** A colour-coded pill shows how clean each room is, worked out from its recurring tasks.
- **A shared calendar.** It holds one-off and recurring chores, lets you move or skip a single occurrence, and filters by member.
- **Your phone's own calendar.** Events from the device calendar appear next to your household chores.
- **SyncdUp.** One view across every home you belong to.
- **Organize My Day.** Your own priorities and times for today's chores.
- **Notes per room**, with archive and restore, plus a **history** of who cleaned what.
- **Suggestions.** A built-in library of common household tasks to get a new home started quickly.

When one person marks a chore done, it appears on everyone else's phone in about a second.

## What I built

I designed and built the app and its backend rules myself.

- **SwiftUI, iOS 17+.** MVVM with real-time Firestore snapshot listeners, offline support and a network monitor.
- **Sign-in.** **Sign in with Apple** and Google Sign-In, with in-app account deletion and Apple re-authentication handled for App Store review.
- **EventKit integration.** Read-only access to the device calendar, so your existing plans appear next to your chores.
- **Backend.** Firebase Auth and Firestore. Security rules enforce home membership and the home password **on the server**, not just in the app.
- **Ownership and deletion.** The owner role passes to someone else when the creator leaves. Homes and rooms are deleted in chunked batches so no orphaned data is left behind.
- **Scheduling logic.** A "freeze the past, float the future" recurrence model: checking a chore off moves upcoming due dates without rewriting history. Cleanliness is calculated from each room's task cycle, and day-rollover edge cases are handled.

## Where it started

HomeSync began as a small **React + Firebase web app**. That first version proved the idea and shaped the data model. Its rough edges on the phone, especially sign-in from the home screen and no access to the device calendar, are why I rebuilt it as a native iPhone app. The iPhone app is now the only version.

## Tech stack

`Swift` · `SwiftUI` · `EventKit` · `Sign in with Apple` · `Google Sign-In` · `Firebase Auth` · `Cloud Firestore` · `Firestore Security Rules`

## Code sample

[`code-samples/CalendarService.swift`](code-samples/CalendarService.swift) is the read-only EventKit service that pulls device calendar events for the visible month and groups them by day. It handles multi-day and all-day events, including the classic off-by-one where an all-day event "ends" at midnight the next day.

## Architecture at a glance

```
 iPhone (SwiftUI)
   Views ─► ViewModels (ObservableObject) ─► FirestoreService ──► Cloud Firestore
                                                                   + Security Rules (membership + home password)
            AuthService ──────────────────────────────────────► Firebase Auth (Apple / Google)
            CalendarService ─► EventKit (device calendar, read-only)
```

---

© 2026 Hunter Miller. All rights reserved. See [LICENSE](LICENSE).
