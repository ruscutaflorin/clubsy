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
Phases 2-5 are genuine future work; Phase 6 carries a hard safety constraint, not just a feature
description.

- [!] B1 Gamification: visit streaks, weekly challenges, points balance — status: approved <!-- failed 2026-10-01: BLOCKED: no database available — B1 needs a schema change and `prisma migrate dev`, and it is also too large for a single task. -->
  - Why: core retention loop once check-in itself works.
  - Scope: a `Streak`/points-balance concept on `User` or a new `UserStats` model, computed from
    `CheckIn` history (consecutive nights/weeks with a check-in); a handful of static weekly
    challenges (e.g. "check in at 3 different clubs this week"); a read-only points balance only —
    no spending yet, that's B4.
  - Acceptance: a user can see their current streak and challenge progress in the app; points
    accrue from check-ins and challenge completions.
  - Size: likely 4-6 tasks (schema, backend computation, Flutter UI).

- [!] B2 Ratings: post-visit behavior ratings between users — status: approved <!-- failed 2026-10-01: BLOCKED: no database available. B2 needs a new `Rating` model, and the project rules require adding it with `npx prisma migrate dev`, which needs a live Postgre... -->
  - Why: requested as a safety/quality signal for who you'll meet at a club.
  - Scope: a `Rating` model (rater, ratee, optional note, 1-5 score), only submittable between two
    users who checked into the same club on the same night; an average rating surfaced on profile.
  - Acceptance: after a shared check-in window closes, both users can rate each other once; the
    average shows on the rated user's profile.
  - Size: likely 4-5 tasks.

