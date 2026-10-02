// Night Shift test gate: runs the client (flutter) and server (jest) suites and prints one
// combined passing-test count. The engine keeps a single test baseline, so only one gate may
// count tests; counting the two suites in separate gates compared flutter's count against
// jest's baseline (3.1: "dropped from 117 to 49").
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';

function run(cwd, cmd) {
  console.log(`\n=== ${cwd}: ${cmd} ===`);
  const r = spawnSync(cmd, { cwd, shell: true, encoding: 'utf8', maxBuffer: 256 * 1024 * 1024 });
  const out = (r.stdout || '') + (r.stderr || '');
  process.stdout.write(out);
  return { code: r.status ?? 1, out };
}

function last(out, re) {
  let n = null;
  for (const m of out.matchAll(re)) n = Number(m[1]);
  return n;
}

let failed = [];
let total = 0;
const parts = [];

if (existsSync('client/pubspec.yaml') && existsSync('client/test')) {
  const r = run('client', 'flutter test --coverage');
  const n = last(r.out, /\+(\d+)(?: ~\d+)?(?: -\d+)?: (?:All tests passed|Some tests failed)/g) ?? 0;
  if (r.code !== 0) failed.push('client (flutter test)');
  total += n;
  parts.push(`client ${n}`);
}

if (existsSync('server/package.json')) {
  const r = run('server', 'pnpm test');
  const n = last(r.out, /Tests:\s+(?:\d+ \w+, )*(\d+) passed/g) ?? 0;
  if (r.code !== 0) failed.push('server (pnpm test)');
  total += n;
  parts.push(`server ${n}`);
}

console.log(`\n=== summary: ${parts.join(', ')} ===`);
if (failed.length) console.log(`FAILED: ${failed.join(', ')}`);
console.log(`TOTAL PASSED TESTS: ${total}`);
process.exit(failed.length ? 1 : 0);
