# Test-pruning campaign

Adapted from OpenClaw's `test-audit` campaign guide (MIT License).

Campaign mode prunes a whole suite (`server/src/__tests__` or `client/test`) or
one lane of it in one branch. The value bar, retention bar, candidate evidence,
and validation in [SKILL.md](SKILL.md) apply to every lane. Each step ends on
its completion criterion; do not start the next step early.

## 1. Baseline

Run `node .nightshift/test-all.mjs` on the starting `develop` commit. Record the
test line counts and every test file's pass/fail state. Keep baseline failures
in their own list: they are likely real bugs, not stale tests.

Done when every in-scope test file has a recorded baseline result.

## 2. Lanes and inventory

Split the surface into **lanes** along production owner boundaries, not file
names: for example server auth/account, clubs and check-in, gamification and
stats, app/routes/config; client models and helpers, controllers, pages and
widgets.

Done when every test file belongs to exactly one lane.

## 3. Ledger per lane

Read every assigned test in full, including parameter tables, plus the
production owners, their entry points, callers, and history. Each test
declaration (`test`/`it`/`testWidgets`) goes into a written **ledger** with one
mark. A `test.each` or a loop is one declaration unless its rows need different
marks.

- `R`: retain, naming the contract and the bug it catches; a retained test that
  only moves to a better file stays `R` with the move noted;
- `F`: retain the contract but repair the assertion, such as a vacuous negative
  that passes when only one of several items is missing;
- `C`: consolidate, naming the owner that absorbs the assertion first: a sibling
  table case or a stronger boundary suite;
- `D`: delete, naming the proof that remains, or why no contract exists.

Judge a test by its assertions, not its name.

Done when every declaration in the lane has a mark and an evidence line.

## 4. Layer plan per lane

Treat the ledger as input, not as the edit list. A second pass looks for the
redundant **layer**: route tests replaying controller tests, controller tests
replaying service arithmetic, widget tests re-checking model parsing. Name the
**keeper** suite for each contract. Prefer the real boundary (supertest against
the app, a widget pumped with a fake service) over a mocked collaborator.
Correct any ledger errors this pass finds.

Done when each lane plan names its retired tests, its keeper per contract, the
assertions to carry into keepers, and the test-only production seams unlocked.

## 5. Cutover

Edit lane by lane, one commit per lane
(`test(audit): <lane> — removed N, consolidated M`), with the D/C evidence in
the commit body. With each lane, remove the test-only production seams it
unlocks without changing production behavior.

Done when every lane plan is applied and each lane's keepers pass.

## 6. Preservation review

Before claiming completion, compare deleted coverage against the keepers, one
boundary group at a time. Look for contracts that lost their only proof, and
for new assertions that cannot fail. Restore or move any coverage the review
finds missing.

Done when the review finds no contract without a remaining proof.