- [!] B3 Matching: Tinder-style swipe/match between users checked into the same club/night — status: approved <!-- failed 2026-10-01: BLOCKED: B3 needs a dedicated design and privacy pass first, and its schema migration needs a live database (no database available). -->
  - Why: the original pitch's "algorithm similar to Tinder" for clubgoers.
  - Scope: a swipe/like/match model scoped to users who share a current or recent check-in at the
    same club; a match unlocks some form of contact (chat is out of scope unless separately
    proposed). Needs its own privacy pass (who's shown to whom, consent, blocking/reporting) before
    being built, not just a schema.
  - Acceptance: TBD pending a dedicated design pass — this is a bigger feature than the others and
    should get its own planning round, not a single task list.
  - Size: large; likely needs its own plan, not just backlog tasks.

- [!] B4 Points economy & subscriptions — status: approved <!-- failed 2026-10-01: BLOCKED: B4's acceptance criteria are "TBD" and what's being sold (perks, cosmetics, partner discounts, subscription tiers) hasn't been decided. It also require... -->
  - Why: monetization + a sink for the points balance from B1.
  - Scope: ways to spend accumulated points (perks, cosmetic profile features, club-partner
    discounts — TBD with the business side); subscription tiers on top. Reintroduce a Stripe
    integration following `timeit`'s `server/src/services/stripeService.js` as the implementation
    pattern (that file was deliberately not carried into this repo — Phase 1 has no payments).
  - Acceptance: TBD — needs a decision on what's actually being sold before tasks can be written.
  - Size: large.

- [!] B5 Live presence map ("who's out tonight") — status: approved <!-- failed 2026-10-01: BLOCKED: B5 has no defined acceptance criteria or safety/blocking design, and the project rules forbid building the presence map without an explicit scope. -->
  - Why: the original "Snapchat map" pitch. **Deferred deliberately** for real safety reasons
    (stalking/unwanted-contact risk in a nightlife context), not because it's low value.
  - Scope, non-negotiable before any build: opt-in per session (not a standing setting), visible
    only to mutual friends/matches (never broadcast more broadly by default), auto-expires a few
    hours after the session ends. Do not approve a version of this that skips any of the three.
  - Acceptance: TBD — needs its own design/safety review pass when the time comes, including how
    blocking/reporting interacts with it.
  - Size: large; requires realtime infrastructure (websockets or similar) not present in Phase 1.

- [ ] B6 Stop exposing club `qrSecret` to non-admin clients — status: proposed
  - Why: `GET /api/clubs` and `GET /api/clubs/:id` return the full `Club` row, including `qrSecret`, to any signed-in user. Anyone can then build a valid QR payload and check in remotely with spoofed GPS, which breaks the "QR scanned on-site" half of the check-in promise.
  - Scope: in `server/src/controllers/clubController.js`, leave `qrSecret` out of `getClubs`/`getClubById` responses for non-admins (Prisma `omit`/`select`, or a small `toPublicClub` helper). Also make `getClubById` return 404 to non-admins for unapproved clubs, the same way `checkIn` treats them. `createClub` (admin-only) still returns the secret and `qrCode`. No schema change. Client `ClubModel` must keep parsing when `qrSecret` is absent; confirm it doesn't read the field. Out: rotating secrets that have already leaked (see B10).
  - Acceptance: a Jest test with a mocked Prisma client shows the controller response for a USER role has no `qrSecret`, on both the list and the single-club route; an ADMIN still sees it; a non-admin asking for an unapproved club gets 404. `pnpm test` passes.
  - Size: S

- [ ] B7 Make the Express app importable and add route-level tests with mocked Prisma — status: proposed
  - Why: every server feature so far has stalled because nothing can be verified without Postgres. If the controllers can be tested without a database, check-in rules (QR + 150m) and auth can be verified on every night shift.
  - Scope: split `server/src/index.js` into `server/src/app.js`, which builds and exports the `app`, and `index.js`, which only calls `listen`. Add `supertest` as a devDependency. Mock `server/src/prisma/client.js` with Jest ESM module mocking (`jest.unstable_mockModule`, or whatever fits the current `"type": "module"` + Jest setup). Cover `POST /api/check-ins`: success, wrong QR, too far (>150m), unapproved club, missing auth. Cover `GET /api/check-ins/me`. No real DB and no schema change.
  - Acceptance: `cd server && pnpm test` runs the new supertest suites without `DATABASE_URL`. The suite asserts 201 for valid QR within 150m, 400 for a bad QR, 400 with `distanceMeters` when too far, and 401 without a token. Importing `app.js` does not open a port.
  - Size: M

- [ ] B8 Prevent duplicate check-ins at the same club on the same night — status: proposed
  - Why: right now a user can scan the same QR repeatedly and inflate their history. Once B1 (streaks/points) lands, that's a direct exploit, and today it already clutters the personal history.
  - Scope: in `checkInController.checkIn`, before `prisma.checkIn.create`, look up an existing `CheckIn` for the same `userId` + `clubId` within a "night" window. Define the window in one exported helper, e.g. `server/src/utils/night.js`: a night runs 06:00 to 06:00 so that 2am counts as the previous evening (UTC for now; note that in NOTES). If one exists, return `409 {message}`. No schema change: query by `checkedInAt` range using the existing `@@index([userId])`. Client: `CheckInPage` shows the 409 message as-is. Out: per-club timezones.
  - Acceptance: unit tests for the night-window helper (23:00 and 02:00 the next day fall in the same night; 07:00 starts a new one). A controller test (mocked Prisma, building on B7 or using a standalone mock) returns 409 on a second check-in in the same window and 201 at a different club. `pnpm test` passes.
  - Size: S

- [ ] B9 Personal map stats: clubs visited, cities, total check-ins on Profile — status: proposed
  - Why: the product promise is "build a personal map of places you've visited". A summary (N clubs across M cities, most-visited club, first check-in date) makes that progress visible without the B1 gamification schema.
  - Scope: server `GET /api/check-ins/me/stats` in `checkInController.js` and `checkInRoutes.js` (register it before any `/:id`-style routes). It uses Prisma `groupBy`/`findMany` on existing `CheckIn` + `Club` data to return `{totalCheckIns, uniqueClubs, uniqueCities, mostVisitedClub, firstCheckInAt}`. Put the aggregation in a pure function (e.g. `server/src/services/statsService.js`) so it can be unit-tested. Client: add `getMyStats()` to `check_in_service.dart`, a `CheckInStatsModel` in `client/lib/data/classes/`, a stats field in `ClubController`, and a small stats card on `ProfilePage`. No schema change.
  - Acceptance: Jest unit tests for the pure aggregation function (empty history, several clubs in two cities, ties for most visited). A Flutter widget test renders the `ProfilePage` stats card from a fixture `CheckInStatsModel` with no HTTP. `pnpm test` and `flutter test` pass.
  - Size: M

- [ ] B10 Admin: re-fetch and rotate a club's venue QR — status: proposed
  - Why: the venue QR is only returned once, from `createClub`. If a printout is lost there's no way to get it again, and if a secret leaks (B6 shows the risk is real) there's no way to invalidate it, which undermines check-in verification.
  - Scope: `GET /api/clubs/:id/qr` returns `{qrCode}` via `generateClubQr`. `POST /api/clubs/:id/qr/rotate` sets a new `generateQrSecret()` and returns the new `{qrCode}`. Both are admin-only (`adminMiddleware`), in `clubController.js`/`clubRoutes.js`. No schema change: `qrSecret` already exists and is unique. Client admin UI is out of scope (no admin screens exist yet). It needs its own item if wanted.
  - Acceptance: controller tests with mocked Prisma: a non-admin gets 403; an admin gets a data-URL `qrCode`; after rotation, `verifyClubQrPayload` rejects the old payload and accepts the new one. `pnpm test` passes.
  - Size: S

- [ ] B11 Validate signup/signin input and fail safely without `JWT_SECRET` — status: proposed
  - Why: `authRoutes.js` is the only route file without `express-validator`. A signup with a missing email, a blank name or a 1-char password goes straight to Prisma and comes back as a generic 500, or creates a weak account. Every check-in and personal-map feature starts at this door, so it should be validated like the others.
  - Scope: add `signUpValidation` (`email` isEmail + normalizeEmail, `password` min length 8, `name` notEmpty + trim) and `signInValidation` (`email`, `password` notEmpty) in `server/src/routes/authRoutes.js`, following `clubRoutes.js`. Add the `validationResult` → `400 {errors}` guard to `signUp`/`signIn` in `authController.js`, following `clubController.createClub`. If `process.env.JWT_SECRET` is unset, return `500 {message}` before calling `jwt.sign`, and never issue a token. Client: make `auth_service.dart` show the first `errors[].msg` when `message` is absent. No schema change. Out: password reset, refresh tokens, rate limiting.
  - Acceptance: Jest tests with mocked Prisma (same pattern as `checkInController.test.js`): a bad email, a short password or a missing name gets 400 `{errors}` and `prisma.user.create` is never called; a valid signup gets 201 with a token; with `JWT_SECRET` unset, signin gets 500 and no token. `pnpm test` passes.
  - Size: S

- [ ] B12 Show why a check-in failed, including how far away the user is — status: proposed
  - Why: the check-in is the product's core action. When it fails, `check_in_service.dart` only reads `message`. Validation failures (`{errors}`) show as a bare "Failed to check in", and the server's `distanceMeters` on a too-far response is thrown away. Users can't tell whether to walk closer, rescan, or give up.
  - Scope: in `client/lib/services/check_in_service.dart`, parse error bodies into a small `CheckInException` class (message, optional `distanceMeters`, optional field errors), put in the same file or `client/lib/data/classes/`. Keep the parsing in a pure function, e.g. `CheckInException.fromResponse(int status, String body)`, so it can be tested. `CheckInPage` shows "You're ~420 m away — get within 150 m of the entrance" when `distanceMeters` is present, and the first field error otherwise. Do not compute or enforce distance on the client: the server stays authoritative and the QR + 150 m rule is unchanged. No server change.
  - Acceptance: Flutter unit tests for the parser: a 400 with `distanceMeters` gives a message containing the rounded metres; a 400 `{errors:[{msg}]}` gives that msg; a 404 `{message}` gives the message; a non-JSON body gives a generic fallback. `flutter test` and `flutter analyze --no-fatal-infos` pass.
  - Size: S

- [ ] B13 Visit summary on ClubDetailsPage ("3 visits · last on 12 Sep") — status: proposed
  - Why: the personal map is the product's promise. Today a club page only shows a "Checked in before" chip. Showing how often and when the user was there makes each pin feel like part of their own history. All the data is already on the client.
  - Scope: add a pure helper (e.g. `visitSummaryFor(String clubId, List<CheckInModel>)` returning count, first visit and last visit) next to `ClubController` or in `client/lib/data/classes/`. Expose it from `ClubController`, and replace or extend the chip in `client/lib/views/pages/club_details_page.dart` with "N visits · last on <date>" (first-visit date as secondary text). The page must keep rendering when there are no visits. Client-only: no server or schema change. Out: other users' visit counts (that's social, needs its own privacy item).
  - Acceptance: unit tests for the helper (no visits, one visit, several out of order so it picks the latest correctly, other clubs ignored). A widget test pumps `ClubDetailsPage` with a fixture club and a `ClubController` that has preset `myCheckIns`, with no HTTP, and finds the "3 visits" text. `flutter test` passes.
  - Size: S

