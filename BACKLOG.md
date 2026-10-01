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

- [ ] B3 Matching: Tinder-style swipe/match between users checked into the same club/night — status: approved
  - Why: the original pitch's "algorithm similar to Tinder" for clubgoers.
  - Scope: a swipe/like/match model scoped to users who share a current or recent check-in at the
    same club; a match unlocks some form of contact (chat is out of scope unless separately
    proposed). Needs its own privacy pass (who's shown to whom, consent, blocking/reporting) before
    being built, not just a schema.
  - Acceptance: TBD pending a dedicated design pass — this is a bigger feature than the others and
    should get its own planning round, not a single task list.
  - Size: large; likely needs its own plan, not just backlog tasks.

- [ ] B4 Points economy & subscriptions — status: approved
  - Why: monetization + a sink for the points balance from B1.
  - Scope: ways to spend accumulated points (perks, cosmetic profile features, club-partner
    discounts — TBD with the business side); subscription tiers on top. Reintroduce a Stripe
    integration following `timeit`'s `server/src/services/stripeService.js` as the implementation
    pattern (that file was deliberately not carried into this repo — Phase 1 has no payments).
  - Acceptance: TBD — needs a decision on what's actually being sold before tasks can be written.
  - Size: large.

- [ ] B5 Live presence map ("who's out tonight") — status: approved
  - Why: the original "Snapchat map" pitch. **Deferred deliberately** for real safety reasons
    (stalking/unwanted-contact risk in a nightlife context), not because it's low value.
  - Scope, non-negotiable before any build: opt-in per session (not a standing setting), visible
    only to mutual friends/matches (never broadcast more broadly by default), auto-expires a few
    hours after the session ends. Do not approve a version of this that skips any of the three.
  - Acceptance: TBD — needs its own design/safety review pass when the time comes, including how
    blocking/reporting interacts with it.
  - Size: large; requires realtime infrastructure (websockets or similar) not present in Phase 1.
