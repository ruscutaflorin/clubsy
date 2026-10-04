# Tasks

Ordered work for the night shift. Keep the format `- [ ] <id> <text>` (ids like `1.2`).
`[ ]` open · `[x]` done · `[>]` needs you (skipped by agents) · `[!]` failed twice (reason in the night report).
A failed task blocks the rest of its phase until you reopen it.

Write each task so an agent can finish and verify it in one session (roughly under 45 minutes),
and say how it is verified (which test proves it).

How to read the tasks below (Phases 2+):

- **Goal** is the user-facing reason, **Scope** is what to build (with the files to touch), **Out**
  is explicitly not part of the task, and **Verified by** is the one check that proves it.
- **Depends on** names tasks or `BACKLOG.md` items that must land first. If a dependency hasn't
  landed, end with `BLOCKED: waiting on <id>`. Don't build the dependency inside this task.
- No task in Phases 2-6 changes `server/prisma/schema.prisma`. If you find you need a schema
  change, stop with `BLOCKED: needs schema change` and explain why. Schema work lives in Phase 7.
- Server tests follow `server/src/__tests__/checkInController.test.js`: Jest ESM with
  `jest.unstable_mockModule("../prisma/client.js", ...)`, and no database. Client tests use fixture
  models and fake or injected services, with no real HTTP.
- `BACKLOG.md` B16-B20 were promoted into this file (3.4, 3.5, 3.6, 5.3, 5.4). Build them from
  here, not from the backlog.

## Phase 1 — Finish the check-in + personal map MVP

The scaffold (schema, Express controllers/routes, Flutter pages/controllers/services) already
exists but is unverified: no `flutter pub get`, no `flutter analyze`, no tests, and no database
migration has been run yet. These tasks get Phase 1 to a genuinely working, tested state.

- [x] 1.1 Get `client/` building: run `flutter pub get`, resolve any dependency version conflicts
      in `client/pubspec.yaml` (`geolocator`, `mobile_scanner`, `flutter_map`, `latlong2`, `lottie`
      were added without verifying they resolve against the installed Flutter SDK), then run
      `flutter analyze --no-fatal-infos` and fix every reported issue under `client/lib/`.
      Verified by: `cd client && flutter pub get` and `cd client && flutter analyze --no-fatal-infos`
      both exit 0.
- [x] 1.2 Confirm `server/` boots without a live database connection (Prisma connects lazily, so
      the process should log "Server is running on port 3000" immediately even with an empty
      `DATABASE_URL`). Fix anything that throws before that log line. Run it briefly with a timeout
      and kill it — never leave a long-running process. Verified by: the log line appears and the
      process exits cleanly when stopped.
- [x] 1.3 Add unit tests for the two DB-free pure pieces of server logic: `distanceInMeters` in
      `server/src/utils/geo.js` (a couple of coordinate pairs with known real-world distances,
      asserted within a reasonable tolerance) and `generateQrSecret`/`verifyClubQrPayload` in
      `server/src/services/venueQrService.js` (valid payload, wrong secret, malformed JSON).
      Verified by: `cd server && pnpm test` passes.
- [x] 1.4 Add Flutter widget tests for `ClubDetailsPage` and `CheckInHistoryPage` using fixture
      `ClubModel`/`CheckInModel` data — no real HTTP or GetX service calls; inject fixture data
      directly rather than hitting `ClubService`/`CheckInService`. Verified by:
      `cd client && flutter test` passes.
- [x] 1.5 Provision a real PostgreSQL database for clubsy (local Postgres, Docker, or a hosted
      instance) and set `server/.env`'s `DATABASE_URL` and `JWT_SECRET` — no local Postgres was
      running during scaffolding, and generating real secrets isn't something an agent should do.
- [x] 1.6 Once 1.5 is done, run `cd server && npx prisma migrate dev --name init` yourself and
      commit the generated `server/prisma/migrations/` folder, or reopen this as `[ ]` for the
      night shift to do it. Depends entirely on 1.5 — leave as `[>]` until then.

## Phase 2 — Server hardening for a real pilot

Goal: no 500s for normal mistakes, every route testable without a database, safe production
defaults, and a one-command local dev setup. No schema changes.

- [x] 2.1 Fix the auth failure modes: return 401 for expired or invalid tokens, make sign-in
      case-insensitive, and expose `GET /api/auth/me`.
      - Goal: today an expired JWT makes `authMiddleware` return **500** (`jwt.verify` throws into
        the generic catch), so the app can't tell "log in again" from "server broken". The
        sign-out-on-401 in 3.4 depends on this. Sign-up lowercases email (`normalizeEmail`) but sign-in
        doesn't, so `Ana@X.com` can't sign in after signing up.
      - Scope: in `server/src/middlewares/authMiddleware.js`, catch `jwt.TokenExpiredError` and
        return `401 {message: "Session expired"}`, and catch `jwt.JsonWebTokenError` and return
        `401 {message: "Invalid token"}`. Keep 500 for unexpected errors. Also require the
        `Bearer ` prefix (today `split(" ")[1]` accepts any scheme). Remove the remaining
        `console.log` of user ids, or put it behind `NODE_ENV !== "production"`. In
        `server/src/routes/authRoutes.js`, add `.isEmail().normalizeEmail()` to
        `signInValidation`'s email rule, using the same normalizer options as sign-up, and route
        `GET /me` → `getCurrentUser` behind `authMiddleware`. `getCurrentUser` must also return
        `createdAt`. Never return `password`.
      - Out: refresh tokens, logout-everywhere (7.7), rate limiting (2.3).
      - Verified by: new cases in `server/src/__tests__/authMiddleware.test.js` (an expired token
        signed with a past `exp` → 401 "Session expired"; a garbage token → 401; a `Basic xyz`
        header → 401; a database error → 500) and in `authController.test.js` (`getCurrentUser`
        returns the user without `password`; unknown user → 404). Also a validation test in which
        sign-in with `ANA@X.COM` ends up calling `prisma.user.findUnique` with `ana@x.com`. Run the
        `signInValidation` chain against a fake req with `express-validator`'s `run()`. `pnpm test`
        passes.

- [x] 2.2 Finish the route-level safety net: JSON 404s, a 400 for malformed JSON, and supertest
      coverage for auth, clubs and stats.
      - Goal: B7 split `server/src/app.js` from `index.js` and covered `POST /api/check-ins` and
        `GET /api/check-ins/me` in `server/src/__tests__/app.test.js`. The other route groups still
        have no end-to-end test of middleware order and validation chains. Unknown routes return
        Express's HTML 404, and a malformed JSON body falls into the generic error handler as a
        500.
      - Scope: in `server/src/app.js`, add a JSON 404 handler after the routes
        (`404 {message: "Not found"}`). In the error middleware, map `express.json()` parse errors
        (`err.type === "entity.parse.failed"`) to `400 {message: "Malformed JSON body"}`, keep 500
        for everything else, and stop echoing the error object in production logs beyond
        `err.message` plus the stack. Add supertest suites next to `app.test.js`, reusing its
        mocking and JWT-signing setup (extract the shared setup into
        `server/src/__tests__/helpers/testApp.js` if that keeps it simple):
        `POST /api/auth/signup` (400 `{errors}` for a bad email, 201 with a token),
        `POST /api/auth/signin` (401 for a wrong password), `GET /api/clubs` as USER (no
        `qrSecret` on any club) and as ADMIN (has it), `GET /api/clubs/:id` for an unapproved club
        as USER (404), `PATCH /api/clubs/:id/approve` as USER (403),
        `GET /api/check-ins/me/stats`, `GET /health`, an unknown route (JSON 404), and a malformed
        JSON body (400).
      - Out: a real database or integration tests against Postgres (needs 7.0).
      - Verified by: `cd server && pnpm test` runs the new suites with `DATABASE_URL` unset, with no
        open-handle warning. `timeout 5 node server/src/index.js` still prints the boot line.

