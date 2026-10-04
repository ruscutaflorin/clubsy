---
name: test-audit
description: "Invoke whenever writing, changing, reviewing, or sweeping tests in Clubsy (server jest suites under server/src/__tests__, Flutter suites under client/test). Authoring gate for new tests plus audit workflow for low-value, implementation-coupled, or duplicative tests and the test-only production seams they demand."
---

# Test Audit

Adapted from OpenClaw's `test-audit` skill
(https://github.com/openclaw/openclaw/tree/main/.agents/skills/test-audit, MIT License,
Copyright (c) 2026 OpenClaw Foundation).

Three modes, one value bar. **Authoring mode** gates every new or changed test at
write time. **Audit mode** runs focused sweeps of tests that re-assert source,
duplicate stronger proof, couple behavior to implementation, or keep test-only
production seams alive. **Campaign mode** prunes a whole suite or lane; before
starting one, read [CAMPAIGN.md](CAMPAIGN.md). Optimize for confidence, not
deletion count.

Night Shift building agents may only use audit or campaign mode (delete or
consolidate tests) when their task in `TASKS.md` is tagged `[test-audit]`.
Every other task uses authoring mode only and never deletes tests.

## Authoring gate

Before adding any test, answer four questions; a missing answer means do not
add it yet:

1. What observable behavior, invariant, or independent contract does it protect?
2. What credible regression makes it fail?
3. Why does existing coverage not already catch that failure? Each contract has
   one primary test owner at the strongest boundary; another layer needs its
   own distinct risk. Prefer extending a table-driven case or shared fixture
   over a near-duplicate test; consolidate duplicated setup in the same change.
4. Does it need a production seam (export, flag, wrapper, injection hook) that no
   production caller needs? If yes, move the test to the real boundary instead.

