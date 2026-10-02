# Plan: clubsy

## Vision

A social app for clubbing. Users check in at clubs (a QR code shown at the venue, plus GPS proximity)
and build a personal map and diary of their nights out. Over time, that verified history powers
achievements, discovery, a safety-first social layer, and venue partnerships.

Pivoted from `timeit`, a separate event-management app. Clubsy reuses some of timeit's working
infrastructure patterns (JWT auth, Express/Prisma scaffolding, Flutter/GetX app shell) but is a new
repository with its own database, designed around club check-ins rather than retrofitted from an
Event model.

### Who it's for

- **The regular** (primary): goes out 2-6 times a month, 18-30, mostly in one city. They want a
  record of where they've been ("what was that place in March?"), a bit of bragging rights, and
  ideas for where to go next. Success for them: the app is worth opening on a night out, not only
  at the door.
- **The explorer**: travels or moves around and collects cities and venues. They respond to maps,
  counts and badges ("12 clubs across 3 cities").
- **The venue** (secondary, future customer): clubs that want verified footfall data and a way to
  reward regulars. Venues are the most realistic path to revenue (see "Monetization direction").

### Core loop

1. Arrive at a club, scan the venue QR and pass the GPS check. This is the only way to add a pin,
   so every pin is earned.
2. Get an immediate reward: a new pin, "visit #N", a badge or streak progress.
3. Look back: the map, the history diary, stats, and periodic recaps ("your September", Wrapped).
4. Come back: find the next place to go (search, favourites, "you haven't been here yet"), keep a
   streak, finish a weekly challenge.
5. Later, socially: see friends' nights after the fact, never live by default (see the safety
   principles).

### North-star metric and pilot targets

- **North star: weekly active check-in users (WACU)**, meaning distinct users with at least one
  successful check-in in a 7-day window. It measures the core action, which can't be faked by
  opening the app.
- Supporting metrics, all computable from `User`/`CheckIn` without new tables (task 4.3):
  - activation: % of new signups who check in within 14 days
  - retention: % of users with check-ins on 2+ distinct nights within 30 days
  - depth: median distinct clubs per active user
  - check-in success rate: successful / attempted. Needs failure logging (task 3.2); failures are
    not persisted today.
- Pilot exit criteria, to decide whether to invest in the social phases: ~10 partner clubs in one
  city, 200+ signups, 40%+ activation, and 25%+ of activated users checking in on 2+ nights in
  their first 30 days.

## Product principles (binding unless the user changes them)

1. **Every pin is verified.** Check-ins stay server-authoritative: QR at the venue plus GPS within
   ~150 m, both required. Client-side checks only improve the UX (clearer errors, earlier
   feedback) and never replace server checks.
2. **Private by default.** Where someone goes at night is sensitive location data. Nothing a user
   does is visible to other users unless they explicitly opt in. Social features show the past, not
   the present, by default. Users can delete single check-ins, export their data, and delete their
   account.