- [x] 2.3 Production-safe server configuration: config module, security headers, CORS
      allowlist, rate limits, quieter logs, longer sessions.
      - Goal: the pilot backend can face the internet. Today CORS is open to every origin, there's
        no brute-force protection on sign-in, Prisma logs every SQL query, and sessions expire
        after 24 h, which logs regulars out between weekly nights out.
      - Scope: new `server/src/config.js` that reads env once and exports typed values with
        defaults: `PORT`, `NODE_ENV`, `JWT_SECRET`, `JWT_EXPIRES_IN` (default `"30d"`),
        `CORS_ORIGINS` (comma-separated; unset means allow all in non-production and none in
        production), `RATE_LIMIT_AUTH_PER_MIN` (default 10) and `RATE_LIMIT_CHECKIN_PER_MIN`
        (default 6). Use it in `authController.js` (`expiresIn`), `app.js` and
        `server/src/prisma/client.js` (log `["warn","error"]` in production,
        `["query","info","warn","error"]` only when `PRISMA_LOG_QUERIES=1`). Add `helmet` and
        `express-rate-limit`, keyed by IP on `/api/auth/signin` and `/api/auth/signup`, and by
        `req.user.id` on `POST /api/check-ins` (mount that limiter after `authMiddleware`). Add
        `GET /health/ready`, which runs `prisma.$queryRaw\`SELECT 1\`` with a 2 s timeout and
        returns 200 or 503. Keep `/health` database-free for the boot check. Commit
        `server/.env.example` listing every variable with a comment (never real secrets).
      - Out: an HTTPS terminator (the host provides it), refresh tokens.
      - Verified by: supertest cases in a new `routes.security.test.js`. The 11th sign-in within a
        minute returns 429. A disallowed `Origin` gets no `Access-Control-Allow-Origin` header when
        `CORS_ORIGINS` is set. `/health/ready` returns 503 when the mocked `$queryRaw` rejects and
        200 when it resolves. A signed token's `exp - iat` equals 30 days by default. Unit tests
        for `config.js` defaults. `pnpm test` passes and `timeout 5 node server/src/index.js`
        still prints the boot line.
      - Depends on: 2.2.

- [x] 2.4 Admin club endpoints: 404 instead of 500 for unknown ids, editing a club, and stricter
      validation.
      - Goal: the admin console (Phase 4) needs reliable endpoints. Approving a deleted or mistyped
        club id currently returns 500 (Prisma `P2025`), and a club with a typo in its coordinates
        can't be fixed.
      - Scope: in `server/src/controllers/clubController.js`, map Prisma `P2025` to
        `404 {message: "Club not found"}` in `approveClub`/`unapproveClub` (one small helper that
        all club handlers share). Add `PATCH /api/clubs/:id` (admin only) for a partial update of
        `name`, `address`, `city`, `latitude`, `longitude` and `imageUrl`, validated with
        `express-validator` `optional()` chains (lat/lng ranges as in `clubValidation`,
        `imageUrl` `isURL({protocols:["https"]})`, strings trimmed and non-empty when present).
        It returns the full club, including `qrSecret`, since the caller is an admin, and it
        rejects any attempt to set `qrSecret`, `isApproved` or `id` (use rotate/approve for
        those). Add `isURL` validation to `imageUrl` in `clubValidation` for create as well. Add
        `PATCH` to the routes in `server/src/routes/clubRoutes.js`.
      - Out: deleting clubs (check-ins reference them, so a soft-delete would need schema),
        uploading images.
      - Verified by: `clubController.test.js` and supertest cases. Unknown id on approve,
        unapprove and PATCH → 404. A non-admin PATCH → 403. `latitude: 200` → 400 `{errors}`. A
        body with `qrSecret` → 400 and no update call. A valid partial update calls
        `prisma.club.update` with only the provided fields. `pnpm test` passes.
      - Depends on: 2.2.

- [x] 2.5 One-command local dev environment: Postgres in Docker, `.env.example`, seed data with
      venue QR images, and a README.
      - Goal: anyone (human or agent with Docker) can go from clone to a working map with clubs in
        minutes. Today the database is empty and the only way to add a club is curl as an admin
        who doesn't exist yet.
      - Scope: `docker-compose.yml` at the repo root with `postgres:16-alpine`, a named volume,
        port 5432 and a healthcheck. `server/prisma/seedData.js` exports a pure
        `buildSeedClubs({center, count})` that returns about 10 **fictional** clubs (never real
        venue names) spread within ~2 km of `center` (default Bucharest Old Town
        `44.4305, 26.1015`), with deterministic names, addresses and coordinates, all
        `isApproved: true`, and two in a second city so the stats show "2 cities".
        `server/prisma/seed.js` upserts those clubs by name with fresh `generateQrSecret()`
        secrets, upserts an ADMIN from `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` (it skips with a
        warning if they're unset, and never hard-codes a password), and writes each club's QR PNG
        to `server/seed-output/<slug>.png` using `qrcode`'s `toFile`. Add `"prisma": {"seed":
        "node prisma/seed.js"}` and a `"seed"` script to `server/package.json`, and add
        `seed-output/` to `server/.gitignore`. Root `README.md`: prerequisites, `docker compose up
        -d`, `.env` setup, `pnpm prisma migrate dev`, `pnpm seed`, running the server, running the
        app on an Android emulator (`--dart-define=API_BASE_URL=http://10.0.2.2:3000/api`, see
        3.1), and how to test a check-in by displaying a seed QR on a second screen while faking
        GPS at the club's coordinates.
      - Out: running the seed (needs a database), CI services.
      - Verified by: Jest `seedData.test.js`: 10 clubs, unique names, every coordinate within
        2.5 km of `center` (use `distanceInMeters`) except the second-city ones, deterministic
        output across calls, and no field named `qrSecret` in the pure output (secrets are added at
        write time). `node --check server/prisma/seed.js` exits 0. `pnpm test` passes.

