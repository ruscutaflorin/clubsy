# Agent handoff notes

Only non-obvious gotchas a later task would trip over. **One line each (max ~200 chars), prefixed
with the task id.** No summaries of what a task did — the commits say that. Every agent session
reads this file, so keep it short; the human prunes.

- 1.1: `pubspec.yaml`'s geolocator/mobile_scanner/flutter_map/latlong2 version pins were picked
  without running `pub get` — they may need bumping or pinning down, not just accepting whatever
  resolves.
- 1.2/1.3/1.6: no Postgres is running in this environment; don't add code that assumes
  `DATABASE_URL` is reachable at build/test time.
- B8: `server/src/utils/night.js` defines a "night" as 06:00-06:00 **UTC**, not local/venue time.
  Fine for a single-country pilot; revisit if clubs ever span multiple timezones.
