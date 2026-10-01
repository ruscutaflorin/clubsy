# Plan: clubsy

## Vision

A social app for clubbing: users check in at clubs (QR scanned on-site + GPS proximity), building a
personal map of places they've visited. Pivoted from `timeit`, a separate event-management app —
clubsy reuses some of its working infrastructure patterns (JWT auth, Express/Prisma scaffolding,
Flutter/GetX app shell) but is a new repository with its own database, designed natively around the
club-checkin concept rather than retrofitted from an Event model.

## Decisions (binding — don't relitigate these without the user)

- New repository, own git history, own database. No event/ticket/payment concepts carried over.
- v1 ("Phase 1", this repo's current state) scope is check-in + personal map only. Everything else
  below is documented, not built.
- Check-in verification is **QR (venue-displayed) + GPS proximity** (~150m) — both required, see
  `server/src/controllers/checkInController.js` and `server/src/utils/geo.js`.
- The live "who's out tonight" presence map is **deferred**, and when it is eventually built it
  must be opt-in, mutuals/matches-only, and auto-expiring — a hard safety requirement, not a
  nice-to-have. See `BACKLOG.md` item B5.

## Out of scope for now

Everything in `BACKLOG.md` (gamification, ratings, matching, points economy/subscriptions, live
presence) is future work requiring explicit approval (`status: approved` on the backlog item, then
promoted into `TASKS.md`) before any agent builds it.

## Architecture

- `server/`: Node + Express + Prisma + PostgreSQL. Models: `User`, `Club`, `CheckIn` (see
  `server/prisma/schema.prisma`). Plain JWT auth, not a third-party provider. One controller/route
  pair per resource; `venueQrService.js` generates/verifies the per-club QR payload
  (`{clubId, secret}`); `geo.js` has the haversine distance check.
- `client/`: Flutter + GetX. `ClubController` holds both the club list and the signed-in user's
  check-in history; `ClubMapPage` (flutter_map/OpenStreetMap), `ClubDetailsPage`, `CheckInPage`
  (camera QR scan via `mobile_scanner` + `geolocator` for GPS), `CheckInHistoryPage`, `ProfilePage`
  are the primary screens, reachable from `WidgetTree`'s bottom nav (Map / History / Profile).
  Auth screens (`WelcomePage`, `LoginPage`, `RegisterPage`) and `AuthController`/`AuthService` are
  carried over from `timeit` near-verbatim — they're generic and had no event coupling.

## Current state / known gaps

See `TASKS.md` Phase 1 for exactly what's unverified: `flutter pub get` has never been run against
the newly added packages, there are no tests yet, and no database migration has been run (no
Postgres was available while this was scaffolded) — `server/.env`'s `DATABASE_URL`/`JWT_SECRET`
are placeholders.