3. **Safety beats virality.** Any feature that reveals people to each other (ratings, matching,
   presence, friends' activity) needs block/report, mutual consent, and an admin moderation path
   before it ships, not after.
4. **No events or ticketing.** Clubsy is not an event-management app. Club profile data (opening
   hours, genres, links) is fine; Event/ticket/cart/payment-for-entry models are not.
5. **Earned, not bought.** Points and badges come from verified check-ins. Monetization must never
   let anyone buy pins, streaks or badges.

## Decisions (binding — don't relitigate these without the user)

- New repository, own git history, own database. No event/ticket/payment concepts carried over.
- Check-in verification is **QR (venue-displayed) + GPS proximity** (~150 m). Both are required; see
  `server/src/controllers/checkInController.js` and `server/src/utils/geo.js`. The rotating QR
  (task 6.4) strengthens the QR half. It doesn't replace either half.
- One check-in per user per club per "night". A night runs 06:00-06:00 UTC (`server/src/utils/night.js`).
- The live "who's out tonight" presence map is **deferred**. When it is eventually built, it must be
  opt-in, mutuals/matches-only, and auto-expiring. This is a hard safety requirement, not a
  nice-to-have; see `BACKLOG.md` item B5. The social foundation (Phase 8) comes first.
- Gamification (B1) is built **computed-first**: streaks, badges and challenges are derived from
  `CheckIn` history on the fly (Phase 6, no schema change). A persisted points ledger only arrives
  when points become spendable (B4).

## Roadmap

Each phase maps to a section in `TASKS.md`. Phases are ordered by what unblocks the pilot first.
Within a phase, tasks are ordered by dependency.

| Phase | Theme | Why now | Night-shift ready? |
|-------|-------|---------|--------------------|
| 1 | Check-in + personal map MVP | Done | Done |
| 2 | Server hardening for a real pilot | Auth bugs (500 on expired token, case-sensitive sign-in), no route tests, no prod config. These would break the pilot on day one | Yes |
| 3 | Client reliability and the check-in experience | Hard-coded `localhost` API, silent error swallowing, expired sessions look like an empty app, no mock-location defence; history and check-in success feel unfinished | Yes |
| 4 | Admin console in the app | Admins can only manage clubs with curl today; pilot ops need list/approve/create/QR/metrics on a phone | Yes |
| 5 | Trust, privacy and pilot launch | 18+ gate, consent, data export, account deletion (a store requirement), removing single check-ins; then deploy, venue onboarding and legal review (human) | Partly (human steps are `[>]`) |
| 6 | Engagement without schema changes | Streaks, badges, challenges, Wrapped recap, rotating QR and club page polish: the retention loop | Yes |
| 7 | Features that need schema changes | Profiles, club enrichment, favourites, notes/vibe ratings, password reset, session revocation, points ledger | No: blocked on 7.0 (database for agents) |
| 8 | Social foundation (friends, block/report, privacy settings, delayed feed) | Prerequisite for B2 ratings, B3 matching and B5 presence | No: needs a design/safety sign-off (8.0) |

`BACKLOG.md` B16-B20 were promoted into `TASKS.md`: 401 handling (B18) became 3.4, grouped history
(B16) became 3.5, the success moment (B17) became 3.6, account deletion (B19) became 5.3, and
removing a single check-in (B20) became 5.4.

### Now / Next / Later

- **Now (pilot blockers):** Phases 2-4, 5.1-5.4, and the human steps 5.5-5.7 and 7.0.
- **Next (retention):** Phase 6, then Phase 7 once agents have a database.
- **Later (growth and revenue):** Phase 8 social foundation, then B2/B3/B5 on top of it, venue
  partner tools (B24) and monetization (B4). See `BACKLOG.md`.

## Open product decisions (the user needs to answer these)

These block specific tasks. Each one says what it unblocks.

1. **Pilot city and launch date.** Decides seed data defaults (2.5), copy, and whether to localize
   (B23, RO/EN). Unblocks 5.6.
2. **Hosting** (e.g. Render, Fly.io or Railway, plus managed Postgres) and a production domain.
   Unblocks 5.5, CORS origins (2.3), and deep links (B30).
3. **Database access for agents.** Pick one: (a) a Postgres container the night shift starts
   through `.nightshift/config.json` `services`, or (b) amend `.nightshift/rules.md` so agents can
   generate migrations offline with
   `prisma migrate diff --from-schema-datamodel <snapshot> --to-schema-datamodel prisma/schema.prisma --script`.
   (a) is recommended because it also enables real integration tests. Unblocks all of Phase 7 (task 7.0).
4. **Email provider** for password reset and notifications (e.g. Resend, Postmark or SES).
   Unblocks 7.6.
5. **Legal copy:** privacy policy, terms, age requirement (18+ assumed), data retention period for
   check-ins. Unblocks 5.7 and the final text for 5.1.
6. **Monetization direction.** Recommended: **venue-side (B2B) first.** Sell verified footfall
   insights and "reward your regulars" perks to clubs (B24), and keep the consumer app free. A
   consumer subscription (B4) only makes sense once there are social or cosmetic features worth
   paying for. Decide before B4/B24 get acceptance criteria.
7. **Social model.** Mutual friends only, or followers too? Recommended: mutual friends only for v1
   (Phase 8). It's simpler and safer, and it matches the B5 constraint.

## Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| QR photographed and shared, plus GPS spoofing, gives remote check-ins | Fake pins, gamification exploits, worthless venue data | 6.4 rotating QR, 3.2 mock-location rejection, 409 duplicate guard (done), check-in failure logging to spot abuse |
| 24 h JWT logs users out between weekly nights out | Churn at the door, at the worst possible moment | 2.3 makes the expiry configurable (default 30 days); 7.7 adds revocation |
| GPS inaccuracy indoors or in dense old towns makes the 150 m check fail legitimately | Frustrated users at the door | 3.2 shows accuracy-aware guidance; pilot step 5.6 measures real-world distances at each venue before launch |
| Location history leak | Severe trust and legal damage | qrSecret gating (done), private by default, data export/deletion, no live presence until Phase 8 + B5 review |
| Social features enable stalking or harassment | Safety incident, app store removal | Phase 8 gate: block/report/moderation first; delayed (not live) activity; mutual consent |
| Night shift stalls on schema work | Roadmap stalls | Phase 6 is deliberately schema-free; 7.0 resolves database access |

## Architecture

- `server/`: Node + Express + Prisma + PostgreSQL. Models: `User`, `Club`, `CheckIn` (see
  `server/prisma/schema.prisma`; initial migration `20261001190159_init`). Plain JWT auth, not a
  third-party provider. One controller/route pair per resource. `venueQrService.js`
  generates and verifies the per-club QR payload (`{clubId, secret}`), `geo.js` holds the
  haversine distance check, `night.js` the 06:00-06:00 UTC night window, and `statsService.js` the
  pure personal-stats aggregation. Tests live in `server/src/__tests__/` and use Jest ESM with
  `jest.unstable_mockModule` to mock `server/src/prisma/client.js`, so no database is needed.
- `client/`: Flutter + GetX. `ClubController` holds the club list, the signed-in user's check-in
  history and stats. The primary screens are `ClubMapPage` (flutter_map/OpenStreetMap),
  `ClubDetailsPage` (with visit summary), `CheckInPage` (camera QR scan via `mobile_scanner` plus
  `geolocator` for GPS), `CheckInHistoryPage` and `ProfilePage` (with stats card). They are
  reachable from `WidgetTree`'s bottom nav (Map / History / Profile). The auth screens
  (`WelcomePage`, `LoginPage`, `RegisterPage`) and `AuthController`/`AuthService` came over from
  `timeit` almost unchanged.
- `server/src/app.js` builds and exports the Express app and `index.js` only listens (B7);
  `server/src/__tests__/app.test.js` holds supertest route tests.
- Planned additions (with the tasks that add them): `server/src/config.js` (2.3), a seed script and `docker-compose.yml` (2.5), a shared
  client API layer `client/lib/services/api_client.dart` (3.1), an admin console under
  `client/lib/views/pages/admin/` (4.x), and `gamificationService.js` (6.1).

## Current state

- Phase 1 is done: the client builds and analyzes clean, there are server unit tests and Flutter
  widget tests, a real Postgres has been provisioned locally by the user, and the init migration
  is committed.
- Built from the backlog: B6 (qrSecret gated by role), B7 (importable app + supertest), B8 (one
  check-in per club per night), B9 (profile stats), B10 (admin QR re-fetch/rotate), B11 (auth
  validation), B12 (check-in failure reasons), B13 (visit summary), B14 (All/Visited map toggle),
  B15 (club search, pagination clamp).

### Known gaps and tech debt (each one is covered by a task)

- `authMiddleware` returns **500** for an expired or malformed JWT, because `jwt.verify` throws
  into the generic catch. It should return 401. 3.4's sign-out-on-401 depends on this. → 2.1
- `signIn` doesn't normalize email, but `signUp` does (`normalizeEmail`), so `Foo@x.com` can sign
  up and then fail to sign in. → 2.1
- `getCurrentUser` exists but isn't routed, so the app never validates a stored token. → 2.1, 3.4
- A malformed JSON body returns 500, and unknown routes return Express's HTML 404. → 2.2
- Open CORS, no rate limiting, no security headers, Prisma logs every query, 24 h tokens. → 2.3
- `approveClub`/`unapproveClub` return 500 instead of 404 for an unknown id (Prisma P2025). No way
  to edit a club. → 2.4
- No seed data, no `.env.example`, no documented dev setup, no CI. → 2.5, 2.6
- The client hard-codes `http://localhost:3000/api` in three services, so it breaks on an Android
  emulator or a real phone. → 3.1
- `ClubController.refresh()` swallows every error, so a server outage looks like "no clubs". → 3.3
- Stats aren't refreshed after a check-in. Mock locations aren't rejected. A permanently denied
  location permission is a dead end. → 3.2
- The static venue QR can be photographed and reused. → 6.4
