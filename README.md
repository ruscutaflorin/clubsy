# Clubsy

Check in at clubs (venue QR + GPS proximity) and build a personal map of places you've visited.
`server/` is Node + Express + Prisma + Postgres; `client/` is Flutter + GetX.

## Prerequisites

Docker, Node 20, pnpm 10, Flutter (see `client/pubspec.yaml`), an Android emulator.

## Local setup

```sh
docker compose up -d            # Postgres 16 on :5432
cd server
cp .env.example .env            # set JWT_SECRET, SEED_ADMIN_EMAIL, SEED_ADMIN_PASSWORD
pnpm install
pnpm prisma migrate dev
pnpm seed                       # ~10 fictional clubs, an admin, QR PNGs in server/seed-output/
pnpm dev                        # API on http://localhost:3000
```

## Running the app on an Android emulator

```sh
cd client
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

## Testing a check-in

1. Sign in on the app and open a seeded club (its coordinates are in the seed data or the admin API).
2. Display `server/seed-output/<club-slug>.png` on a second screen.
3. In the emulator's Extended controls → Location, set the GPS to the club's coordinates
   (within ~150 m), then scan the QR from the app.

## Tests

```sh
cd server && pnpm test
cd client && flutter test
```
