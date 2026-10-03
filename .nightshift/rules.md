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
  `cd server && npx prisma migrate dev --name <snake_case_name>`, never hand-edit a file under
  `server/prisma/migrations/`. Only `TASKS.md` Phase 7+ tasks may change the schema.
- Club check-in verification is QR (venue-displayed) + GPS proximity (~150m, see
  `server/src/utils/geo.js` and `MAX_CHECK_IN_DISTANCE_METERS` in `checkInController.js`) — don't
  relax this to GPS-only or QR-only without an explicit task saying so.
- A local dev Postgres (Docker container `clubsy-db`) is started by the supervisor for Phase 7 and 8
  tasks (`.nightshift/config.json` service `postgres`), and `server/.env` already points at it: use
  that `DATABASE_URL`, never invent a connection string. The database holds seed data only and is
  disposable. If `prisma migrate dev` reports drift or migrations the branch doesn't have (left by
  an earlier attempt), run `cd server && npx prisma migrate reset --force` (it re-applies the
  branch's migrations and re-seeds), then retry. Server tests still mock Prisma and never need
  the database. If the database is unreachable, end `BLOCKED: no database available`.
- To verify the server boots without crashing, run exactly `timeout 5 node server/src/index.js`
  (that precise command, from the repo root) — it is the one allowlisted in `.claude/settings.json`.
  A different timeout value or invocation form will be denied by the permission system, not by a
  bug in the code.

## Task sizing

Every builder/reviewer attempt re-runs the full gate suite (`flutter pub get`, `dart format`,
`flutter analyze`, `flutter test`, `pnpm install`, `pnpm test`) regardless of how small the task
is — that is a fixed cost per session, not per line changed. Prefer fewer, larger tasks over many
tiny ones:

- When proposing or splitting backlog items into TASKS.md tasks, bundle one feature's schema +
  backend + frontend work into a single task sized for roughly 45-75 minutes of agent time, rather
  than one task per file or per layer. A task like "add the Rating model, migration, controller,
  routes, and Flutter rating UI" is preferred over separate schema/backend/frontend tasks for the
  same feature.
- Still keep each task independently verifiable (one clear "Verified by:" check) and small enough
  to fit one coherent diff — do not bundle unrelated features together just to save a gate cycle.
- Up to 8 consecutive small/independent tasks may be batched into one session automatically (see
  .nightshift/config.json's batch setting); writing tasks with that in mind (self-contained,
  ordered so related ones are adjacent) helps the batcher combine them.
