# Deploying the backend to Render

The whole setup lives in `render.yaml` at the repo root.

## First deploy

1. Create an account at render.com and connect your GitHub account.
2. New → Blueprint, pick this repo and the `main` branch.
3. Fill in the secrets Render asks for:
   - `CORS_ORIGINS`: comma-separated browser origins (e.g. the admin console URL). Mobile apps don't need CORS.
   - `RESEND_API_KEY` and `EMAIL_FROM`: email sender (used once 7.6 lands; may be left blank until then).
4. Apply. Render creates the `clubsy-db` Postgres, generates `JWT_SECRET`, builds, runs
   `prisma migrate deploy` as the pre-deploy step and waits for `/health/ready` to pass.
5. Optional: Settings → Custom Domains on `clubsy-api`.
6. Build the app with `--dart-define=API_BASE_URL=https://<domain>/api`.

## Create the production admin

In the `clubsy-api` service open **Shell** and run:

```sh
SEED_ADMIN_EMAIL=you@example.com SEED_ADMIN_PASSWORD='a-long-password' pnpm seed
```

The seed script upserts the admin (an existing user with that email is promoted) and also
upserts the seed clubs. Store the password in a password manager. Alternatively, register in
the app and run `UPDATE "User" SET role = 'ADMIN' WHERE email = '...';` in the database's psql shell.

## Roll back

- Code: service → Events/Deploys → pick a previous successful deploy → **Rollback**.
- Migrations are not reverted by a rollback. Prisma migrations are forward-only: ship a new
  corrective migration, or restore the database from a Render Postgres backup (database → Recovery).
  Prefer additive migrations so the previous code keeps working against the new schema.
