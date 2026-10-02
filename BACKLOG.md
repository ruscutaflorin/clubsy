# Backlog

Ideas beyond `TASKS.md`. The night-shift product agent appends proposals here; it never builds them.
**To queue one, change `status: proposed` to `status: approved`.** To reject, set `status: rejected`
(kept so it isn't proposed again). Built items become `[x] … status: done`.

```
- [ ] B<n> Title — status: proposed | approved | rejected
  - Why / Scope / Acceptance / Size
```

---

The full product roadmap agreed with the user before Phase 1 was scaffolded (see
`C:\Users\ruscu\.claude\plans\tingly-exploring-hickey.md` for the original planning context).
B1-B5 failed as single night-shift items because each is several features in one and most need
schema changes. Each one now has a **path forward** that names the `TASKS.md` tasks it was split
into, and what it still waits on. They stay `[!]` so the supervisor doesn't retry them whole. Build
them through the listed tasks instead. See `PLAN.md` "Roadmap" and "Open product decisions".

- [!] B1 Gamification: visit streaks, weekly challenges, points balance — status: approved <!-- failed 2026-10-01: BLOCKED: no database available — B1 needs a schema change and `prisma migrate dev`, and it is also too large for a single task. -->
  - Why: core retention loop once check-in itself works.
  - Scope: a `Streak`/points-balance concept on `User` or a new `UserStats` model, computed from
    `CheckIn` history (consecutive nights/weeks with a check-in); a handful of static weekly
    challenges (e.g. "check in at 3 different clubs this week"); a read-only points balance only —
    no spending yet, that's B4.
  - Acceptance: a user can see their current streak and challenge progress in the app; points
    accrue from check-ins and challenge completions.
  - Size: likely 4-6 tasks (schema, backend computation, Flutter UI).
  - Path forward (2026-10-01): split **computed-first**, with no schema needed. TASKS 6.1 (server
    engine: weekly streak, badge catalogue, weekly challenges, display-only points), 6.2 (Flutter
    achievements page, unlock moment after a check-in) and 6.3 (monthly/yearly recap share card).
    The persisted ledger is 7.8, and only once B4 decides what points buy. Streaks are **weekly**,
    not nightly: a nightly streak would reward going out every night, which is the wrong incentive
    for a nightlife app, and weekly matches how regulars actually behave.

- [!] B2 Ratings: post-visit behavior ratings between users — status: approved <!-- failed 2026-10-01: BLOCKED: no database available. B2 needs a new `Rating` model, and the project rules require adding it with `npx prisma migrate dev`, which needs a live Postgre... -->
  - Why: requested as a safety/quality signal for who you'll meet at a club.
  - Scope: a `Rating` model (rater, ratee, optional note, 1-5 score), only submittable between two
    users who checked into the same club on the same night; an average rating surfaced on profile.
  - Acceptance: after a shared check-in window closes, both users can rate each other once; the
    average shows on the rated user's profile.
  - Size: likely 4-5 tasks.
  - Path forward (2026-10-01): **venue** ratings come first, with less risk and immediate value:
    TASKS 7.4 (a private vibe rating per check-in) and 7.5 (an aggregate club score with a k >= 5
    threshold). Person-to-person ratings need a design answer to "how did you meet this person?".
    Sharing a club and a night isn't enough: it would let anyone rate any stranger who was at the
    same club, which is a harassment vector. Recommended prerequisite: B3 matches or 8.1 friends,
    so only people who interacted can rate each other. Also needed: 8.2 block/report, a rule that
    ratings below 3 need a reason category, an appeal path, and showing averages only from 5+
    raters. Re-scope after Phase 8.

- [!] B3 Matching: Tinder-style swipe/match between users checked into the same club/night — status: approved <!-- failed 2026-10-01: BLOCKED: B3 needs a dedicated design and privacy pass first, and its schema migration needs a live database (no database available). -->
  - Why: the original pitch's "algorithm similar to Tinder" for clubgoers.
  - Scope: a swipe/like/match model scoped to users who share a current or recent check-in at the
    same club; a match unlocks some form of contact (chat is out of scope unless separately
    proposed). Needs its own privacy pass (who's shown to whom, consent, blocking/reporting) before
    being built, not just a schema.
  - Acceptance: TBD pending a dedicated design pass — this is a bigger feature than the others and
    should get its own planning round, not a single task list.
  - Size: large; likely needs its own plan, not just backlog tasks.
  - Path forward (2026-10-01): needs Phase 8 (friends, block/report, privacy settings) and 7.1
    (usernames, age confirmation). Questions for the design round: (1) Opt-in per night ("I'm open
    to meeting people tonight"), not a standing profile flag. (2) Who appears in the deck: only
    other opted-in users checked into the same club **tonight**. Never show their check-in time,
    and never show anyone after they leave or after 06:00. (3) What a match unlocks: recommended
    is exchanging usernames to add as friends (8.1), so in-app chat isn't needed for v1. (4) Photos
    need image upload, storage and moderation, which is a separate project. (5) Abuse controls:
    rate limits on likes, report from the deck, 18+ enforced (7.1). (6) App store category and
    age-rating impact. Write the answers here, then split into tasks.

- [!] B4 Points economy & subscriptions — status: approved <!-- failed 2026-10-01: BLOCKED: B4's acceptance criteria are "TBD" and what's being sold (perks, cosmetics, partner discounts, subscription tiers) hasn't been decided. It also require... -->
  - Why: monetization + a sink for the points balance from B1.
  - Scope: ways to spend accumulated points (perks, cosmetic profile features, club-partner
    discounts — TBD with the business side); subscription tiers on top. Reintroduce a Stripe
    integration following `timeit`'s `server/src/services/stripeService.js` as the implementation
    pattern (that file was deliberately not carried into this repo — Phase 1 has no payments).
  - Acceptance: TBD — needs a decision on what's actually being sold before tasks can be written.
  - Size: large.
  - Path forward (2026-10-01): recommended order is **venue-side revenue first** (B24 venue
    insights, B25 venue perks), because clubs pay for verified footfall and regulars, and the
    consumer app stays free during growth. Consumer points then get a real sink through B25 perks
    ("500 points = free entry before midnight at Club X"), funded by the venue, not by Clubsy. A
    consumer subscription waits until there are premium features worth paying for (e.g. unlimited
    recap history, custom map themes, advanced stats). Note that iOS/Android digital
    subscriptions must use in-app purchase, not Stripe, so the timeit Stripe pattern only fits
    venue billing. Decision needed from the user: PLAN.md open decision 6.

- [!] B5 Live presence map ("who's out tonight") — status: approved <!-- failed 2026-10-01: BLOCKED: B5 has no defined acceptance criteria or safety/blocking design, and the project rules forbid building the presence map without an explicit scope. -->
  - Why: the original "Snapchat map" pitch. **Deferred deliberately** for real safety reasons
    (stalking/unwanted-contact risk in a nightlife context), not because it's low value.
  - Scope, non-negotiable before any build: opt-in per session (not a standing setting), visible
    only to mutual friends/matches (never broadcast more broadly by default), auto-expires a few
    hours after the session ends. Do not approve a version of this that skips any of the three.
  - Acceptance: TBD — needs its own design/safety review pass when the time comes, including how
    blocking/reporting interacts with it.
  - Size: large; requires realtime infrastructure (websockets or similar) not present in Phase 1.
  - Path forward (2026-10-01): a stepping stone that delivers most of the value with less risk is
    TASKS 8.4 (a friends' nights feed shown only **after** the night ends), then "friends here
    tonight" counts at **club level** only ("2 friends checked in here tonight", no names unless
    each friend opted in for that night). Club-level presence needs no realtime infrastructure:
    it's a query on tonight's check-ins plus the opt-in flag, refreshed on pull. A true live map
    only comes after those prove safe in the pilot. The three non-negotiables above still apply to
    every step.

- [x] B6 Stop exposing club `qrSecret` to non-admin clients — status: done
  - Why: `GET /api/clubs` and `GET /api/clubs/:id` return the full `Club` row, including `qrSecret`, to any signed-in user. Anyone can then build a valid QR payload and check in remotely with spoofed GPS, which breaks the "QR scanned on-site" half of the check-in promise.
  - Scope: in `server/src/controllers/clubController.js`, leave `qrSecret` out of `getClubs`/`getClubById` responses for non-admins (Prisma `omit`/`select`, or a small `toPublicClub` helper). Also make `getClubById` return 404 to non-admins for unapproved clubs, the same way `checkIn` treats them. `createClub` (admin-only) still returns the secret and `qrCode`. No schema change. Client `ClubModel` must keep parsing when `qrSecret` is absent; confirm it doesn't read the field. Out: rotating secrets that have already leaked (see B10).
  - Acceptance: a Jest test with a mocked Prisma client shows the controller response for a USER role has no `qrSecret`, on both the list and the single-club route; an ADMIN still sees it; a non-admin asking for an unapproved club gets 404. `pnpm test` passes.
  - Size: S

- [x] B7 Make the Express app importable and add route-level tests with mocked Prisma — status: done
  - Why: every server feature so far has stalled because nothing can be verified without Postgres. If the controllers can be tested without a database, check-in rules (QR + 150m) and auth can be verified on every night shift.
  - Scope: split `server/src/index.js` into `server/src/app.js`, which builds and exports the `app`, and `index.js`, which only calls `listen`. Add `supertest` as a devDependency. Mock `server/src/prisma/client.js` with Jest ESM module mocking (`jest.unstable_mockModule`, or whatever fits the current `"type": "module"` + Jest setup). Cover `POST /api/check-ins`: success, wrong QR, too far (>150m), unapproved club, missing auth. Cover `GET /api/check-ins/me`. No real DB and no schema change.
  - Acceptance: `cd server && pnpm test` runs the new supertest suites without `DATABASE_URL`. The suite asserts 201 for valid QR within 150m, 400 for a bad QR, 400 with `distanceMeters` when too far, and 401 without a token. Importing `app.js` does not open a port.
  - Size: M

- [x] B8 Prevent duplicate check-ins at the same club on the same night — status: done
  - Why: right now a user can scan the same QR repeatedly and inflate their history. Once B1 (streaks/points) lands, that's a direct exploit, and today it already clutters the personal history.
  - Scope: in `checkInController.checkIn`, before `prisma.checkIn.create`, look up an existing `CheckIn` for the same `userId` + `clubId` within a "night" window. Define the window in one exported helper, e.g. `server/src/utils/night.js`: a night runs 06:00 to 06:00 so that 2am counts as the previous evening (UTC for now; note that in NOTES). If one exists, return `409 {message}`. No schema change: query by `checkedInAt` range using the existing `@@index([userId])`. Client: `CheckInPage` shows the 409 message as-is. Out: per-club timezones.
  - Acceptance: unit tests for the night-window helper (23:00 and 02:00 the next day fall in the same night; 07:00 starts a new one). A controller test (mocked Prisma, building on B7 or using a standalone mock) returns 409 on a second check-in in the same window and 201 at a different club. `pnpm test` passes.
  - Size: S

- [x] B9 Personal map stats: clubs visited, cities, total check-ins on Profile — status: done
  - Why: the product promise is "build a personal map of places you've visited". A summary (N clubs across M cities, most-visited club, first check-in date) makes that progress visible without the B1 gamification schema.
  - Scope: server `GET /api/check-ins/me/stats` in `checkInController.js` and `checkInRoutes.js` (register it before any `/:id`-style routes). It uses Prisma `groupBy`/`findMany` on existing `CheckIn` + `Club` data to return `{totalCheckIns, uniqueClubs, uniqueCities, mostVisitedClub, firstCheckInAt}`. Put the aggregation in a pure function (e.g. `server/src/services/statsService.js`) so it can be unit-tested. Client: add `getMyStats()` to `check_in_service.dart`, a `CheckInStatsModel` in `client/lib/data/classes/`, a stats field in `ClubController`, and a small stats card on `ProfilePage`. No schema change.
  - Acceptance: Jest unit tests for the pure aggregation function (empty history, several clubs in two cities, ties for most visited). A Flutter widget test renders the `ProfilePage` stats card from a fixture `CheckInStatsModel` with no HTTP. `pnpm test` and `flutter test` pass.
  - Size: M

- [x] B10 Admin: re-fetch and rotate a club's venue QR — status: done
  - Why: the venue QR is only returned once, from `createClub`. If a printout is lost there's no way to get it again, and if a secret leaks (B6 shows the risk is real) there's no way to invalidate it, which undermines check-in verification.
  - Scope: `GET /api/clubs/:id/qr` returns `{qrCode}` via `generateClubQr`. `POST /api/clubs/:id/qr/rotate` sets a new `generateQrSecret()` and returns the new `{qrCode}`. Both are admin-only (`adminMiddleware`), in `clubController.js`/`clubRoutes.js`. No schema change: `qrSecret` already exists and is unique. Client admin UI is out of scope (no admin screens exist yet). It needs its own item if wanted.
  - Acceptance: controller tests with mocked Prisma: a non-admin gets 403; an admin gets a data-URL `qrCode`; after rotation, `verifyClubQrPayload` rejects the old payload and accepts the new one. `pnpm test` passes.
  - Size: S

- [x] B11 Validate signup/signin input and fail safely without `JWT_SECRET` — status: done
  - Why: `authRoutes.js` is the only route file without `express-validator`. A signup with a missing email, a blank name or a 1-char password goes straight to Prisma and comes back as a generic 500, or creates a weak account. Every check-in and personal-map feature starts at this door, so it should be validated like the others.
  - Scope: add `signUpValidation` (`email` isEmail + normalizeEmail, `password` min length 8, `name` notEmpty + trim) and `signInValidation` (`email`, `password` notEmpty) in `server/src/routes/authRoutes.js`, following `clubRoutes.js`. Add the `validationResult` → `400 {errors}` guard to `signUp`/`signIn` in `authController.js`, following `clubController.createClub`. If `process.env.JWT_SECRET` is unset, return `500 {message}` before calling `jwt.sign`, and never issue a token. Client: make `auth_service.dart` show the first `errors[].msg` when `message` is absent. No schema change. Out: password reset, refresh tokens, rate limiting.
  - Acceptance: Jest tests with mocked Prisma (same pattern as `checkInController.test.js`): a bad email, a short password or a missing name gets 400 `{errors}` and `prisma.user.create` is never called; a valid signup gets 201 with a token; with `JWT_SECRET` unset, signin gets 500 and no token. `pnpm test` passes.
  - Size: S

- [x] B12 Show why a check-in failed, including how far away the user is — status: done
  - Why: the check-in is the product's core action. When it fails, `check_in_service.dart` only reads `message`. Validation failures (`{errors}`) show as a bare "Failed to check in", and the server's `distanceMeters` on a too-far response is thrown away. Users can't tell whether to walk closer, rescan, or give up.
  - Scope: in `client/lib/services/check_in_service.dart`, parse error bodies into a small `CheckInException` class (message, optional `distanceMeters`, optional field errors), put in the same file or `client/lib/data/classes/`. Keep the parsing in a pure function, e.g. `CheckInException.fromResponse(int status, String body)`, so it can be tested. `CheckInPage` shows "You're ~420 m away — get within 150 m of the entrance" when `distanceMeters` is present, and the first field error otherwise. Do not compute or enforce distance on the client: the server stays authoritative and the QR + 150 m rule is unchanged. No server change.
  - Acceptance: Flutter unit tests for the parser: a 400 with `distanceMeters` gives a message containing the rounded metres; a 400 `{errors:[{msg}]}` gives that msg; a 404 `{message}` gives the message; a non-JSON body gives a generic fallback. `flutter test` and `flutter analyze --no-fatal-infos` pass.
  - Size: S

- [x] B13 Visit summary on ClubDetailsPage ("3 visits · last on 12 Sep") — status: done
  - Why: the personal map is the product's promise. Today a club page only shows a "Checked in before" chip. Showing how often and when the user was there makes each pin feel like part of their own history. All the data is already on the client.
  - Scope: add a pure helper (e.g. `visitSummaryFor(String clubId, List<CheckInModel>)` returning count, first visit and last visit) next to `ClubController` or in `client/lib/data/classes/`. Expose it from `ClubController`, and replace or extend the chip in `client/lib/views/pages/club_details_page.dart` with "N visits · last on <date>" (first-visit date as secondary text). The page must keep rendering when there are no visits. Client-only: no server or schema change. Out: other users' visit counts (that's social, needs its own privacy item).
  - Acceptance: unit tests for the helper (no visits, one visit, several out of order so it picks the latest correctly, other clubs ignored). A widget test pumps `ClubDetailsPage` with a fixture club and a `ClubController` that has preset `myCheckIns`, with no HTTP, and finds the "3 visits" text. `flutter test` passes.
  - Size: S

- [x] B14 Personal-map filter and framing: "Visited only" toggle and fit map to my clubs — status: done
  - Why: `ClubMapPage` shows every approved club and centres on the first club in the list, so the user's own map gets lost among clubs they haven't visited. A visited-only view, framed around where they've been, is the "personal map of places you've visited" in its plainest form.
  - Scope: in `client/lib/views/pages/club_map_page.dart`, add a small overlay toggle (All / Visited) backed by an `RxBool` on `ClubController`. Pull the marker selection into a pure function `clubsForMap(clubs, visitedIds, visitedOnly)` and a pure `boundsFor(List<ClubModel>)` that returns null when the list is empty. Use flutter_map's `CameraFit.bounds` when bounds exist, otherwise keep `_defaultCenter`. Show an empty-state hint ("No check-ins yet") when visited-only is on and nothing has been visited. Client-only: no server change. Out: device-location centring and clustering.
  - Acceptance: unit tests for `clubsForMap` (both modes, none visited) and `boundsFor` (empty → null, one club, several clubs → correct SW/NE). A widget test toggles to Visited with a fixture `ClubController` and checks the empty-state text when nothing has been visited. `flutter test` passes.
  - Size: S

- [x] B15 Club search and city filter screen — status: done
  - Why: users can only find a club by panning the map. `GET /api/clubs` already supports `search` and `city`, and `ClubService.getClubs({search, city})` already sends them, but no UI uses them. Finding the venue you're standing outside of is the first step of every check-in.
  - Scope: new `client/lib/views/pages/club_search_page.dart`, pushed with `Get.to()` from a search action in `ClubMapPage` (not a new nav tab). A debounced text field calls `ClubService.getClubs(search:)`. Each result tile shows name, city and a visited marker from `visitedClubIds`, and tapping it opens `ClubDetailsPage`. Keep the results state in a small `ClubSearchController` (GetX) that takes an injectable fetch function, so tests need no HTTP. Server: in `clubController.getClubs`, clamp `page`/`limit` to positive integers with `limit` ≤ 50, because today a non-numeric `limit` produces `NaN` in `skip`/`take`. Cover that with a mocked-Prisma Jest test. No schema change.
  - Acceptance: Jest: `limit=abc` and `limit=1000` call `findMany` with `take` 20 and 50 respectively. Flutter: a controller test with a fake fetch shows the query is forwarded and the results are exposed. A widget test renders fixture results and marks the visited one. `pnpm test` and `flutter test` pass.
  - Size: M

- [ ] B16 Check-in history grouped by night with readable dates — status: promoted → TASKS.md 3.5 (build it from TASKS.md, not from here)
  - Why: `CheckInHistoryPage` prints a raw `DateTime.toLocal()` string (`2026-09-12 01:34:56.000`) in one flat list. The history is the text view of the personal map, so it should read as a diary of nights out ("Sat 12 Sep · 2 clubs"), not a debug log.
  - Scope: client-only. Add pure helpers (e.g. `client/lib/data/classes/check_in_grouping.dart`): `nightOf(DateTime local)` (a night runs 06:00 to 06:00, so 02:00 belongs to the previous evening; this matches the window proposed in B8) and `groupByNight(List<CheckInModel>)`, which returns ordered groups, newest first. Add a hand-rolled `formatNightLabel` / `formatTime` so `intl` isn't needed. In `check_in_history_page.dart`, render a section header per night ("Sat 12 Sep · 2 clubs") with tiles showing the club name, city and `HH:mm`. Keep the existing empty state and pull-to-refresh. Out: server changes and filtering.
  - Acceptance: unit tests show that 23:00 and 02:00 the next day end up in one group while 07:00 starts a new one, that groups and the items inside them are ordered newest first, and that the label format is right. A widget test pumps `CheckInHistoryPage` with fixture `myCheckIns` across two nights and finds both headers and an `HH:mm` time. `flutter test` and `flutter analyze --no-fatal-infos` pass.
  - Size: S

- [ ] B17 Check-in success moment: "New place on your map!" vs "Visit #N" — status: promoted → TASKS.md 3.6 (build it from TASKS.md, not from here)
  - Why: a successful check-in, the product's core action, currently ends with a generic snackbar and `Get.back()`. Calling out a first visit, which adds a new pin to the map, rewards the behaviour the product is built on, without needing the B1 gamification schema.
  - Scope: client-only. In `ClubController.checkIn`, return the created `CheckInModel` and update `myCheckIns`/`visitedClubIds` locally if it doesn't already. Add a pure `checkInOutcome(clubId, previousCheckIns)` that returns `{isFirstVisit, visitNumber, totalClubsVisited}`, computed before the new record is added. In `CheckInPage`, swap the snackbar for a small confirmation dialog or bottom sheet ("New place on your map! That's 7 clubs." / "Visit #3 at Club X") with a "View on map" button that pops back. Server, QR and GPS rules are unchanged. Out: points, streaks and sharing.
  - Acceptance: unit tests for `checkInOutcome` (no history gives first visit and total 1; two earlier visits to the same club give visit #3; visits to other clubs only change the total). A widget test renders the confirmation widget from a fixture outcome and finds the first-visit text. `flutter test` passes.
  - Size: S

- [ ] B18 Handle expired or invalid sessions: on 401, sign out and return to login — status: promoted → TASKS.md 3.4 (merged with startup session validation) (build it from TASKS.md, not from here)
  - Why: JWTs expire, and when one does, every call in `club_service.dart`/`check_in_service.dart` fails with a generic "Failed to …" error. The map and history then look empty or broken, with no way back except reinstalling or logging out by hand.
  - Scope: client-only. Add a small shared helper (e.g. `client/lib/services/api_response.dart`) with `bool isUnauthorized(int status)`, plus an injectable `onUnauthorized` callback registered by `AuthController`. That callback calls `signOut()` and `Get.offAllNamed('/login')`, with a "Session expired, please sign in again" snackbar. `ClubService` and `CheckInService` call the helper before their existing status checks. Keep the services constructible with an injectable `http.Client` (or equivalent) so the behaviour can be tested with `MockClient` from `package:http/testing.dart`. Out: refresh tokens and server changes.
  - Acceptance: tests using `MockClient` show that a 401 from `getClubs` and from `getMyCheckIns` invokes the `onUnauthorized` callback exactly once and throws, and that a 200 does not invoke it. A controller test shows the registered callback clears the stored token. `flutter test` and `flutter analyze --no-fatal-infos` pass.
  - Size: S

- [ ] B19 Delete my account and my check-in history — status: promoted → TASKS.md 5.3 (build it from TASKS.md, not from here)
  - Why: Clubsy stores a timestamped history of where a user goes at night, which is sensitive location data. Users need a way to erase it, and the App Store and Play require in-app account deletion before the app can ship.
  - Scope: server: `DELETE /api/auth/me` (authMiddleware) in `authController.js`/`authRoutes.js`. It requires the current `password` in the body (bcrypt compare), validated with `express-validator`. It then runs `prisma.$transaction([checkIn.deleteMany({where:{userId}}), user.delete({where:{id}})])` and returns 204. The last remaining ADMIN account can't be deleted (409). No schema change. Client: `deleteAccount(password)` in `auth_service.dart`, and a "Delete account" tile on `ProfilePage` with a confirm dialog and password field; on success it signs out and goes to `/login`. Out: data export and a soft-delete grace period. The human may want to review the wording of the confirm dialog.
  - Acceptance: Jest tests with mocked Prisma: a wrong password gets 401 and `$transaction` is never called; a correct password gets 204 and `$transaction` is called with the check-in delete before the user delete; with no token it gets 401. A Flutter widget test shows that the Profile tile opens a confirm dialog containing a password field. `pnpm test` and `flutter test` pass.
  - Size: M

- [ ] B20 Remove a single check-in from my map — status: promoted → TASKS.md 5.4 (build it from TASKS.md, not from here)
  - Why: a personal map is only personal if the user controls it. Someone may want to drop a visit they'd rather not keep (a bad night, a place they don't want on their record) without deleting their whole account (B19).
  - Scope: server: `DELETE /api/check-ins/:id` in `checkInController.js`/`checkInRoutes.js`. It looks the row up by id, returns 404 if it doesn't exist or `userId !== req.user.id` (don't leak whether other users' check-ins exist), and otherwise deletes it and returns 204. No schema change. Client: `deleteCheckIn(id)` in `check_in_service.dart`. `ClubController.removeCheckIn(id)` updates `myCheckIns` and recomputes `visitedClubIds`, so a club's pin goes back to unvisited once its last check-in is removed. Swipe-to-delete with a confirm on `CheckInHistoryPage`. Out: undo and admin moderation.
  - Acceptance: Jest tests with mocked Prisma: the owner gets 204 and `checkIn.delete` is called; another user's check-in gets 404 and no delete happens; an unknown id gets 404. A Flutter controller test with a fake service shows that removing a club's only check-in drops it from `visitedClubIds`, while removing one of two keeps it. `pnpm test` and `flutter test` pass.
  - Size: S

---

Product-owner proposals, 2026-10-01. These sit beyond the pilot scope in `TASKS.md` Phases 2-8.
Most need a human decision or an external account first, as noted in each item. Approve the ones
you want, and they'll be split into `TASKS.md` tasks.

- [ ] B21 Push notifications, opt-in and granular — status: proposed
  - Why: the strongest retention lever for a weekly habit. Examples: "Keep your 3-week streak
    going: one night out this week does it" (Thursday 18:00 local), "Your September recap is
    ready", "How was Club X last night?" (the 7.4 vibe prompt), and friend requests (8.1).
  - Scope: Firebase Cloud Messaging (Android plus APNs through FCM). A `DeviceToken {userId, token,
    platform, updatedAt}` model. Per-category toggles in Profile, all off until the user opts in
    on a primer screen, never on first launch. A server `notificationService.js` with an
    injectable sender and a daily job runner (host cron hitting an admin-only endpoint).
    Quiet hours: nothing between 02:00 and 10:00 local.
  - Needs: a Firebase project and APNs key (human), and 7.0 for the schema.
  - Acceptance: a user who enabled only streak reminders gets only those; no notification ever
    contains another user's name or location.
  - Size: L (2-3 tasks).

- [ ] B22 Crash reporting and privacy-safe product analytics — status: proposed
  - Why: during the pilot we're blind to crashes on real devices and to where users drop off
    (signup → first check-in → second night). The `PLAN.md` metrics from the server (4.3) cover
    outcomes, not funnels or crashes.
  - Scope: Sentry for Flutter and Node (DSN from env, `sendDefaultPii: false`, scrub request bodies
    and coordinates). A tiny analytics wrapper with about 10 named events (`signup_completed`,
    `checkin_scan_started`, `checkin_failed{reason}`, `checkin_succeeded{firstVisit}`,
    `recap_shared`, and so on), never carrying coordinates, club names or user ids in clear text.
    Send them to a privacy-friendly tool (e.g. PostHog EU or self-hosted) behind a consent toggle
    that defaults to off where the law requires it.
  - Needs: accounts or DSNs (human), and an update to the privacy policy (5.7).
  - Acceptance: a forced test crash shows up in Sentry with a release tag; the event schema is
    documented in `docs/analytics.md`; a unit test shows events contain no lat/lng keys.
  - Size: M.

- [ ] B23 Localization: English and Romanian (or the pilot market's language) — status: proposed
  - Why: if the pilot city is in Romania (the test fixtures sit at 45°N 25°E), a native-language
    UI noticeably improves signup conversion, and the legal copy has to be in the local language
    anyway.
  - Scope: `flutter_localizations` + `intl` with ARB files, extract every user-facing string, and
    locale-aware dates (this replaces the hand-rolled formatters from 3.5). The server keeps
    English `message` text but adds a stable `code` (e.g. `CHECKIN_TOO_FAR`) to every error so the
    client can show localized text. Add a language override in Profile.
  - Acceptance: a widget test pumps key pages in both locales, and no user-facing string literals
    remain outside the ARB files (spot-checked in review).
  - Size: M-L.

- [ ] B24 Venue partner portal: verified footfall insights for clubs (the first revenue path) — status: proposed
  - Why: venues get real value from verified, de-duplicated visit data (how many unique guests,
    how many came back, which nights work), and they can pay for it. This funds a free consumer
    app (see B4's path forward).
  - Scope: a `VENUE_MANAGER` role and a `ClubManager {userId, clubId}` relation. Admins assign
    managers. Endpoints scoped to the managed club: check-ins per night (last 12 weeks), unique
    visitors, a returning-visitor rate, a hour-of-night histogram, and the share of first-time
    visitors. **All aggregates use k-anonymity ≥ 5** and never return user identities. Managers
    can also view and rotate their own QR and display link (TASKS 6.4). Build it as an in-app section
    first; a web dashboard can come later.
  - Needs: open decision 6 (monetization) and 7.0.
  - Acceptance: a manager of club A gets 403 on club B; any bucket with fewer than 5 users is
    suppressed; no response contains user ids.
  - Size: L (3-4 tasks).

- [ ] B25 Venue perks for regulars — status: proposed
  - Why: gives check-ins and points a real-world payoff ("your 5th visit: free entry before
    midnight") that venues fund, and gives venues a reason to promote Clubsy at the door, which is
    the best acquisition channel there is.
  - Scope: a `Perk {clubId, title, rule: {type: VISIT_COUNT|POINTS, threshold}, activeFrom,
    activeTo, maxPerUser}` model and `PerkRedemption`. Users see the perks they've unlocked on the
    club page. Redemption shows a 60-second one-time code that staff validate in the venue manager
    view (B24). Abuse: one redemption per perk per night, and codes are bound to the user and the
    night.
  - Needs: B24 and 7.8 (points ledger, if perks cost points).
  - Size: L.

- [ ] B26 "Suggest a club" from users, with admin review — status: proposed
  - Why: in a new city the club list is the product's biggest gap. Users standing outside an
    unlisted venue are the best source of new venues, and each suggestion is a sales lead for B24.
  - Scope: a `ClubSuggestion {userId, name, address, city, lat, lng, note, status, createdAt}`
    model. A "Club missing? Suggest it" entry in search results and on an empty map. Rate-limit to
    5 per user per day. An admin queue in the console (Phase 4) where approving pre-fills the 4.2
    create form. Notify the suggester when their club goes live (B21).
  - Size: M.

- [ ] B27 Enforce rotating-only QR per club — status: proposed
  - Why: TASKS 6.4 accepts both the static and the rotating payloads so printed QRs keep working.
    Once a venue has a display screen running, its static QR should stop working.
  - Scope: `Club.qrMode enum(STATIC, ROTATING) @default(STATIC)`, an admin/manager toggle with a
    warning, and `verifyClubQrPayload` respecting the mode. The metrics (4.3) show the static vs.
    rotating mix.
  - Size: S (after 6.4 and 7.0).

- [ ] B28 Production map tiles, marker clustering and a dark map style — status: proposed
  - Why: `ClubMapPage` uses `tile.openstreetmap.org`, and OSM's tile usage policy doesn't allow
    heavy production use, so it has to change before a public launch. A city with 50+ clubs also
    becomes an unreadable cluster of pins, and the bright default tiles clash with a nightlife app
    that's mostly used at night.
  - Scope: a tile provider with an API key from `--dart-define` (e.g. MapTiler or Stadia; a human
    picks it and creates the account), a dark style by default with light style following the app
    theme, correct attribution, `flutter_map_marker_cluster` with visited/unvisited counts per
    cluster, and tile caching for basements with poor signal.
  - Size: M.

- [ ] B29 Visual identity pass: brand, typography, icon, splash and empty-state art — status: proposed
  - Why: the app still carries timeit's look (teal on navy, a carried-over Lottie animation, and
    `fontFamily: 'Poppins'` in `client/lib/data/constants.dart` with no font bundled in
    `pubspec.yaml`, so it silently falls back). Recap cards (6.3) are shared publicly, so the brand
    is visible outside the app too.
  - Scope: a design decision first (palette, type, logo; human or designer). Then bundle the fonts,
    centralise the theme in `client/lib/src/core/theme/app_theme.dart` (remove the duplicate theme
    in `constants.dart`), app icons via `flutter_launcher_icons`, a splash via
    `flutter_native_splash`, badge artwork for 6.2, and illustrations for empty states.
  - Size: M (after the design input).

- [ ] B30 Deep links and shareable club pages — status: proposed
  - Why: shares from 6.3 recaps, 6.5 club shares and B26 should open the app at the right club, or
    show a web page with store links when the app isn't installed, which turns every share into
    an install path.
  - Scope: a domain (open decision 2), Android App Links and iOS Universal Links for `/c/:clubId`,
    and a small server-rendered public club page (name, city, photo, "Get Clubsy"). It must never
    show visitor counts below k = 5 or any user data. GetX route handling for the incoming link.
  - Size: M.

- [ ] B31 Sign in with Apple and Google — status: proposed
  - Why: signup friction at a club entrance is high (typing an email and password on a phone in
    the dark). One-tap sign-in raises activation, which is our first pilot metric.
  - Scope: `google_sign_in` and `sign_in_with_apple`. The server verifies ID tokens and links them
    to a `UserIdentity {provider, subject}` model, with email matching only for verified emails.
    Apple's guideline requires Sign in with Apple if Google sign-in is offered on iOS. The 5.1
    consent checkboxes still apply.
  - Needs: Apple developer and Google Cloud console setup (human), and 7.0.
  - Size: M-L.

- [ ] B32 Accessibility pass — status: proposed
  - Why: the map and the camera scanner are the core flows, and both are unusable with a screen
    reader today (markers are bare icons, and status messages aren't announced).
  - Scope: `Semantics` labels on map markers ("Club X, visited 3 times"), a list alternative to the
    map (the B15 search covers part of this), live-region announcements for check-in status, 4.5:1
    contrast on the dark theme, layouts that survive 200% text scale, and tap targets of at least
    48 px.
  - Acceptance: `flutter test` with `meetsGuideline(textContrastGuideline)` and
    `androidTapTargetGuideline` on the main pages.
  - Size: S-M.

- [ ] B33 "How busy is it tonight?" on club pages (aggregate only) — status: proposed
  - Why: the most-asked question before going out. Verified check-ins answer it honestly, without
    revealing anyone.
  - Scope: club responses get `tonight: "quiet" | "getting busy" | "packed" | null`, bucketed from
    distinct check-ins in the current night relative to that club's own 8-week median. It's `null`
    below 5 check-ins tonight (k-anonymity), and the exact count is never exposed. No schema change.
  - Safety note: this is aggregate venue data, not presence of people. It's allowed under the B5
    principles because no individual can be inferred. Keep the threshold.
  - Size: S.

- [ ] B34 Integration tests against a real Postgres — status: proposed
  - Why: the mocked-Prisma tests can't catch query bugs (wrong `where` shape, missing `include`,
    transaction order, unique-constraint behaviour), and Phase 7 adds a lot of real queries.
  - Scope: after 7.0, a `pnpm test:int` suite that runs `prisma migrate reset --force` against the
    docker database, seeds it with 2.5's `buildSeedClubs`, and runs the key flows over supertest
    (signup → check-in → stats → delete account). Add it to CI (2.6) with a Postgres service
    container. Keep the night-shift gate on the unit suite unless the service is reliable.
  - Size: M.

- [ ] B35 Check-in data retention — status: proposed
  - Why: keeping precise visit history forever is a liability. A clear retention rule (decided in
    5.7) is also a selling point ("we keep your history only as long as you want").
  - Scope: depends on the legal decision. Options: (a) keep it forever but let the user set
    auto-delete after 1 or 2 years; (b) drop `distanceMeters` and coarsen `checkedInAt` to the
    night date after 90 days (the map and history still work; precise times go). A scheduled job
    endpoint (admin-only, triggered by host cron), plus tests on fixed dates.
  - Size: S-M.

---

Product-owner proposals, 2026-10-02. Schema-free follow-ups to Phases 3-6.

- [x] B36 Reject physically impossible check-in sequences ("impossible travel") — status: done
  - Why: "every pin is verified" is the product's first principle. GPS spoofing that slips past the mock-location flag still leaves a trail: a check-in in one city and another 300 km away 20 minutes later. Rejecting those protects streaks, badges and future venue footfall data without touching the QR + 150 m rule.
  - Scope: server only, no schema change. Add a pure `isImpossibleTravel(previous, next, maxSpeedKmh = 250)` in a new `server/src/utils/travel.js`. It takes `{latitude, longitude, at}` for the user's most recent check-in's club and for the current attempt, reuses `distanceInMeters` from `server/src/utils/geo.js`, ignores pairs less than 1 km apart, and returns true when the implied speed exceeds `maxSpeedKmh`. In `server/src/controllers/checkInController.js` `checkIn`, after the 409 duplicate check and before `prisma.checkIn.create`, load the user's latest check-in with `prisma.checkIn.findFirst({ where: { userId }, orderBy: { checkedInAt: 'desc' }, include: { club: true } })`. If it's impossible travel, call the existing `logFailure("implausible_travel", userId, clubId)` and return `400 {message: "This check-in doesn't match your previous one. Try again later."}`. Don't reveal the previous club or the distance in the response. The QR check, the 150 m GPS check and the night window stay exactly as they are. Client: no change; `CheckInException` already shows `message`. Out: per-user flags, admin review queues, persisting failures (needs a schema).
  - Acceptance: Jest unit tests in a new `server/src/__tests__/travel.test.js`: 100 km in 10 minutes → true; 100 km in 2 hours → false; 500 m apart 1 minute later → false; exactly at the speed limit → false. Tests in `server/src/__tests__/checkInController.test.js` with mocked Prisma: a previous check-in 300 km away 30 minutes earlier gives 400 and `checkIn.create` is not called; a previous check-in at a club 300 km away 2 days earlier gives 201; with no previous check-in it gives 201. `node .nightshift/test-all.mjs` passes, with no existing tests removed.
  - Size: S

- [x] B37 "My cities" collection progress: visited vs. listed clubs per city — status: done
  - Why: the explorer persona collects places ("12 clubs across 3 cities"), and the regular wants to know what's left in their own city. Per-city progress ("Cluj · 4 of 11 clubs") turns the personal map into a collection and points to the next place to go (core loop step 4), using only data that already exists.
  - Scope: no schema change. Server: a pure `computeCityProgress(checkIns, approvedClubs)` in `server/src/services/statsService.js` that returns `[{city, visitedClubs, totalClubs, lastVisitedAt}]`, sorted by `visitedClubs` desc and then city name, including only cities where the user has at least one check-in. Clubs that are no longer approved still count as visited but not in `totalClubs`, and `visitedClubs` is capped at `totalClubs` for display. Add `GET /api/check-ins/me/cities` (authMiddleware) in `checkInController.js` and `checkInRoutes.js`, registered before `/me`, following `getMyCheckInStats`. It loads the user's check-ins with their club and `prisma.club.findMany({ where: { isApproved: true }, select: { id: true, city: true } })`. It never returns other users' data. Client: `getMyCities()` in `client/lib/services/check_in_service.dart`, a `CityProgressModel` in `client/lib/data/classes/city_progress_model.dart`, a `cityProgress` list on `ClubController` that loads with stats, and a new `client/lib/views/pages/my_cities_page.dart` pushed with `Get.to()` from the stats card on `ProfilePage` (not a nav tab). Each row shows the city, "4 of 11 clubs" and a `LinearProgressIndicator`, plus an empty state ("Check in somewhere to start your collection"). Out: country grouping, per-city maps.
  - Acceptance: Jest unit tests for `computeCityProgress` in `server/src/__tests__/statsService.test.js` (no check-ins → []; two cities sorted correctly; repeat visits to one club count once; an unapproved visited club doesn't inflate `totalClubs`). A supertest/mocked-Prisma test in `server/src/__tests__/routes.test.js` shows `GET /api/check-ins/me/cities` gives 401 without a token and 200 with the expected shape. A Flutter model test parses a fixture JSON, and a widget test pumps `MyCitiesPage` with a fixture `ClubController` (no HTTP) and finds "4 of 11 clubs" and the empty state. `node .nightshift/test-all.mjs` passes.
  - Size: M

- [x] B38 Admin per-club footfall report, to show partner venues during onboarding — status: done
  - Why: pilot step 5.6 means convincing ~10 venues to put a QR at the door, and verified footfall is the pitch (PLAN monetization direction, B24). Admins can only see global metrics today. A per-club report lets the team show a venue its numbers from a phone, with no new roles or schema, before B24 builds the real venue portal.
  - Scope: no schema change; admin-only. Server: a pure `computeClubFootfall({ checkIns, firstVisits, now, weeks = 12 })` in a new `server/src/services/footfallService.js` (mirror `metricsService.js`) that returns `{totalCheckIns, uniqueVisitors, returningVisitorRate, firstTimeShare, weekly: [{weekStart, checkIns, uniqueVisitors}], byWeekday: [7 counts]}`. Use `nightStart` from `server/src/utils/night.js` so 02:00 counts toward the previous evening. `weekly` always has `weeks` entries, oldest first, with zeros filled in. The response must not contain user ids, names or emails. `GET /api/admin/clubs/:id/footfall` in `adminController.js` and `adminRoutes.js` (authMiddleware + adminMiddleware) returns 404 `{message}` for an unknown club and otherwise loads that club's check-ins from the last `weeks` weeks (only `userId` and `checkedInAt` selected) plus each visitor's earliest check-in at the club for the first-time share. Client: `getClubFootfall(id)` in `client/lib/services/admin_service.dart`, a `ClubFootfallModel` in `client/lib/data/classes/`, and a new `client/lib/views/pages/admin/admin_club_footfall_page.dart` pushed from a "Footfall" action on each club in `admin_clubs_page.dart`. It shows the headline numbers and a simple bar row of weekly counts drawn with plain `Container`s (no chart package). Out: venue-manager role and k-anonymity thresholds (B24), and export.
  - Acceptance: Jest unit tests in `server/src/__tests__/footfallService.test.js`: no check-ins gives zeros and 12 weekly buckets; a 02:00 Saturday check-in falls in Friday's weekday bucket; a user with visits in two different weeks counts as returning; the output JSON contains no `userId`. Mocked-Prisma route tests: a non-admin gets 403, an unknown club gets 404, and an admin gets 200 with `weekly.length === 12`. A Flutter widget test pumps `AdminClubFootfallPage` with a fixture model (no HTTP) and finds the unique-visitor count. `node .nightshift/test-all.mjs` passes.
  - Size: M

- [ ] B39 "Not been yet": nearby unvisited clubs list — status: proposed
  - Why: core loop step 4 ("find the next place to go") has no direct screen. A short list of approved clubs the user hasn't visited, nearest first when location is already granted (or in the user's most-visited city otherwise), turns the map into a to-do list.
  - Scope: client only. A pure `unvisitedSuggestions(clubs, visitedIds, {origin, homeCity, limit = 10})` next to `clubsForMap`. A section or page pushed from `ClubMapPage` that reuses `formatDistance` from 6.5. Never prompt for location from here. Build it after 6.5 so it reuses that task's distance helper and "near me" permission logic. Out: personalised ranking and favourites (7.3).
  - Acceptance: unit tests for ordering with and without an origin, visited clubs excluded, and the limit respected; a widget test for the empty state ("You've been everywhere in <city>!").
  - Size: S

- [ ] B40 Persist failed check-in attempts so the success rate becomes measurable — status: proposed
  - Why: PLAN.md names the check-in success rate as a pilot metric, but failures only go to `console.warn` via `logFailure` in `checkInController.js`, so 4.3's metrics can't show it and admins can't spot venues where GPS fails legitimately (the risk table's "dense old towns" row).
  - Scope: a `CheckInAttempt {id, userId, clubId?, reason, createdAt}` model written by `logFailure` (no coordinates stored, which keeps it privacy-light), a 90-day retention note, the success rate and failure-reason breakdown added to `computePilotMetrics` and the admin metrics card, and a per-club "too_far" count in the B38 footfall report. Needs 7.0 (database access for migrations) first.
  - Acceptance: mocked-Prisma tests show each failure reason writes one row and a success writes none; the metrics function computes successes / (successes + failures), and returns null when there are no attempts.
  - Size: M

---

Product-owner proposals, 2026-10-02 (evening). Schema-free retention and account follow-ups.

- [x] B41 "Keep your streak alive" nudge in the app when this week has no check-in yet — status: done
  - Why: the weekly streak (6.1/6.2) is the main "come back" lever (core loop step 4), but nothing warns a user before a streak lapses, and push notifications (B21) need a Firebase account. An in-app banner ("One night out this week keeps your 3-week streak") delivers most of that value with no new services.
  - Scope: no schema change. Server: in `server/src/services/gamificationService.js`, make `weeklyStreak` also return `atRisk` (true when `streak > 0` and the current week, per the existing `weekIndexOf(now)`, has no check-in), and expose it as `streak.atRisk` in the achievements response next to `current` and `longest` (same route, `GET /api/check-ins/me/achievements`). Client: add `streakAtRisk` (false when the key is missing) to `AchievementsModel` in `client/lib/data/classes/achievements_model.dart`. Add a `StreakNudgeBanner` widget in a new `client/lib/widgets/streak_nudge_banner.dart` that reads `ClubController.achievements` and renders nothing unless `streakAtRisk` is true; otherwise a dismissible card "One night out this week keeps your N-week streak". Show it at the top of `ProfilePage` and above the badge grid on `AchievementsPage`. Dismissal lasts for the session only (in memory). Out: push or local notifications (B21), persisted dismissal.
  - Acceptance: Jest tests in `server/src/__tests__/gamificationService.test.js`: check-ins in each of the two previous weeks and none this week → `atRisk: true` with `streak: 2`; a check-in this week → `atRisk: false`; no check-ins → `atRisk: false`; a check-in on this Monday at 03:00 UTC (it belongs to Sunday's night, so the previous week) and nothing after → `atRisk: true`. A Flutter model test parses `streak.atRisk` and defaults to false without it. A widget test pumps `StreakNudgeBanner` with a fixture `ClubController` (no HTTP): it finds "keeps your 3-week streak" when at risk, finds nothing when not, and the text is gone after tapping dismiss. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [x] B42 "On this night": resurface past nights from the same date in the history diary — status: done
  - Why: core loop step 3 ("look back") only happens when the user goes looking. A card like "1 year ago: Club X" makes opening the diary rewarding on ordinary days and reinforces why every pin is worth earning, using check-ins the client already has.
  - Scope: client only, no server or schema change. A pure `onThisNight(List<CheckInModel> checkIns, DateTime now)` in a new `client/lib/data/classes/on_this_night.dart` that returns memories for the same night-date exactly 1, 2, 3… years ago, plus exactly one month ago. Reuse the night grouping in `client/lib/data/classes/check_in_grouping.dart` so a 02:00 check-in counts as the previous evening. Each memory is `{label ("1 year ago" | "2 years ago" | "1 month ago"), nightDate, clubNames}`. A 29 Feb night surfaces on 28 Feb in non-leap years; a month-ago date that doesn't exist (31 Mar → 31 Feb) yields no month memory. In `client/lib/views/pages/check_in_history_page.dart`, show an "On this night" card above the diary when there's at least one memory, listing each label with its club names; tapping a club opens `ClubDetailsPage` the same way history rows do. Out: notifications, server-side memories, photos.
  - Acceptance: Flutter unit tests in a new `client/test/on_this_night_test.dart`: a check-in exactly one year ago at 23:00 is found; one at 02:00 the morning after a year-ago evening is grouped under that evening; a check-in 364 days ago is not found; a 29 Feb check-in surfaces on 28 Feb the next year; `now` = 31 March gives no month-ago memory; two clubs on the same past night appear in one memory. A widget test pumps `CheckInHistoryPage` with a fixture `ClubController` (no HTTP) and finds "1 year ago" and the club name, and finds no "On this night" card when nothing matches. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [x] B43 Change my password while signed in — status: done
  - Why: users can delete their account but can't change a password they think has leaked, and 7.6 (reset by email) is blocked on an email provider. A signed-in change-password flow is a basic trust feature for an app that holds sensitive location history (principle 2).
  - Scope: no schema change. Server: `changePassword` in `server/src/controllers/authController.js` loads the user by `req.user.id` and checks `currentPassword` with `bcrypt.compare` (mirror `deleteMyAccount`). It returns 401 `{message: "Invalid password"}` on a mismatch, 400 `{message}` when the new password equals the current one, and otherwise saves `bcrypt.hash(newPassword, 10)` and returns 200 `{message: "Password changed"}`, never the hash. Route: `POST /api/auth/me/password` in `server/src/routes/authRoutes.js` with `authMiddleware`, `authLimiter` and `express-validator` rules (`currentPassword` not empty; `newPassword` with the same `isLength({ min: 8 })` rule as `signUpValidation`). Client: `changePassword(current, next)` in `client/lib/services/auth_service.dart` and on `AuthController`, and a "Change password" tile on `ProfilePage` that pushes a new `client/lib/views/pages/change_password_page.dart` (current, new and confirm fields; client-side checks for 8+ characters and a matching confirm; "Wrong password" on 401; a snackbar and `Get.back()` on success). Out: signing out other sessions (7.7 needs `tokenVersion`), reset by email (7.6).
  - Acceptance: Jest tests with mocked Prisma in a new `server/src/__tests__/changePassword.test.js` (follow `deleteMyAccount.test.js`): no token → 401; wrong current password → 401 and `user.update` not called; a 7-character new password → 400; new equals current → 400; success → 200, `user.update` called with a hash that `bcrypt.compare(newPassword, hash)` accepts, and the body has no `password` key. Flutter widget tests pump `ChangePasswordPage` with a fake `AuthController` (no HTTP): a mismatched confirm shows an error and doesn't call the controller; a 401 from the fake shows "Wrong password". `node .nightshift/test-all.mjs` passes.
  - Size: S

- [ ] B44 Admin bulk club import from JSON, for venue onboarding — status: proposed
  - Why: pilot step 5.6 onboards ~10 venues, and each later city adds dozens. Entering them one by one through the 4.2 form on a phone is slow and error-prone. A bulk import lets the team prepare the list once (name, address, city, coordinates) and load it in one call, with clear per-row errors.
  - Scope: no schema change; admin-only. Server: `POST /api/clubs/import` (authMiddleware + adminMiddleware, registered before the `/:id` routes in `clubRoutes.js`) takes `{clubs: [...], approve?: boolean}`, at most 100 rows. A pure `validateClubRows(rows, existingClubs)` in a new `server/src/services/clubImportService.js` applies the same field rules as `clubValidation` (name, address and city required; latitude and longitude in range; optional `imageUrl`) and flags duplicates by case-insensitive name + city, both against existing clubs and within the file. If any row is invalid, nothing is written and the response is 400 `{errors: [{row, field, message}]}`. Otherwise every row is created in one `prisma.$transaction`, each with its own `generateQrSecret()`, and the response is 201 `{created: n}` with no `qrSecret`. Client (optional, could be a follow-up): an "Import" action on `admin_clubs_page.dart` that accepts pasted JSON. Out: CSV parsing, geocoding addresses, updating existing clubs.
  - Acceptance: Jest unit tests for `validateClubRows` (a missing city; latitude 91; a duplicate inside the file; a case-insensitive duplicate of an existing club). Mocked-Prisma route tests: a non-admin gets 403; 101 rows give 400; one bad row gives 400 and nothing is created; valid rows give 201, `$transaction` is called once, every created row has a distinct `qrSecret`, and the response contains no `qrSecret`.
  - Size: M

---

Product-owner proposals, 2026-10-03. Schema-free: pilot exit scorecard, goal hints, and looking back.

- [x] B45 Pilot exit scorecard for admins: the four exit criteria and the weekly north-star trend — status: done
  - Why: PLAN.md sets explicit pilot exit criteria (~10 partner clubs, 200+ signups, 40%+ activation, 25%+ of activated users checking in on 2+ nights in their first 30 days) and names weekly active check-in users (WACU) as the north star, but the 4.3 metrics only show a sliding 7/30/90-day window. The team can't see whether the pilot has passed, or whether WACU is trending up week over week, and that is the decision gate for investing in the social phases.
  - Scope: no schema change; admin-only. Server: a pure `computePilotScorecard({ users, checkIns, approvedClubCount, now, weeks = 8 })` in `server/src/services/metricsService.js` next to `computePilotMetrics` (reuse its `DAY_MS` and `ACTIVATION_DAYS`, and `nightStart` from `server/src/utils/night.js`). It returns `{criteria: [{id, label, value, target, met}], wacu: [{weekStart, activeUsers}]}` with criteria ids `partner_clubs` (value = `approvedClubCount`, target 10), `signups` (all users, target 200), `activation` (share of users who signed up at least 14 days before `now` with a check-in within 14 days of signup; target 0.4; value `null` and `met: false` when there are no such users), and `retention` (among activated users who signed up at least 30 days before `now`, the share with check-ins on 2+ distinct nights, by `nightStart`, within 30 days of signup; target 0.25; same null rule). `wacu` has exactly `weeks` entries, oldest first, each counting distinct users with a check-in in that 7-day window (windows end at `now` and step back 7 days), zeros filled in. No user ids, names or emails in the output. Add `GET /api/admin/metrics/scorecard` in `server/src/controllers/adminController.js` and `server/src/routes/adminRoutes.js` (authMiddleware + adminMiddleware, mirror the existing metrics handler) that loads users (`id`, `createdAt`), check-ins (`userId`, `checkedInAt`) and `prisma.club.count({ where: { isApproved: true } })`. Client: `getPilotScorecard()` in `client/lib/services/admin_service.dart`, a `PilotScorecardModel` in a new `client/lib/data/classes/pilot_scorecard_model.dart`, and a "Pilot exit criteria" section at the top of `client/lib/views/pages/admin/admin_metrics_page.dart`: one row per criterion with "value / target" and a check or cross icon (percentages for rates, "—" for null), plus an 8-bar WACU row drawn with plain `Container`s like the existing `DailyBars`. Out: storing snapshots, alerts, per-city scorecards.
  - Acceptance: Jest unit tests in `server/src/__tests__/metricsService.test.js`: empty input gives `signups` value 0, activation and retention `null` with `met: false`, and 8 zero WACU buckets; a user who signed up 40 days ago and checked in on 2 different nights within 30 days counts as retained, while a user whose two check-ins were at 01:00 and 03:00 on the same night does not; a user who signed up 5 days ago is excluded from the activation denominator; 10 approved clubs gives `partner_clubs.met === true`; the JSON output contains no `userId`. Mocked-Prisma route tests in `server/src/__tests__/routes.test.js`: no token → 401, non-admin → 403, admin → 200 with 4 criteria and `wacu.length === 8`. A Flutter model test parses a fixture (including a null activation value), and a widget test pumps the scorecard section with a fixture model (no HTTP) and finds "Pilot exit criteria", "10 / 10" and "—". `node .nightshift/test-all.mjs` passes.
  - Size: M

- [x] B46 "Next up" goal hints: the closest unearned badge and what it takes — status: done
  - Why: badges (6.1/6.2) only motivate if users know which one is within reach. Today an unearned badge shows `current/target` only after tapping it in the grid. A line like "2 more clubs to unlock Explorer" on Profile turns the badge catalogue into a reason to go out this weekend (core loop step 4), using data the client already has.
  - Scope: client only, no server or schema change. A pure `nextGoals(AchievementsModel a, {int limit = 2})` in a new `client/lib/data/classes/next_goals.dart` that picks unearned badges with `current > 0` (plus the `first_pin` badge when nothing is earned yet), sorted by highest `current / target`, then smallest `target - current`, then catalogue order, and returns `[{badgeId, title, remaining, hint}]`. Build `hint` from the badge id (the ids are listed in `badgeIcon` in `client/lib/views/pages/achievements_page.dart`): `explorer_*` → "N more clubs to unlock <title>", `globetrotter_*` → "N more cities to unlock <title>", `regular_*` → "N more nights at one club to unlock <title>", `streak_*` → "N more weeks in a row to unlock <title>", `first_pin` → "Check in anywhere to unlock First pin", anything else → "N to go for <title>", with correct singular/plural. A `NextGoalsCard` widget in a new `client/lib/widgets/next_goals_card.dart` reads `ClubController.achievements` and renders nothing when achievements are null or there are no goals; otherwise a card titled "Next up" with one row per goal and a `LinearProgressIndicator`. Show it on `client/lib/views/pages/profile_page.dart` under `AchievementsSummaryTile`; tapping it opens `AchievementsPage` like the tile does. Out: server-side hints, new badges, notifications.
  - Acceptance: Flutter unit tests in a new `client/test/next_goals_test.dart`: Explorer at 3/5 and Pathfinder at 3/15 gives Explorer first with "2 more clubs to unlock Explorer"; earned badges are never returned; a remaining count of 1 is singular ("1 more club"); no check-ins at all returns only the First pin hint; `limit` is respected. A widget test pumps `NextGoalsCard` with a fixture `ClubController` (no HTTP): it finds "Next up" and the hint text, and finds nothing when every badge is earned. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [x] B47 Nights-out calendar: a year-at-a-glance grid of the nights I went out — status: done
  - Why: the regular's core question is "what was that place in March?", and the core loop's "look back" step lives in recaps and the diary. A GitHub-style calendar of nights out (one cell per night, shaded by number of clubs) makes a year of verified pins visible at a glance and gives a reason to tap back into a specific night.
  - Scope: client only, no server or schema change. A pure `nightsCalendar(List<CheckInModel> checkIns, int year)` in a new `client/lib/data/classes/nights_calendar.dart` that returns a map from night date (date-only `DateTime`) to that night's club names, reusing `nightOf` from `client/lib/data/classes/check_in_grouping.dart` so a 02:00 check-in counts as the previous evening (a 01:00 check-in on 1 January belongs to 31 December of the previous year). It also returns `nightsOut` (number of nights) and `longestGapDays` between consecutive nights in that year (0 with fewer than two nights). A `NightsCalendar` widget in a new `client/lib/widgets/nights_calendar.dart`: 53 columns × 7 rows (Monday first) of small squares drawn with plain `Container`s (no new package), each keyed `Key('night_yyyy-MM-dd')`; empty cells muted, 1 club one shade, 2+ clubs a stronger shade, month initials above. Tapping a filled cell shows a bottom sheet listing that night's clubs, each opening `ClubDetailsPage` the way history rows do. Show it in `client/lib/views/pages/recap_page.dart` only when a year is selected (not for the monthly recap), above the share card, with the caption "N nights out in <year>". Out: multi-year views, sharing the calendar as an image, streak overlays.
  - Acceptance: Flutter unit tests in a new `client/test/nights_calendar_test.dart`: check-ins at two clubs on the same evening give one night with two clubs; a 02:00 check-in is keyed to the previous date; a 01:00 check-in on 1 January is excluded from that year and included in the previous one; `longestGapDays` for nights on 1 and 11 March is 10; an empty list gives `nightsOut` 0. A widget test pumps `NightsCalendar` with fixture check-ins (no HTTP), finds "3 nights out in 2026", taps `Key('night_2026-03-14')` and finds the club name in the sheet. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [ ] B48 Admin "quiet clubs" health check: approved clubs with no check-ins lately — status: proposed
  - Why: during the pilot, a partner club with no check-ins for two weekends usually means the QR isn't at the door, the display screen (6.4) is off, or GPS fails there. Spotting that from the admin console lets the team fix it before the venue decides Clubsy doesn't work.
  - Scope: no schema change; admin-only. A pure `findQuietClubs({ clubs, lastCheckIns, now, quietDays = 14 })` in `server/src/services/footfallService.js` that returns approved clubs whose latest check-in is older than `quietDays`, or that never had one, with `daysSinceLastCheckIn` (null for never), sorted never-first then longest-quiet. `GET /api/admin/clubs/quiet` (registered before the `/clubs/:id` admin routes) using `prisma.checkIn.groupBy({ by: ['clubId'], _max: { checkedInAt: true } })`. Client: a "Quiet" filter on `admin_clubs_page.dart` next to pending/approved, showing "No check-ins for 18 days" per row, with links to the B38 footfall page and the QR page. Out: notifying venues, auto-unapproving.
  - Acceptance: Jest tests for `findQuietClubs` (a never-checked-in club listed first; a club checked in 3 days ago excluded; unapproved clubs excluded; the boundary at exactly 14 days); mocked-Prisma route tests (403 for non-admin, 200 shape); a widget test for the Quiet filter with a fixture list.
  - Size: S

- [ ] B49 "My top clubs": a ranked list of my most-visited places with first and last visit — status: proposed
  - Why: the profile only shows a single `mostVisitedClub`. Regulars identify with "their" clubs; a top-5 ranking ("Club X · 14 nights · since March") is a bit of bragging rights, prepares venue perks for regulars (B25), and links straight to each club page.
  - Scope: no schema change. Extend `computeCheckInStats` in `server/src/services/statsService.js` with `topClubs: [{id, name, city, nights, firstVisitAt, lastVisitAt}]` (top 5 by distinct nights via `nightStart`, ties broken by most recent visit), keeping `mostVisitedClub` unchanged for compatibility. Client: parse it in `check_in_stats_model.dart` (empty list when missing) and add a "Your top clubs" section on `ProfilePage` whose rows push `ClubDetailsPage`. Out: public leaderboards across users (needs the Phase 8 social foundation and must stay opt-in).
  - Acceptance: Jest tests for ranking by distinct nights (two check-ins on one night count once), ties, the 5-item cap and the empty case; a Flutter model test for the missing key; a widget test finding "14 nights".
  - Size: S

---

Product-owner proposals, 2026-10-03 (night). Schema-free: finding a past night, GPS health at the door, personal records, cohorts.

- [x] B50 Find a night: search my check-in history by club or city — status: done
  - Why: the regular's defining question is "what was that place in March?" (PLAN.md, who it's for). The diary (3.5) is a long, newest-first scroll, so after a few months a past night is hard to find. A search field that filters the diary by club name or city makes the history useful as a record, using check-ins the client already has.
  - Scope: client only, no server or schema change. A pure `filterNightGroups(List<NightGroup> groups, String query)` in `client/lib/data/classes/check_in_grouping.dart` (next to `groupByNight`) that keeps the groups that contain at least one check-in whose `club.name` or `club.city` contains the trimmed query (case-insensitive), keeps only the matching check-ins inside each group, and returns `groups` unchanged for an empty or whitespace-only query. In `client/lib/views/pages/check_in_history_page.dart`, add a search `TextField` (hint "Search clubs or cities", `Key('history_search')`, with a clear button) above the diary when there is at least one check-in. Keep the query in a small `StatefulWidget` or an `RxString` local to the page, not in `ClubController`. While a query is active, hide the month summary and the "On this night" card, show "N nights match" ("1 night matches" for one) above the results, and show `No nights match "<query>"` when nothing matches. Swipe-to-remove and tapping a row keep working on filtered rows. Out: server-side search, date-range pickers, searching notes (7.4).
  - Acceptance: Flutter unit tests added to `client/test/check_in_grouping_test.dart`: the query "techno" matches club "Techno Hall" case-insensitively; the query "cluj" matches by city; a night with two clubs where only one matches keeps that night with just the matching check-in; an empty or "   " query returns all groups; a query that matches nothing returns an empty list. A widget test in `client/test/pages_widget_test.dart` pumps `CheckInHistoryPage` with a fixture `ClubController` (no HTTP), enters text into `Key('history_search')`, finds the matching club and "1 night matches", doesn't find a non-matching club, and finds "No nights match" for an unknown query. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [ ] B51 Admin check-in distance health per club: is the 150 m GPS radius right at this venue? — status: approved
  - Why: the plan's top door risk is GPS inaccuracy indoors and in dense old towns making the 150 m check fail at a real venue, and pilot step 5.6 asks the team to measure real-world distances. Every successful check-in already stores `distanceMeters`. Showing the distribution per club (median, 90th percentile, share close to the limit) tells the team which venue's pin is misplaced or where GPS is marginal, without loosening verification.
  - Scope: no schema change; admin-only; read-only. Server: a pure `computeDistanceHealth(distances, { limit = MAX_CHECK_IN_DISTANCE_METERS })` in `server/src/services/footfallService.js` that takes an array of numbers and returns `{count, medianMeters, p90Meters, nearLimitShare, status}`. `nearLimitShare` is the share of distances >= 0.8 × limit. `status` is `"insufficient"` when count < 5, otherwise `"marginal"` when `p90Meters >= 0.8 × limit`, otherwise `"ok"`. Median and p90 use nearest-rank and are rounded to whole metres; with count 0, all numbers are `null`. Import `MAX_CHECK_IN_DISTANCE_METERS` from `server/src/controllers/checkInController.js` (export it if it isn't already, or move it to `server/src/utils/geo.js` and import it in both places) so there is one source of truth. Extend the existing `getClubFootfall` in `server/src/controllers/adminController.js` to also select `distanceMeters` for the same window and add `distance: computeDistanceHealth(...)` to its response. Don't add a new route. Client: add an optional `distance` (`DistanceHealth` with nullable fields) to `client/lib/data/classes/club_footfall_model.dart`, parsed as null when the key is missing. On `client/lib/views/pages/admin/admin_club_footfall_page.dart`, add a "Check-in distance" card with "Median 42 m · 90% within 118 m", the near-limit share as a percentage, and a warning line "Many check-ins are close to the 150 m limit: check the pin's position" when status is `marginal`, or "Not enough check-ins yet" when it is `insufficient`. Out: changing the radius, per-club radius overrides, logging failed attempts (B40).
  - Acceptance: Jest unit tests in `server/src/__tests__/footfallService.test.js`: `[]` gives count 0, null numbers and `insufficient`; four distances give `insufficient`; `[10,20,30,40,50,60,70,80,90,100]` gives median 50 and p90 90 with status `ok` at limit 150; ten distances with p90 >= 120 give `marginal`; `nearLimitShare` counts values >= 120 at limit 150. A mocked-Prisma route test in `server/src/__tests__/routes.test.js` checks that the admin footfall response includes `distance.count` and contains no `userId`. A Flutter model test parses `distance` and defaults to null without it. A widget test in `client/test/admin_club_footfall_test.dart` pumps the page with a fixture (no HTTP) and finds "Median 42 m" and the marginal warning. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [ ] B52 "Your records": personal bests from my nights out — status: approved
  - Why: the explorer and the regular both respond to counts and bragging rights (PLAN.md). Badges give fixed thresholds, but personal records ("Biggest night: 3 clubs on 14 Mar", "Busiest month: 7 nights in July 2026") reward someone's own history and give a reason to beat it, all derived from verified pins (principle 5).
  - Scope: client only, no server or schema change. A pure `personalRecords(List<CheckInModel> checkIns)` in a new `client/lib/data/classes/personal_records.dart` that groups by night with `nightOf` / `groupByNight` from `client/lib/data/classes/check_in_grouping.dart` (so a 02:00 check-in counts as the previous evening). It returns null for no check-ins. Otherwise it returns `PersonalRecords` with `biggestNight` (night date + distinct club count; ties go to the most recent night), `busiestMonth` (year, month, nights; ties go to the most recent), `firstNight` (date of the earliest night) and `mostVisitedCity` (the city with the most distinct nights; ties alphabetical). A `PersonalRecordsCard` widget in a new `client/lib/widgets/personal_records_card.dart` reads `ClubController.myCheckIns` and renders nothing when the result is null. Otherwise it shows a "Your records" card with rows "Biggest night: 3 clubs · 14 Mar 2026", "Busiest month: 7 nights · July 2026", "First night out: 2 Feb 2026" and "Most nights in: Cluj-Napoca", with singular forms ("1 club", "1 night"). Show it on `client/lib/views/pages/profile_page.dart` below `NextGoalsCard`. Out: comparing with other users, server-side records, new badges.
  - Acceptance: Flutter unit tests in a new `client/test/personal_records_test.dart`: empty input gives null; two clubs on one evening plus one at 02:00 the next morning give a biggest night of 3 clubs on that evening's date; two months with equal nights choose the more recent one; two check-ins on one night count as one night towards `busiestMonth`; `mostVisitedCity` counts distinct nights, not check-ins. A widget test pumps `PersonalRecordsCard` with a fixture `ClubController` (no HTTP), finds "Your records" and "Biggest night: 3 clubs", and finds nothing with no check-ins. `node .nightshift/test-all.mjs` passes.
  - Size: S

- [ ] B53 Admin signup cohorts: activation and retention by signup week — status: proposed
  - Why: the B45 scorecard gives one pilot-wide activation and retention number, but it can't show whether onboarding changes (consent flow, check-in primer, new venues) are working. A weekly cohort table ("signed up week of 7 Sep: 24 users, 46% activated, 21% retained") shows whether newer users do better than older ones, and that is the trend that decides whether the pilot is improving.
  - Scope: no schema change; admin-only; aggregates only. A pure `computeSignupCohorts({ users, checkIns, now, weeks = 8 })` in `server/src/services/metricsService.js` that reuses the B45 activation and retention definitions (`ACTIVATION_DAYS`, `RETENTION_DAYS`, distinct nights via `nightStart`) and returns one entry per Monday-aligned signup week, oldest first: `{weekStart, signups, activationRate, retentionRate}`. A rate is `null` until every user in the cohort has had the full window, and also when the cohort is empty. `GET /api/admin/metrics/cohorts` (authMiddleware + adminMiddleware) in `adminController.js` / `adminRoutes.js`. Client: `getSignupCohorts()` in `admin_service.dart`, a model, and a "Signup cohorts" table on `admin_metrics_page.dart` that shows "—" for null. Out: daily cohorts, per-city cohorts, exporting.
  - Acceptance: Jest unit tests (empty input gives 8 empty cohorts; a cohort less than 14 days old has `activationRate: null`; same-night check-ins don't count as retained; the output has no user ids); mocked-Prisma route tests (401/403/200 with 8 entries); a Flutter model test and a widget test that finds "Signup cohorts" and "—".
  - Size: M
