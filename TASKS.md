# Tasks

Ordered work for the night shift. Keep the format `- [ ] <id> <text>` (ids like `1.2`).
`[ ]` open · `[x]` done · `[>]` needs you (skipped by agents) · `[!]` failed twice (reason in the night report).
A failed task blocks the rest of its phase until you reopen it.

Write each task so an agent can finish and verify it in one session (roughly under 45 minutes),
and say how it is verified (which test proves it).

## Phase 1 — Finish the check-in + personal map MVP

The scaffold (schema, Express controllers/routes, Flutter pages/controllers/services) already
exists but is unverified: no `flutter pub get`, no `flutter analyze`, no tests, and no database
migration has been run yet. These tasks get Phase 1 to a genuinely working, tested state.

- [ ] 1.1 Get `client/` building: run `flutter pub get`, resolve any dependency version conflicts
      in `client/pubspec.yaml` (`geolocator`, `mobile_scanner`, `flutter_map`, `latlong2`, `lottie`
      were added without verifying they resolve against the installed Flutter SDK), then run
      `flutter analyze --no-fatal-infos` and fix every reported issue under `client/lib/`.
      Verified by: `cd client && flutter pub get` and `cd client && flutter analyze --no-fatal-infos`
      both exit 0.
- [ ] 1.2 Confirm `server/` boots without a live database connection (Prisma connects lazily, so
      the process should log "Server is running on port 3000" immediately even with an empty
      `DATABASE_URL`). Fix anything that throws before that log line. Run it briefly with a timeout
      and kill it — never leave a long-running process. Verified by: the log line appears and the
      process exits cleanly when stopped.
- [ ] 1.3 Add unit tests for the two DB-free pure pieces of server logic: `distanceInMeters` in
      `server/src/utils/geo.js` (a couple of coordinate pairs with known real-world distances,
      asserted within a reasonable tolerance) and `generateQrSecret`/`verifyClubQrPayload` in
      `server/src/services/venueQrService.js` (valid payload, wrong secret, malformed JSON).
      Verified by: `cd server && pnpm test` passes.
- [ ] 1.4 Add Flutter widget tests for `ClubDetailsPage` and `CheckInHistoryPage` using fixture
      `ClubModel`/`CheckInModel` data — no real HTTP or GetX service calls; inject fixture data
      directly rather than hitting `ClubService`/`CheckInService`. Verified by:
      `cd client && flutter test` passes.
- [>] 1.5 Provision a real PostgreSQL database for clubsy (local Postgres, Docker, or a hosted
      instance) and set `server/.env`'s `DATABASE_URL` and `JWT_SECRET` — no local Postgres was
      running during scaffolding, and generating real secrets isn't something an agent should do.
- [>] 1.6 Once 1.5 is done, run `cd server && npx prisma migrate dev --name init` yourself and
      commit the generated `server/prisma/migrations/` folder, or reopen this as `[ ]` for the
      night shift to do it. Depends entirely on 1.5 — leave as `[>]` until then.