Then check the test against every [junk pattern](#junk-patterns); a match fails
the gate unless the [retention bar](#retention-bar) names the contract it
independently guards. A test that would break under behavior-preserving
refactoring is asserting implementation, not behavior; rewrite it at the
owning boundary before landing it.

Bug regression tests must fail on the pre-fix code for the intended reason and
pass after the owner-boundary repair. A regression test that never demonstrably
failed proves the mock, not the fix. One regression at the owner boundary
covers the bug; do not replay the same scenario at every layer it crosses.

### Clubsy boundaries

- **Server**: the strongest boundary is usually the HTTP route through
  `supertest` against the real Express app with Prisma mocked (status, JSON
  body, `{message}`/`{errors}` shape, auth/role enforcement). Pure utilities and
  services (`utils/geo.js`, `utils/night.js`, gamification/stats services) own
  their calculations; test them directly, and do not replay their arithmetic
  through every controller that calls them.
- **Client**: pure Dart helpers and models own parsing and derived stats; test
  them directly. Widget tests own what the user sees and can do (text, empty
  and error states, taps leading to navigation or service calls). A widget test
  that re-checks model parsing or helper arithmetic duplicates the owner.

## Junk patterns

The shared checklist for both modes: the authoring gate rejects a new test that
matches one, and audits hunt for existing tests that do.

- assertion-free coverage probes (renders without throwing, `expect(x, isNotNull)`
  on something that cannot be null);
- self-comparisons and identity copiers;
- copied fixtures, inventories, manifests, or export lists (e.g. "the catalogue
  has exactly these N ids");
- exact source, import, or string greps;
- private predicate or call-shape tests duplicated at real boundaries;
- duplicate invocations of the same contract;
- replays of shared helpers inside each caller's suite;
- tests whose only purpose is preserving test-only exports, globals, or wrappers;
- dead production code whose only callers are tests;
- expected values produced by the helper or renderer under test;
- mocks that implement the asserted behavior (asserting that a mocked Prisma
  call returns what the mock was told to return), or one identical mock standing
  in for different APIs;
- fixtures that supply the result the code under test should produce, or
  persistence asserted against a store the path never writes;
- tests that restate declared constants or flags instead of exercising the
  behavior they drive;
- negative controls that pass for an unrelated reason, such as a 401 from the
  auth middleware when the test claims to check validation, or a rejection the
  production path never reaches;
- names or fixtures that promise more than the input exercises.

## Value bar

Tests justify their maintenance cost by protecting behavior, a credible
regression, or an independently meaningful contract. In an audit, an existing
test that must change for behavior-preserving source reorganization is suspect,
not automatically deletable; the authoring gate still rejects new ones.

Before judging a candidate, read the complete test and production owner, its
entry point, callers, callees, sibling implementations, overlapping tests, and
relevant `git log` history. Read `CLAUDE.md`, `.nightshift/rules.md` and
`PLAN.md` first. When the test claims dependency-backed behavior (Prisma,
express-validator, GetX, geolocator), inspect the dependency source or types
directly.

## Discovery

Keep discovery read-only and report evidence before editing. Lanes:

- server routes and controllers (`server/src/routes`, `server/src/controllers`);
- server services and utilities (`server/src/services`, `server/src/utils`, config, seed);
- client models, services, and pure helpers (`client/lib/data`, `client/lib/services`);
- client controllers and pages/widgets (`client/lib/src/core/controllers`, `client/lib/views`);
- a cross-cutting pattern sweep for the junk patterns.

Outside campaign mode, prefer a few high-confidence candidates over a large
speculative inventory.

## Retention bar

Keep a test when it independently enforces a public API (route path, status,
JSON shape), auth or ownership rule, security behavior (rate limits, helmet,
admin-only routes), check-in verification (QR + GPS proximity), schema or
migration, privacy guarantee (export, account deletion), default value, or
user-visible copy that matters. Also keep:

- call ordering when order is observable behavior;
- regressions with a credible failure mode;
- source inspection when it is the cheapest independent guard: it fails when
  the contract changes (the user-facing key, byte, or path) and survives an
  identifier-only refactor;
- a retained test that fails on the baseline: treat it as a possible product
  bug, reproduce it, and repair the owner rather than deleting it.

Static or slow is not a deletion reason. A test that resembles implementation
may still be the independent contract; prove otherwise before removing it.

## Candidate evidence

Record every field below before editing. A missing field means the candidate is
not ready for deletion:

- exact test name and location;
- what failure it can actually detect;
- non-test callers of the covered production or support seam;
- stronger remaining owner-boundary proof, or why no proof is needed;
- relevant history and the reason the test or seam exists;
- production or test-support deletion unlocked;
- risk and the focused validation command.

Put a one-line summary of this evidence for each removed or consolidated test
in the commit body.

## Edit shape

Choose one coherent owner-boundary batch. Delete obsolete test-only exports,
globals, wrappers, and dead production paths instead of preserving aliases.
Move retained regressions to their canonical owners. Consolidate repeated
assertions into one table-driven case.

Prefer net-negative production LOC, without changing production behavior. Do
not add replacement tests that restate the same implementation, and do not
convert uncertain candidates into cleanup to increase deletion counts.

## Validation

Never edit source or tests while a test run is in progress in the checkout.

1. Run the smallest owner and sibling tests:
   `cd server && pnpm test -- <file-or-pattern>` or
   `cd client && flutter test test/<file>_test.dart`.
2. Run the full gate exactly as Night Shift does, from the repo root:
   `node .nightshift/test-all.mjs` (prints `TOTAL PASSED TESTS: N`).
3. Run `cd client && dart format .`, `cd client && flutter analyze --no-fatal-infos`,
   then `git diff --check`.
4. Inspect `git diff --numstat`; report production code separately from tests
   and test support.

## Landing

Night Shift agents commit on the current branch and stop; the supervisor lands
the work. Humans commit on a branch and open a PR only when authorized. A
landed audit lowers the passing-test count: for a `[test-audit]` task the
supervisor records the new baseline itself; for a hand-landed audit, record the
new count in `.nightshift/state/test-baseline.json` under the tree of the
landed `develop` commit, or every later Night Shift task fails the count check.

## Handoff

Report:

- removed low-value categories;
- production owner simplifications;
- retained false positives and why they remain valuable;
- baseline failures treated as product bugs;
- focused and full proof actually run;
- production versus test LOC;
- named follow-ups.
