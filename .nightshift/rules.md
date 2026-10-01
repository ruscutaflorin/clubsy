- Follow the conventions in `CLAUDE.md`.

## What this project is

Clubsy: users check in at clubs (QR scanned on-site + GPS proximity check) and build a personal
map of places they've visited. Pivoted from a separate event-management app (`timeit`); nothing
in this repo should reintroduce event/ticketing/cart concepts.

## Layout

- `server/`: Node + Express + Prisma + PostgreSQL, plain JWT auth (`jsonwebtoken`, not a third-party
  auth provider). Controllers go in `server/src/controllers/`, routes in `server/src/routes/` and
  are registered in `server/src/index.js`, one service per concern in `server/src/services/`.
  Mirror the existing `clubController.js` / `checkInController.js` shape for new resources:
  `express-validator` for input validation, Prisma directly in controllers, `{message}` or
  `{errors}` JSON error shape, `req.user.id` / `req.user.role` (set by `authMiddleware`) for
  ownership and admin checks.
- `client/`: Flutter + GetX. One `_service.dart` per resource in `client/lib/services/` doing authed
  HTTP calls (mirror `club_service.dart`), one `_model.dart` per resource in
  `client/lib/data/classes/` for (de)serialization, one controller per resource in
  `client/lib/src/core/controllers/` holding `GetxController` state, pages in
  `client/lib/views/pages/`. New top-level pages get wired into `client/lib/views/widget_tree.dart`
  and `client/lib/widgets/navbar_widget.dart` only when they're meant to be a primary tab — most
  new features are pushed with `Get.to()` from an existing page instead.

## Hard rules

- Never add Event/EventRegistration/Payment/ticketing/cart models or UI back — this app has no
  event-management concept. If a task description seems to ask for that, treat it as a mistake in
  the task text and end with `BLOCKED: <reason>` rather than building it.
- The **live "who's out tonight" presence map is deferred** (see `BACKLOG.md` Phase 6) and, when it
  is eventually built, must be opt-in, visible only to mutuals/matches, and auto-expiring — never a
  plain broadcast of a user's live location. Do not build any version of this feature unless a
  `TASKS.md` task explicitly describes that exact scope.
- `server/prisma/schema.prisma` migrations are one-way in practice (a real Postgres instance holds
  data once seeded) — when a task changes the schema, add a new migration via
  `npx prisma migrate dev`, never hand-edit a file under `server/prisma/migrations/`.
- Club check-in verification is QR (venue-displayed) + GPS proximity (~150m, see
  `server/src/utils/geo.js` and `MAX_CHECK_IN_DISTANCE_METERS` in `checkInController.js`) — don't
  relax this to GPS-only or QR-only without an explicit task saying so.
- No Postgres is guaranteed to be running during a night-shift session. Any task that needs a live
  database (running `prisma migrate dev`, hitting an endpoint end-to-end) should say so plainly and
  end `BLOCKED: no database available` rather than guessing at a connection string.
