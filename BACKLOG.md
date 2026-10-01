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