- [ ] B14 Personal-map filter and framing: "Visited only" toggle and fit map to my clubs — status: proposed
  - Why: `ClubMapPage` shows every approved club and centres on the first club in the list, so the user's own map gets lost among clubs they haven't visited. A visited-only view, framed around where they've been, is the "personal map of places you've visited" in its plainest form.
  - Scope: in `client/lib/views/pages/club_map_page.dart`, add a small overlay toggle (All / Visited) backed by an `RxBool` on `ClubController`. Pull the marker selection into a pure function `clubsForMap(clubs, visitedIds, visitedOnly)` and a pure `boundsFor(List<ClubModel>)` that returns null when the list is empty. Use flutter_map's `CameraFit.bounds` when bounds exist, otherwise keep `_defaultCenter`. Show an empty-state hint ("No check-ins yet") when visited-only is on and nothing has been visited. Client-only: no server change. Out: device-location centring and clustering.
  - Acceptance: unit tests for `clubsForMap` (both modes, none visited) and `boundsFor` (empty → null, one club, several clubs → correct SW/NE). A widget test toggles to Visited with a fixture `ClubController` and checks the empty-state text when nothing has been visited. `flutter test` passes.
  - Size: S

- [ ] B15 Club search and city filter screen — status: proposed
  - Why: users can only find a club by panning the map. `GET /api/clubs` already supports `search` and `city`, and `ClubService.getClubs({search, city})` already sends them, but no UI uses them. Finding the venue you're standing outside of is the first step of every check-in.
  - Scope: new `client/lib/views/pages/club_search_page.dart`, pushed with `Get.to()` from a search action in `ClubMapPage` (not a new nav tab). A debounced text field calls `ClubService.getClubs(search:)`. Each result tile shows name, city and a visited marker from `visitedClubIds`, and tapping it opens `ClubDetailsPage`. Keep the results state in a small `ClubSearchController` (GetX) that takes an injectable fetch function, so tests need no HTTP. Server: in `clubController.getClubs`, clamp `page`/`limit` to positive integers with `limit` ≤ 50, because today a non-numeric `limit` produces `NaN` in `skip`/`take`. Cover that with a mocked-Prisma Jest test. No schema change.
  - Acceptance: Jest: `limit=abc` and `limit=1000` call `findMany` with `take` 20 and 50 respectively. Flutter: a controller test with a fake fetch shows the query is forwarded and the results are exposed. A widget test renders fixture results and marks the visited one. `pnpm test` and `flutter test` pass.
  - Size: M