- [x] 2.6 Continuous integration on GitHub Actions mirroring the night-shift gates.
      - Goal: every push and PR to `develop`/`main` runs the same checks the night shift trusts, so
        human commits can't silently break the gates.
      - Scope: `.github/workflows/ci.yml` with two jobs. **server**: `pnpm/action-setup` (version
        from `packageManager` in `server/package.json`), Node 20, `pnpm install
        --frozen-lockfile`, `pnpm test`, and `npx prisma validate` with a dummy `DATABASE_URL`.
        **client**: `subosito/flutter-action` with `channel: stable` and `flutter-version: 3.47.3`
        (the local toolchain: Flutter 3.47.3 / Dart 3.13.3, satisfies `sdk: ^3.13.3`), then `flutter pub get`, `dart format --set-exit-if-changed .`, `flutter
        analyze --no-fatal-infos` and `flutter test`. Cache the pnpm store and the pub cache.
        Trigger on push and pull_request for `develop` and `main`. The CI is deliberately
        stricter than the local gates: keep `npx prisma validate` and
        `dart format --set-exit-if-changed .` exactly as listed; use plain `pnpm test` (never
        `pnpm test -- ...`, which makes Jest find no tests). No README badge: the repo has no
        GitHub remote yet, so the owner adds it after the first push; README may get one plain
        sentence saying CI lives in `.github/workflows/ci.yml`.
      - Out: deploy jobs, building release artifacts, publishing.
      - Verified by: the workflow file parses (`npx --yes yaml-lint .github/workflows/ci.yml`, or
        a `node -e` YAML parse with the `yaml` package if that's easier). Every command in it is
        one that exits 0 locally in this session (list them in the commit message). The human
        confirms the first green run after pushing.

## Phase 3 — Client reliability and the check-in experience

Goal: the app works on a real phone against a real server, failures are visible and recoverable,
the check-in is harder to fake, and the two screens people use most (the check-in result and the
history) feel finished. No schema changes.

- [x] 3.1 One configurable API layer for the client: base URL from `--dart-define`, an injectable
      HTTP client, and one error parser.
      - Goal: the three services hard-code `http://localhost:3000/api`, which is unreachable from an
        Android emulator (`10.0.2.2`) or a phone, so the app can't be piloted. Error parsing is
        copy-pasted three times with slightly different behaviour.
      - Scope: new `client/lib/services/api_config.dart` with
        `const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue:
        'http://localhost:3000/api')` plus a doc comment showing the emulator and device values.
        New `client/lib/services/api_client.dart` with `ApiClient({http.Client? client, required
        Future<String?> Function() tokenProvider})`. It exposes `get`/`post`/`patch`/`delete`
        returning decoded JSON, builds auth headers, applies a 15 s timeout, and throws a single
        `ApiException(statusCode, message, {fieldErrors, body})` parsed by a pure
        `ApiException.fromResponse(int status, String body)` that handles `{message}`,
        `{errors:[{msg}]}`, non-JSON bodies and timeouts ("The server didn't respond — check your
        connection"). Refactor `AuthService`, `ClubService` and `CheckInService` to use it, keeping
        their public method signatures. `CheckInException` (B12) should keep working; make it
        extend or wrap `ApiException` so `distanceMeters` survives. Give `ApiClient` an optional
        `onUnauthorized` callback, called exactly once per 401 response, which 3.4 wires up.
      - Out: retries, caching (3.3), certificate pinning.
      - Verified by: `client/test/api_client_test.dart` using `MockClient` from
        `package:http/testing.dart`. The Authorization header is set when a token exists. A
        missing token throws "Not authenticated" before any request. 400 `{errors}` → `fieldErrors`
        and the first message. 500 with an HTML body → generic message. A timeout (use a
        `MockClient` that never completes plus a short injected timeout) → connection message.
        Existing `check_in_exception_test.dart` still passes. `flutter test` and `flutter analyze
        --no-fatal-infos` pass.

- [x] 3.2 Make check-ins robust at the door: accurate location, mock-location rejection, a usable
      scanner, and fresh stats afterwards.
      - Goal: the check-in is the product, and it happens in a dark, crowded street with a phone at
        10% battery. Today the scanner keeps firing during a request, location has no timeout or
        accuracy setting, a permanently denied permission is a dead end, mock GPS goes
        undetected, and Profile stats stay stale after a successful check-in.
      - Scope (client, `client/lib/views/pages/check_in_page.dart`): use a `MobileScannerController`
        and `stop()` it while processing, then `start()` it again after a failure. Add a torch
        toggle in the AppBar. Call `Geolocator.getCurrentPosition(locationSettings:
        LocationSettings(accuracy: LocationAccuracy.best, timeLimit: Duration(seconds: 12)))` and
        turn a timeout into "Couldn't get a GPS fix — step outside the entrance and try again".
        For `deniedForever`, show a button that calls `Geolocator.openAppSettings()`, and for
        disabled services, `Geolocator.openLocationSettings()`. Send `isMocked:
        position.isMocked` and `accuracyMeters: position.accuracy` with the check-in. Put all
        user-facing wording in a pure `locationProblemMessage(LocationProblem)` so it can be
        tested. Add `HapticFeedback.mediumImpact()` on a detected code. In
        `client/lib/src/core/controllers/club_controller.dart`, after a successful check-in,
        re-fetch stats (`getMyStats`) without blocking the success UI.
      - Scope (server): in `checkInValidation` (`server/src/routes/checkInRoutes.js`), add
        `isMocked` as an optional boolean and `accuracyMeters` as an optional float ≥ 0. In
        `checkIn`, `isMocked === true` → `400 {message: "Mock locations aren't allowed for
        check-ins"}`, checked **before** the QR check so the attempt reveals nothing about the QR.
        Log each failed check-in reason as one structured line (`console.warn(JSON.stringify({evt:
        "checkin_failed", reason, userId, clubId}))`), which is the input for the
        check-in-success-rate metric. The 150 m rule and QR rule are unchanged, and accuracy is
        not used to relax them.
      - Out: device attestation (Play Integrity/App Attest), persisting failures (schema), the
        success dialog (3.6).
      - Verified by: Jest: `isMocked: true` → 400 and `findUnique` not called; `isMocked:
        "yes"` → 400 `{errors}`; missing `isMocked` still → 201 (older clients keep working).
        Flutter: unit tests for `locationProblemMessage` (each problem type), and a
        `ClubController` test with a fake service showing stats are re-fetched after `checkIn`.
        `pnpm test`, `flutter test` and `flutter analyze --no-fatal-infos` pass.
      - Depends on: 3.1 (uses `ApiClient`).

- [x] 3.3 Visible error states and an offline cache for the map, history and profile.
      - Goal: `ClubController.refresh()` catches every error silently, so a server outage, an
        expired session and "you have no check-ins" all look the same: an empty screen. In a club
        basement with no signal, the map should still show the user's pins.
      - Scope: in `ClubController`, add `loadError` (`RxnString`) and `isOffline` (`RxBool`).
        `refresh()` sets them from `ApiException`/socket errors instead of swallowing them, and
        still ignores the "Not authenticated" case at startup. New
        `client/lib/services/local_cache.dart` with `LocalCache` that stores the last successful
        clubs, check-ins and stats JSON in `SharedPreferences` (one key each, with a `savedAt`
        timestamp). The controller hydrates from the cache in `onInit` before the network call and
        writes after each successful refresh. Clear the cache in `AuthController.signOut()`, since
        another user must never see the previous user's map. Add a reusable
        `client/lib/widgets/error_banner_widget.dart` ("Couldn't refresh — showing data from
        21:04 · Retry") and use it on `ClubMapPage`, `CheckInHistoryPage` and `ProfilePage`. Each
        page gets a distinct empty state ("No check-ins yet — scan a club's QR to add your first
        pin") that differs from the error state.
      - Out: caching club images, offline check-ins (deliberately unsupported: a check-in must be
        verified live).
      - Verified by: controller tests with fake services and
        `SharedPreferences.setMockInitialValues`. A failure sets `loadError` and keeps the cached
        clubs. A success clears `loadError` and writes the cache. Sign-out empties the cache. A
        widget test shows the banner with a Retry button that calls `refresh()` again. `flutter
        test` passes.
      - Depends on: 3.1.

- [x] 3.4 Session lifecycle: sign out cleanly on any 401, and validate the stored session at
      startup (absorbs `BACKLOG.md` B18).
      - Goal: JWTs expire. Today an expired token makes every call fail with a generic "Failed to …",
        so the map and history look empty or broken, and the only way out is to log out by hand.
        "Has a token in SharedPreferences" also counts as logged in, even if the token expired weeks
        ago or the account was deleted (5.3).
      - Scope (runtime 401): in `client/lib/src/core/controllers/auth_controller.dart`, register
        the `ApiClient.onUnauthorized` callback from 3.1. It calls `signOut()` (which also clears the
        3.3 cache), then `Get.offAllNamed('/login')`, then shows a "Session expired, please sign in
        again" snackbar. Guard it so several parallel 401s (for example the three calls in
        `ClubController.refresh()`) trigger one sign-out and one snackbar. 401s from
        `/auth/signin` (a wrong password) must **not** trigger it: exclude auth endpoints.
      - Scope (startup): when a token exists, `checkAuthStatus()` calls `GET /api/auth/me`
        (task 2.1). 200 → update the cached user, since name, email or role may have changed.
        401/404 → the same sign-out path. Network error or timeout → stay signed in with the cached
        user (3.3 offline mode). Re-validate on app resume when more than 6 h have passed since the
        last check (`AppLifecycleListener`). Expose `isAdmin` (`user?['role'] == 'ADMIN'`) for
        Phase 4.
      - Out: refresh tokens, multi-device sign-out (7.7).
      - Verified by: tests using `MockClient`. A 401 from `getClubs` and from `getMyCheckIns`
        invokes the callback exactly once and throws. Three parallel 401s produce one sign-out. A
        401 from sign-in doesn't invoke it. A 200 doesn't. `AuthController` tests with an injected
        fake `AuthService`: startup 200 updates the user, startup 401 clears the token and sets
        `isAuthenticated` false, a startup network error keeps `isAuthenticated` true, and `isAdmin`
        is true only for ADMIN. `flutter test` and `flutter analyze --no-fatal-infos` pass.
      - Depends on: 2.1 (route and 401s), 3.1.

- [x] 3.5 Check-in history as a diary of nights, with readable dates (absorbs `BACKLOG.md` B16).
      - Goal: `CheckInHistoryPage` prints a raw `DateTime.toLocal()` string
        (`2026-09-12 01:34:56.000`) in one flat list. The history is the text view of the personal
        map and should read like a diary ("Sat 12 Sep · 2 clubs"), not a debug log.
      - Scope: client only. Add pure helpers in `client/lib/data/classes/check_in_grouping.dart`:
        `nightOf(DateTime local)` (a night runs 06:00 to 06:00, so 02:00 belongs to the previous
        evening; this matches the server's `night.js`, but in local time for display),
        `groupByNight(List<CheckInModel>)` (ordered groups, newest first, and items inside a group
        newest first), and hand-rolled `formatNightLabel` / `formatTime`, so `intl` isn't needed
        yet (B23 brings it). In `client/lib/views/pages/check_in_history_page.dart`, add a section
        header per night ("Sat 12 Sep · 2 clubs"), tiles with the club name, city and `HH:mm`, and
        a "This month: 3 nights · 5 clubs" summary line at the top. Tapping a tile opens
        `ClubDetailsPage`. Keep the existing empty state (or the 3.3 one) and pull-to-refresh.
      - Out: server changes, filtering, notes and ratings (7.4).
      - Verified by: unit tests (23:00 and 02:00 the next day end up in one group while 07:00 starts
        a new one; groups and the items inside them are ordered newest first; the label format is
        right, including a year suffix for a previous year, as in "Sat 12 Sep 2025"). A widget test
        pumps `CheckInHistoryPage` with fixture `myCheckIns` across two nights and finds both
        headers and an `HH:mm` time. `flutter test` and `flutter analyze --no-fatal-infos` pass.

- [x] 3.6 The check-in success moment: "New place on your map!" or "Visit #N" (absorbs
      `BACKLOG.md` B17).
      - Goal: a successful check-in, the product's core action, ends with a generic snackbar and
        `Get.back()`. Celebrating a first visit (a new pin) rewards exactly the behaviour the product
        is built on, and gives Phase 6 a place to announce badges.
      - Scope: client only. Add a pure `checkInOutcome(clubId, previousCheckIns)` in
        `client/lib/data/classes/check_in_outcome.dart` that returns `{isFirstVisit, visitNumber,
        totalClubsVisited, isNewCity}`, computed **before** the new record is added. `ClubController.checkIn`
        returns the outcome alongside the record. New `client/lib/widgets/check_in_success_sheet.dart`
        is a bottom sheet with a short scale-in animation (no new dependency). It shows "New place
        on your map! That's 7 clubs." (or "…and your first in Cluj!" when `isNewCity`), or "Visit #3
        at Club X". It has an `extras` slot that 6.2 fills with unlocked badges, a primary "View on
        map" button that pops back to the map centred on the club, and a secondary "Done" button.
        Replace the snackbar in `client/lib/views/pages/check_in_page.dart` with this sheet.
      - Out: server changes, points, streaks, sharing.
      - Verified by: unit tests for `checkInOutcome` (no history → first visit, total 1; two earlier
        visits to the same club → visit #3; visits to other clubs only change the total; a first
        club in a new city → `isNewCity`). A widget test renders the sheet from fixture outcomes and
        finds the first-visit text and the "Visit #3" text. `flutter test` passes.

## Phase 4 — Admin console in the app

Goal: pilot operations (adding venues, approving them, printing and rotating QR codes, watching
pilot metrics) can be done from an admin's phone, with no curl. Admin screens are pushed with
`Get.to()` from Profile and are only visible when `AuthController.isAdmin` is true. The server
already enforces `adminMiddleware`, so the UI gate is only for convenience.

- [x] 4.1 Admin club list: pending/approved filter, approve and unapprove, and view the venue QR.
      - Scope: `client/lib/services/admin_service.dart` (via `ApiClient`) with `listAllClubs()`
        (`GET /api/clubs?limit=50`, paginated until `pages` is reached; admins already receive
        unapproved clubs and `qrSecret`), `approve(id)`, `unapprove(id)`, `getQr(id)` and
        `rotateQr(id)`. `client/lib/src/core/controllers/admin_controller.dart` takes an
        injectable `AdminService`. `client/lib/views/pages/admin/admin_clubs_page.dart` has
        filter chips (All / Pending / Approved) with counts, a list tile per club (name, city,
        status chip) and an approve/unapprove switch with optimistic update and rollback on error.
        Tapping a club opens `admin_club_qr_page.dart`, which decodes the `data:image/png;base64,`
        URL with `UriData.parse(...).contentAsBytes()` and shows it full-screen with a "Rotate QR"
        action. That action needs a confirm dialog: "The printed QR at the venue will stop working
        immediately." Add an "Admin" tile to `ProfilePage`, shown only for admins. Use
        `Obx`/`isAdmin` from 3.4, or `user?['role']` if 3.4 hasn't landed.
      - Out: create/edit forms (4.2), metrics (4.3), user management.
      - Verified by: controller tests with a fake service: filter counts, an optimistic approve
        rolls back when the service throws, and rotate replaces the stored QR. Widget tests: the
        Profile admin tile is hidden for USER and shown for ADMIN, and the QR page renders an
        `Image` from a fixture 1×1 PNG data URL. `flutter test` passes.
      - Depends on: 3.1 (2.4 for clean 404s, but not required to start).

- [x] 4.2 Admin create and edit club form, with "use my location", a map preview and QR sharing
      for printing.
      - Scope: `client/lib/views/pages/admin/admin_club_form_page.dart`, used for both create
        (`POST /api/clubs`) and edit (`PATCH /api/clubs/:id`, task 2.4). Fields: name, address,
        city, latitude, longitude, image URL. Pure validators live in
        `client/lib/data/classes/club_form_validation.dart` (required, lat/lng ranges, https URL),
        mirroring the server rules. A "Use my current location" button fills lat/lng from
        `Geolocator` (admins typically stand at the entrance). A small non-interactive
        `FlutterMap` preview shows the pin and the 150 m check-in radius as a `CircleLayer`, so
        the admin can see whether the entrance falls inside it. Server field errors (`{errors}` via
        `ApiException.fieldErrors`) map back onto the matching fields. After create, open the QR
        page from 4.1. On the QR page, add "Share / print" using `share_plus` (new dependency): it
        writes the PNG to a temp file and shares it with the club name as the subject. On the
        server's `generateClubQr`, use `errorCorrectionLevel: "H"` and `width: 1024` so prints
        scan from a distance (update `venueQrService.test.js` if it asserts sizes).
      - Out: image upload, deleting clubs, bulk import.
      - Verified by: unit tests for each validator, including boundaries (`90`, `90.0001`, `-180`,
        `http://` rejected). A widget test fills the form and checks that submit is disabled until
        it's valid. A controller test shows server field errors land on the right fields. `pnpm
        test`, `flutter test` and `flutter analyze --no-fatal-infos` pass.
      - Depends on: 4.1, 2.4.

- [x] 4.3 Pilot metrics for admins: a server aggregation endpoint and a dashboard card.
      - Goal: decide from data whether the pilot works (see the north-star metric and exit criteria
        in `PLAN.md`) without running SQL by hand.
      - Scope: `server/src/services/metricsService.js` with a pure
        `computePilotMetrics({users, checkIns, now, days})` that returns `signups`,
        `activeCheckInUsers` (WACU when `days=7`), `checkIns`, `nightsOut` (distinct user+night
        pairs, using `nightStart` from `night.js`), `activationRate` (signups in the window who
        checked in within 14 days of signing up), `returningUsers` (users with check-ins on 2+
        distinct nights in the window), `topClubs` (top 5 by check-ins: id, name, count, unique
        visitors), and a `daily` series of `{date, checkIns, activeUsers}`. Add
        `server/src/controllers/adminController.js` and `server/src/routes/adminRoutes.js` with
        `GET /api/admin/metrics?days=7|30|90` (default 7, anything else → 400). It's admin only and
        mounted at `/api/admin` in `app.js`. It fetches `user` (`id`, `createdAt` only) and
        `checkIn` (`userId`, `clubId`, `checkedInAt` plus the club name) rows within the window
        plus 14 days. Responses contain **aggregates only: no user ids, emails or names**. Client:
        `admin_metrics_page.dart`, reached from the admin console, with a 7/30/90 segmented
        control, KPI tiles (WACU, check-ins, activation %, returning users) and a simple bar row
        for the daily series (plain `Container` bars, no chart dependency).
      - Out: venue-facing insights (B24), exporting, real-time updates.
      - Verified by: Jest unit tests for `computePilotMetrics`: an empty dataset gives zeros and no
        NaN; two check-ins by one user on the same night count as 1 night out; activation counts
        only signups inside the window; `topClubs` ties are ordered by name; the output contains no
        `email` key at any depth. A supertest case: USER → 403, `days=5` → 400. A Flutter widget
        test renders the KPI tiles from a fixture model. `pnpm test` and `flutter test` pass.
      - Depends on: 2.2, 4.1.

## Phase 5 — Trust, privacy and pilot launch

Goal: the app can legally and safely go in front of real people in one city. 5.1-5.4 are agent
work; 5.5-5.7 are yours.

- [x] 5.1 Register consent, an 18+ gate, Privacy/Terms screens, and permission explainers before
      the OS prompts.
      - Goal: clubs are 18+ and Clubsy stores location history. Users must confirm their age and
        accept the terms before an account exists. Explaining why the app needs the camera and
        location before the OS dialog appears raises grant rates, and a denial blocks the core
        action.
      - Scope: on `client/lib/views/pages/register_page.dart`, add two required checkboxes ("I'm 18
        or older", and "I accept the Terms and Privacy Policy" with tappable links). The Register
        button stays disabled until both are checked. New `client/lib/views/pages/legal_page.dart`
        renders a title plus body from `client/assets/legal/privacy.md` and `terms.md` (plain text
        or minimal markdown; register the folder in `pubspec.yaml`). Write **placeholder** copy
        that starts with "DRAFT — pending legal review" and covers what's collected (account,
        check-in time, club, distance), why, retention, deletion/export and contact. Link both
        from `ProfilePage` too. New `client/lib/views/pages/check_in_primer_page.dart` is shown
        once, before the first `CheckInPage` (flag `checkInPrimerSeen` in `SharedPreferences`). It
        has three short points: scan the QR at the entrance, location is only read at the moment
        you check in, and your map is private. Then it continues to the scanner.
      - Out: storing `acceptedTermsAt` server-side (7.1), final legal text (5.7), date of birth.
      - Verified by: widget tests. Register stays disabled until both boxes are checked; tapping
        the Terms link pushes `LegalPage`. The primer shows on the first navigation to check-in and
        not on the second (`SharedPreferences.setMockInitialValues`). `flutter test` passes.

- [x] 5.2 "Download my data": export my profile and full check-in history as JSON.
      - Goal: the user owns their location history (GDPR access/portability). It pairs with 5.3
        (delete account) and 5.4 (remove a check-in), so users can take their data with them
        before deleting.
      - Scope: server `GET /api/auth/me/export` (authMiddleware) in `authController.js` returns
        `{exportedAt, user: {id, email, name, role, createdAt}, checkIns: [{id, checkedInAt,
        distanceMeters, verificationMethod, club: {id, name, address, city, latitude,
        longitude}}]}` with `Content-Disposition: attachment; filename="clubsy-export-<date>.json"`.
        It uses an explicit Prisma `select`, **never** `password` or `qrSecret`. Client: a
        "Download my data" tile on `ProfilePage` calls it through `ApiClient`, writes the file to
        the temp directory and opens the share sheet (`share_plus`, added in 4.2; add it here if
        4.2 hasn't landed).
      - Out: an email delivery of the export, CSV.
      - Verified by: Jest: the export for a user with two check-ins has both; the serialized
        response contains neither `password` nor `qrSecret` (search the JSON string); no token →
        401. A Flutter test with a fake service checks the tile triggers the export call. `pnpm
        test` and `flutter test` pass.
      - Depends on: 2.2, 3.1.

- [x] 5.3 Delete my account and all my check-ins (absorbs `BACKLOG.md` B19).
      - Goal: Clubsy stores a timestamped history of where someone goes at night, which is
        sensitive location data. Users need a way to erase it, and App Store and Play policy require
        in-app account deletion before the app can ship. This blocks 5.5.
      - Scope (server): `DELETE /api/auth/me` (authMiddleware) in `authController.js` and
        `authRoutes.js`. It requires the current `password` in the body (`express-validator`
        notEmpty, then a bcrypt compare: wrong → 401). It runs
        `prisma.$transaction([checkIn.deleteMany({where:{userId}}), user.delete({where:{id}})])`
        and returns 204. Deleting the last remaining ADMIN → 409 `{message}`. No schema change. When
        7.7 lands, bump `tokenVersion` first. When later phases add user-owned rows (favourites,
        friendships, reports), each of those tasks must add its table to this transaction. Add a
        comment there saying so.
      - Scope (client): `deleteAccount(password)` in `auth_service.dart` (via `ApiClient`), and a
        "Delete account" tile at the bottom of `ProfilePage` (red, below Logout). It opens a confirm
        dialog that explains what is deleted and that this can't be undone, offers the 5.2 "Download
        my data" first, and requires the password. On success: sign out, clear the 3.3 cache, go to
        `/login`, and show "Your account and history were deleted".
      - Out: a soft-delete grace period. The human may want to review the confirm wording (5.7).
      - Verified by: Jest with mocked Prisma. Wrong password → 401 and `$transaction` never
        called. Correct password → 204 and `$transaction` called with the check-in delete **before**
        the user delete. Last admin → 409. No token → 401. A Flutter widget test shows the Profile
        tile opens a confirm dialog with a password field and a disabled Delete button until it's
        filled. `pnpm test` and `flutter test` pass.
      - Depends on: 3.1, 3.3 (cache clear). 5.2 is linked from the dialog if it has landed.

- [x] 5.4 Remove a single check-in from my map (absorbs `BACKLOG.md` B20).
      - Goal: a personal map is only personal if the user controls it. Someone may want to drop a
        visit (a bad night, a place they'd rather not have on their record) without deleting their
        whole account.
      - Scope (server): `DELETE /api/check-ins/:id` in `checkInController.js` and
        `checkInRoutes.js`. Look the row up by id. Return 404 if it doesn't exist **or** if
        `userId !== req.user.id`, so the response doesn't reveal whether other users' check-ins
        exist. Otherwise delete it and return 204. Stats and achievements recompute naturally since
        they're derived. No schema change.
      - Scope (client): `deleteCheckIn(id)` in `check_in_service.dart`. `ClubController.removeCheckIn(id)`
        updates `myCheckIns` optimistically (rolling back on error), re-fetches stats, and lets
        `visitedClubIds` recompute, so the club's pin goes back to unvisited once its last check-in
        is removed. Add swipe-to-delete on the 3.5 history tiles, with a confirm ("Remove this visit
        from your map? This can't be undone."). Also add a "Remove" action in the tile's long-press
        menu for accessibility.
      - Out: undo, admin moderation of check-ins.
      - Verified by: Jest with mocked Prisma. Owner → 204 and `checkIn.delete` called. Another
        user's check-in → 404 and no delete. Unknown id → 404. No token → 401. A Flutter controller
        test with a fake service: removing a club's only check-in drops it from `visitedClubIds`;
        removing one of two keeps it; a service error restores the list. `pnpm test` and
        `flutter test` pass.
      - Depends on: 3.1, 3.5.

- [>] 5.5 (You) Deploy the pilot backend and ship test builds.
      - Host: **Render** (decided 2026-10-03). Once 5.8 has landed: create a Render account,
        choose New → Blueprint, point it at this repo's `main`, and fill in the secrets the
        blueprint marks as yours (`CORS_ORIGINS`, `RESEND_API_KEY`, `EMAIL_FROM`). The blueprint
        provisions managed Postgres, generates `JWT_SECRET`, runs `prisma migrate deploy` before
        each release and health-checks `/health/ready` (2.3). Add a custom domain if you want one.
      - Build the app with `--dart-define=API_BASE_URL=https://<domain>/api`. Ship it to Play
        Console internal testing and TestFlight. Set a real application id or bundle id instead of
        any `com.example` default, plus app name, icon and splash screen.
      - Create the production admin with the seed script's admin path (2.5) or by SQL, and store
        the password in a password manager.

- [>] 5.6 (You) Venue onboarding for the pilot city: about 10 partner clubs.
      - For each venue: create it in the admin console (4.2) while **standing at the entrance**,
        using "Use my current location". Check that the 150 m radius preview covers the entrance
        and the queue area. Print the QR (A5 or larger, laminated) and place it where staff can see
        it, not on the street side, to limit photo sharing until 6.4 lands.
      - Do one real check-in per venue on two different phones (iOS and Android). Write down the
        `distanceMeters` the server reports. If legitimate check-ins regularly land above 120 m,
        raise it with the agent team before changing `MAX_CHECK_IN_DISTANCE_METERS`, because that
        rule is binding.
      - Agree with each venue who to call if the QR goes missing (rotate it from 4.1).

- [>] 5.7 (You) Legal review: replace the DRAFT privacy policy and terms (5.1), decide the
      check-in data retention period, and confirm the 18+ requirement and the in-app
      account-deletion path (5.3) meet App Store and Play policy. Add the hosted policy URL to both
      store listings.

- [x] 5.8 Render deployment blueprint for the backend, so deploying (5.5) is only an account plus
      secrets.
      - Goal: the pilot API deploys to Render (decided 2026-10-03, `PLAN.md` decision 2) from one
        file, with no hand-configured settings.
      - Scope: a `render.yaml` at the repo root with:
        - a Node web service: `rootDir: server`, region `frankfurt`, build
          `pnpm install --frozen-lockfile && npx prisma generate`, `preDeployCommand:
          npx prisma migrate deploy`, start `node src/index.js`, `healthCheckPath: /health/ready`
        - a managed Postgres database `clubsy-db` in the same region, wired in with
          `DATABASE_URL: fromDatabase`
        - env vars `NODE_ENV=production`, `JWT_EXPIRES_IN=30d`, `JWT_SECRET` with
          `generateValue: true`, and `CORS_ORIGINS`, `RESEND_API_KEY`, `EMAIL_FROM` as
          `sync: false` (filled in by the owner)

        Also add a short `docs/deploy.md`: the owner's click path, how to run the seed script's
        admin path against production (2.5), and how to roll back. Add `RESEND_API_KEY` and
        `EMAIL_FROM` to `server/.env.example` as optional, commented.
      - Out: creating the Render account or deploying (5.5), app store builds, the email sender
        itself (7.6).
      - Verified by: a Jest test (`server/src/__tests__/renderBlueprint.test.js`) that parses
        `render.yaml` with the `yaml` package (add it as a devDependency). It asserts the
        health-check path, the pre-deploy migration, `rootDir`, and that every variable
        `config.js` reads in production is declared. `pnpm test` passes.

## Phase 6 — Engagement without schema changes

Goal: build the retention loop (streaks, badges, challenges, recaps) on top of verified check-ins,
computed from `CheckIn` history so it needs no migration. This is the first, schema-free slice of
`BACKLOG.md` B1. Points stay display-only until B4.

- [x] 6.1 Achievements engine on the server: weekly streak, badges, weekly challenges and display
      points.
      - Scope: `server/src/services/gamificationService.js` with pure functions over a user's
        check-ins (each including its club) and `now`:
        - `weeklyStreak(checkIns, now)`: the number of consecutive ISO weeks, ending with the
          current or the previous week, that contain at least one check-in. Assign weeks by
          `nightStart` (so a Sunday 02:00 check-in belongs to Saturday's week). The current week
          doesn't break the streak until it's over. Also return `longestStreak`.
        - `badges(checkIns)`: returns `[{id, title, description, earnedAt | null, progress: {current,
          target}}]` for a static catalogue in `server/src/services/badgeCatalogue.js`:
          `first_pin` (1 check-in), `explorer_5` / `explorer_15` (distinct clubs), `globetrotter_3`
          (distinct cities), `regular_5` (5 nights at one club), `night_owl` (a check-in between
          03:00 and 05:59 local; use the club's timezone if known, otherwise UTC, and note the
          assumption), `weekend_warrior` (Friday and Saturday nights in the same week) and
          `streak_4` (a 4-week streak). `earnedAt` is the timestamp of the check-in that completed
          the badge.
        - `weeklyChallenges(checkIns, now)`: three static challenges for the current ISO week
          ("Check in at 2 different clubs", "Go out on 2 nights", "Visit a club you've never been
          to"), each with progress and `completed`.
        - `points(checkIns)`: 10 per check-in, 25 bonus per new club, 50 per earned badge. Display
          only: don't store it, and don't let anything spend it.
        - Endpoint `GET /api/check-ins/me/achievements` in `checkInController.js` and
          `checkInRoutes.js`, registered before `/me`.
      - Out: persisted points, a leaderboard (social, Phase 8), push notifications.
      - Verified by: Jest unit tests with fixed `now`. Empty history → streak 0 and all badges
        unearned. Check-ins in weeks W1, W2, W3 with `now` in W4 (no check-in yet) → streak 3.
        A gap → the streak resets and `longestStreak` is kept. A Sunday 02:00 check-in counts for
        the previous week. `earnedAt` for `explorer_5` is the 5th distinct club's check-in time.
        Challenge progress resets at the week boundary. A controller test returns all four
        sections. `pnpm test` passes.

- [x] 6.2 Achievements in the app: streak flame, badge grid, weekly challenges, and unlocks
      announced after a check-in.
      - Scope: `client/lib/data/classes/achievements_model.dart` (`fromMap` for the 6.1 response).
        Add `getMyAchievements()` to `CheckInService`, and an `achievements` field on
        `ClubController`, refreshed with the rest and after every check-in. On `ProfilePage`, add a
        row under the stats card with the current streak ("🔥 3-week streak"), points and "5/8
        badges", which opens the new `client/lib/views/pages/achievements_page.dart`: the weekly
        challenges with `LinearProgressIndicator`s and the week's end date, then a 3-column badge
        grid with unearned badges greyed out and showing progress ("3/5 clubs"); tapping a badge
        shows its description and earned date. After a successful check-in, compare the
        achievements from before and after with a pure `newlyEarned(before, after)` and show
        "Badge unlocked: Explorer" in the success UI (the 3.6 sheet).
      - Out: badge artwork (use Material icons per badge id for now; artwork is a design task),
        sharing badges.
      - Verified by: unit tests for `AchievementsModel.fromMap` and `newlyEarned` (none, one,
        several, and a streak increase that isn't a badge). A widget test renders the
        `AchievementsPage` grid from fixtures with earned and unearned states and challenge
        progress text. `flutter test` passes.
      - Depends on: 6.1.

- [x] 6.3 "Your nights" recap: a monthly and yearly summary with a shareable image card.
      - Goal: Spotify-Wrapped-style recaps are the cheapest growth loop for a diary product. Every
        share is a free ad, and the card only shows what the user chose to share.
      - Scope: client-only, computed from `myCheckIns`. Pure
        `client/lib/data/classes/recap.dart` with `buildRecap(checkIns, {required DateTime from,
        required DateTime to})` returning nights out, distinct clubs, distinct cities, the top club
        (with visit count), the busiest weekday, the latest night (the check-in time closest to
        06:00) and new clubs in the period. New `recap_page.dart` (reached from `ProfilePage` as
        "Your September" for the last complete month, plus a year selector) renders a stylised
        9:16 card inside a `RepaintBoundary`. "Share" captures it with `toImage(pixelRatio: 3)`,
        writes a PNG and opens `share_plus`. A toggle "Hide club names on the card" (default on)
        replaces the names with counts. Privacy matters even in brag posts.
      - Out: server-side image generation, automatic posting, push reminders ("your recap is
        ready", see B21).
      - Verified by: unit tests for `buildRecap` (empty period, a period boundary at 06:00, ties
        for top club broken by most recent visit, new clubs = first-ever visit inside the period).
        A widget test renders the card from fixtures and checks that no club name appears when
        "Hide club names" is on. `flutter test` passes.
      - Depends on: share_plus from 4.2 or 5.2 (or add it here).

- [x] 6.4 Rotating venue QR (TOTP-style) plus a venue display page, to stop photographed QR codes
      from working remotely.
      - Goal: the static QR can be photographed once and reused from home with spoofed GPS. A code
        that changes every 30 s on a screen at the door makes a shared photo useless within a
        minute, without changing the "QR + GPS" rule.
      - Scope (server): in `server/src/services/venueQrService.js`, add `rotatingCode(secret,
        timeStep)` = the first 8 hex characters of `HMAC-SHA256(qrSecret, String(timeStep))`, with
        `timeStep = floor(unixSeconds / 30)`. Add `buildRotatingPayload(club, now)` →
        `JSON.stringify({clubId, t: timeStep, code})`. Extend `verifyClubQrPayload(raw, club, now
        = new Date())` so it accepts **either** the legacy static `{clubId, secret}` payload (so
        printed QRs keep working during the pilot) **or** a rotating payload whose `t` is within
        ±1 step of now and whose `code` matches. Use `crypto.timingSafeEqual` for both
        comparisons. Add a display endpoint `GET /venue-display/:clubId?key=<displayKey>`, where
        `displayKey` = `HMAC-SHA256(qrSecret, "display")` (so rotating the QR also invalidates
        display links). It serves a self-contained HTML page (no external scripts; inline the QR
        as a data URL generated server-side) that auto-refreshes the QR every 30 s via
        `fetch('/venue-display/:clubId/qr?key=…')`, which returns `{qrCode, expiresAt}`. A wrong
        key → 404 (never reveal whether the club exists). Admins get the display URL from a new
        `GET /api/clubs/:id/display-link`. Client admin: a "Venue display link" action on the QR
        page (4.1) with copy and share.
      - Out: enforcing rotating-only per club (needs a `qrMode` column, see B27), a native
        tablet app.
      - Verified by: Jest with an injected `now`. Static payload → accepted. Rotating payload in
        the current, previous and next step → accepted. Two steps old → rejected. A tampered code
        → rejected. A rotating payload for another club → rejected. After `rotateClubQr`, the old
        display key → 404. Supertest: a display page with the right key → 200 `text/html`
        containing a `data:image/png` URL; wrong key → 404. `pnpm test` passes.
      - Depends on: 2.2, 4.1.

- [x] 6.5 Club page polish: directions, distance from me, share, and a "not visited yet" nudge.
      - Goal: `ClubDetailsPage` is where intent turns into a visit. It should answer "how far is it,
        and how do I get there?" and make an unvisited club feel like an invitation.
      - Scope: in `client/lib/views/pages/club_details_page.dart`, add a "Directions" button that
        opens the platform maps app via `url_launcher` (`geo:` on Android, `https://maps.apple.com/?daddr=` on iOS;
        build the URI in a pure `directionsUri(club, platform)`). Show "1.2 km from you" when
        location permission is **already** granted; never prompt from this page, because
        the prompt belongs to the check-in flow. Format it with a pure `formatDistance(meters)`
        (`< 1000` → "350 m", otherwise one decimal in km). Add a share button with the text "<Club>
        in <City> — on Clubsy" (deep links come with B30). For unvisited clubs, show "Not on your
        map yet", and for visited ones keep the B13 visit summary. On `ClubMapPage`, add a "near
        me" FAB that centres the map on the user's position (only when permission is granted;
        otherwise it opens the 5.1 primer explanation).
      - Out: in-app routing, opening hours (7.2), favourites (7.3).
      - Verified by: unit tests for `directionsUri` (both platforms, coordinates encoded) and
        `formatDistance` (0, 999, 1000, 1549 → "1.5 km"). A widget test with fixture data shows the
        "Not on your map yet" state for an unvisited club and the B13 summary for a visited one.
        `flutter test` passes.

## Phase 7 — Features that need schema changes

Every task here adds a Prisma migration with `npx prisma migrate dev` against the local dev
Postgres that the supervisor starts (service `postgres` in `.nightshift/config.json`; see
`.nightshift/rules.md`). Each task bundles schema, migration, server, client and tests for one
feature, per the sizing rules. Server tests still mock Prisma.

- [x] 7.0 (You) Give the night shift a way to create migrations. Done 2026-10-03 with option (a):
      the existing `clubsy-db` container is the `postgres` service (started for Phases 7 and 8),
      `server/.env` (copied into every worktree) points at it, and `.nightshift/rules.md` explains
      how to migrate and reset it.

- [x] 7.1 Public-safe user profile: a unique username, an editable display name, a home city, and
      server-side consent records.
      - Schema: `User.username String? @unique` (3-20 characters, `[a-z0-9_]`, stored lowercase),
        `User.homeCity String?`, `User.acceptedTermsAt DateTime?`, `User.termsVersion String?`,
        `User.ageConfirmedAt DateTime?`.
      - Server: signup accepts and requires `acceptTerms: true` and `ageConfirmed: true` (400
        otherwise) and stamps both fields with the current `TERMS_VERSION` from `config.js`. New
        `PATCH /api/auth/me` for `name`, `username` (409 if taken, with a case-insensitive check)
        and `homeCity`. `GET /api/auth/me` returns them. `GET /api/auth/username-available?u=` is
        rate-limited.
      - Client: send the 5.1 checkboxes at signup. Add an "Edit profile" page from Profile with a
        live username availability check (debounced), and show `@username` on Profile.
      - Why now: usernames are the prerequisite for adding friends (8.1) without exposing emails.
      - Verified by: Jest (signup without consent → 400; username taken → 409; invalid characters →
        400; a case-insensitive duplicate → 409), a Flutter widget test for the edit form
        validation, and `pnpm test` plus `flutter test`.

- [x] 7.2 Richer club profiles: description, music genres, opening hours, links, and "Open now".
      - Schema: `Club.description String?` (≤ 500), `Club.genres String[]` (from a fixed list in
        `server/src/utils/genres.js`: techno, house, hip-hop, commercial, rock, latin, drum-and-bass,
        live), `Club.openingHours Json?` (`{mon:[{open:"23:00",close:"05:00"}], …}`, close may be
        after midnight), `Club.instagramUrl String?`, `Club.websiteUrl String?`,
        `Club.timezone String @default("Europe/Bucharest")` (also fixes the UTC night assumption
        in NOTES.md for future multi-city use).
      - Server: validate in create and PATCH (2.4), including the opening-hours shape. Add a
        `genre` filter on `GET /api/clubs`. Pure `isOpenAt(openingHours, timezone, date)` with
        tests across midnight.
      - Client: genre chips and an opening-hours table on `ClubDetailsPage` with an "Open now" or
        "Opens 23:00" chip, a genre filter on the map or search (B15), and the fields in the admin
        form (4.2).
      - Out: anything event-like (line-ups, dated parties, tickets). Opening hours are a weekly
        schedule only.
      - Verified by: Jest for `isOpenAt` (Friday 23:00-05:00 is open at Saturday 02:00 and closed
        at Saturday 06:00; closed days; a malformed JSON shape is rejected at validation),
        Flutter tests for the chip text, `pnpm test` and `flutter test`.

- [x] 7.3 Favourites ("Want to go") list and map layer.
      - Schema: `Favorite {userId, clubId, createdAt, @@unique([userId, clubId])}`.
      - Server: `PUT /api/clubs/:id/favorite` and `DELETE /api/clubs/:id/favorite` (idempotent,
        404 for unapproved clubs), and `GET /api/clubs/favorites`. Club list responses include
        `isFavorite` for the caller.
      - Client: a heart toggle on `ClubDetailsPage` (optimistic), a star marker style on the map
        (visited = green, favourite = gold, both = green with a star), and a "Want to go" filter in
        B14's toggle (All / Visited / Want to go). When a favourite gets checked into, show "Ticked
        off your list!" in the success UI.
      - Verified by: Jest (idempotent PUT; DELETE on a non-favourite → 204; unapproved → 404;
        `isFavorite` only reflects the caller's favourites), Flutter controller tests for the
        optimistic toggle with rollback, `pnpm test` and `flutter test`.

- [x] 7.4 Private night notes and a venue "vibe" rating on each check-in.
      - Goal: turn the history into a real diary ("great DJ, went with Ana") and collect the venue
        quality signal that powers 7.5. This rates **venues**, not people; person-to-person
        ratings (B2) stay gated behind Phase 8.
      - Schema: `CheckIn.note String?` (≤ 280), `CheckIn.vibe Int?` (1-5), `CheckIn.vibeAt
        DateTime?`.
      - Server: `PATCH /api/check-ins/:id` (owner only, 404 otherwise) for `note` and `vibe`.
        `vibe` is only editable until 7 days after `checkedInAt`. Notes are never returned to
        anyone but the owner.
      - Client: after a check-in, the success UI offers "Rate tonight later". The next morning (the
        first app open after 06:00) shows a one-tap 1-5 "How was <Club>?" card on the map. Show the
        note and vibe on history tiles, with editing from history.
      - Verified by: Jest (non-owner → 404; vibe 6 → 400; editing after 7 days → 409; the note is
        absent from any non-owner response), Flutter tests for the morning-card trigger logic
        (pure `pendingVibePrompt(checkIns, now)`), `pnpm test` and `flutter test`.
      - Depends on: 7.0, 3.5 and 5.4 (history tile layout).

- [x] 7.5 Club vibe score on club pages (aggregate, privacy-preserving).
      - Server: club responses include `vibe: {average, count}` only when `count >= 5` (k-anonymity:
        individual ratings are never exposed, and below the threshold the field is `null`).
        Compute it over the last 90 days. Add a `sort=vibe` option on `GET /api/clubs`.
      - Client: "★ 4.3 · 27 ratings" on `ClubDetailsPage` and in search results, and "Not enough
        ratings yet" below the threshold.
      - Verified by: Jest (4 ratings → `null`; 5 → average; ratings older than 90 days excluded;
        no rater ids in the payload), `pnpm test` and `flutter test`.
      - Depends on: 7.4.

- [x] 7.6 Password reset by email.
      - Provider: **Resend** (decided 2026-10-03, `PLAN.md` decision 4). Call its HTTP API
        (`POST https://api.resend.com/emails`) with `fetch` instead of adding an SDK. Use the
        Resend sender when `RESEND_API_KEY` is set, otherwise the console sender, and send from
        `EMAIL_FROM`. `config.js` requires both in production. Tests inject a fake sender or a
        fake `fetch` and never call the real API.
      - Schema: `PasswordResetToken {id, userId, tokenHash, expiresAt, usedAt}`. Store only a
        SHA-256 hash of the token.
      - Server: `POST /api/auth/password/forgot` always returns 202 (never reveals whether an email
        exists), is rate-limited per IP and email, and sends a 6-digit code valid for 15 minutes.
        `POST /api/auth/password/reset` takes `{email, code, newPassword}`, enforces the same
        password rules as signup, and is single-use. The email sender is an injectable module
        (`server/src/services/emailService.js`) with a console implementation in development.
      - Client: "Forgot password?" on `LoginPage`, then a two-step flow (email, then code plus new
        password).
      - Verified by: Jest with a fake email sender (unknown email → 202 and no send; an expired
        code → 400; a reused code → 400; a successful reset → new password works and the old one
        doesn't), `pnpm test` and `flutter test`.

- [x] 7.7 Session revocation: sign out everywhere, and invalidate tokens on password change or
      account deletion.
      - Schema: `User.tokenVersion Int @default(0)`.
      - Server: include `tv` in the JWT. `authMiddleware` rejects with 401 when `tv !==
        user.tokenVersion`. Increment it on password reset (7.6), on a new `POST
        /api/auth/signout-all`, and before deleting an account (5.3).
      - Client: a "Sign out of all devices" tile on Profile.
      - Verified by: Jest (an old token → 401 after signout-all; a new token works), `pnpm test`.
      - Depends on: 2.1, 3.4.

The points ledger (formerly 7.8) moved to `BACKLOG.md` B4 on 2026-10-03: monetization is
venue-side B2B first, so there's nothing for points to buy yet, and 6.1's computed points are
enough.

## Phase 8 — Social foundation (after 7)

Nothing in this phase shows a user's **current** location to anyone. It's the base that B2
(ratings), B3 (matching) and B5 (presence) must build on. Every task needs 7.1 (usernames) and
follows the 8.0 decisions below.

- [x] 8.0 (You) Sign off the social design. Signed off 2026-10-03 (`PLAN.md` decision 7):
      - **Model:** mutual friends only. No followers and no one-way visibility.
      - **What a friend sees:** clubs and night dates, never check-in times, and only nights that
        have ended (after 06:00). Sharing is opt-in per user and off by default, and any single
        check-in can be hidden.
      - **Blocking:** a blocked user disappears everywhere, in both directions, and any friendship
        or pending request between the two ends. Unblocking doesn't restore the friendship.
      - **Moderation:** the owner (admin role) works the report queue in the admin console within
        48 hours. A user with 3+ open reports is flagged for review.
      - **Navigation:** no new bottom tab. Friends and the feed are pages pushed from Profile.

- [x] 8.1 Friends: requests by username, accept or decline, friend list, unfriend.
      - Schema: `Friendship {id, requesterId, addresseeId, status PENDING|ACCEPTED, createdAt,
        respondedAt, @@unique([requesterId, addresseeId])}`.
      - Server: send a request by `username` (7.1). Searching only matches an exact username,
        never partial matches or email lookups, to prevent enumeration. Add accept, decline,
        cancel, unfriend, and list (accepted plus incoming and outgoing pending). A pending request
        in the opposite direction auto-accepts. Rate-limit requests to 20 per day.
      - Client: a Friends page from Profile (list, requests with badges, add by username).
      - Verified by: Jest for every state transition, including duplicates, the reverse-direction
        auto-accept, requesting yourself → 400, and an unknown username giving the same response
        as a known one, plus Flutter controller tests.

- [x] 8.2 Block and report, plus an admin moderation queue.
      - Schema: `Block {blockerId, blockedId, createdAt, @@unique}` and `Report {id, reporterId,
        reportedUserId, reason enum, details ≤ 500, status OPEN|ACTIONED|DISMISSED, createdAt,
        handledById, handledAt}`.
      - Server: blocking removes any friendship and pending requests, and every social query
        filters out blocks in both directions. Use one shared Prisma `where` helper so a future
        social query can't forget it. Admin endpoints list and resolve reports. A reported user
        with 3+ open reports is flagged in the admin console.
      - Client: block/report actions on any user surface, a "Blocked users" list in settings, and
        a reports queue in the admin console (Phase 4).
      - Verified by: Jest (a blocked user can't send a friend request or see you in any list in
        either direction; unblocking doesn't restore the friendship), `pnpm test` and
        `flutter test`.

- [x] 8.3 Privacy settings: control who sees my nights.
      - Schema: `User.shareNightsWithFriends Boolean @default(false)` and `CheckIn.hiddenFromFriends
        Boolean @default(false)`.
      - Client: a Privacy section in Profile with a clear explanation, and a per-check-in "Hide
        from friends" toggle in history.
      - Verified by: Jest for the defaults (a new user shares nothing) and the toggles,
        `pnpm test` and `flutter test`.

- [x] 8.4 Friends' nights feed: delayed, opt-in on both sides, past nights only.
      - Server: `GET /api/feed` returns friends' check-ins only when **both** users have
        `shareNightsWithFriends` on, the check-in isn't hidden, and its night has **ended** (now is
        at or after `nightEnd(checkedInAt)`). It shows the club and the night date, never the
        check-in time. It's paginated and never includes blocked users.
      - Client: a "Friends' nights" feed page pushed from Profile (no new tab, per 8.0), plus
        "3 friends have been here" on `ClubDetailsPage` (count only).
      - Verified by: Jest (a check-in from tonight is not visible until 06:00; one-sided sharing is
        not visible; hidden check-ins and blocked users are excluded; no `checkedInAt` time is in
        the payload), `pnpm test` and `flutter test`.

## Phase 9 — Test-audit follow-ups

Goal: close the gaps the 2026-10-04 test audit found (PR #4). No schema changes. New tests must
pass the testing policy in `.nightshift/rules.md`.

- [x] 9.1 Server: cover the empty club update and remove the dead `signOut` controller.
      - Scope: in `server/src/__tests__/routes.test.js`, add one supertest case:
        `PATCH /api/clubs/:id` as ADMIN with a body that sets no editable field (e.g. `{}`)
        returns 400 `{message: "No fields to update"}` and never calls `club.update`. Delete the
        unrouted `signOut` export from `server/src/controllers/authController.js`. No route
        uses it, and the client signs out by dropping its token.
      - Out: adding a sign-out route or token revocation (that's 7.7).
      - Verified by: the new case fails if the `Object.keys(data).length === 0` guard in
        `updateClub` is removed, `grep -rn signOut server/src` finds nothing, and `pnpm test`
        passes.

- [ ] 9.2 Client: make the date-dependent history and recap widget tests deterministic.
      - Goal: `on_this_night_test.dart` ("history page shows the On this night card", "history
        page has no card when nothing matches") and `recap_test.dart` ("page shows comparison",
        "page hides comparison without previous check-ins") build their fixtures from
        `DateTime.now()`, so their result depends on the day they run (month ends, 29 Feb, a run
        that crosses midnight).
      - Scope: give `CheckInHistoryPage` and `RecapPage` an optional `DateTime? now` constructor
        parameter (default `DateTime.now()`, matching `BeenAWhileCard(now:)` and
        `YearlyGoalCard(now:)`), use it where they call `DateTime.now()` today
        (`check_in_history_page.dart` `onThisNight(...)`, `recap_page.dart` `_now`), and pin a
        fixed `now` in those four tests. Keep their assertions otherwise unchanged.
      - Out: changing the on-this-night or recap rules.
      - Verified by: the four tests pass with `now` pinned to 2025-02-28, 2026-03-31 and
        2026-10-02 (check locally, then keep one), and `flutter test` passes.
