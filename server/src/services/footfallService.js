import { nightStart } from "../utils/night.js";

const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

// Monday 00:00 UTC of the week containing the given night.
const weekStartOf = (night) => {
  const daysSinceMonday = (night.getUTCDay() + 6) % 7;
  return new Date(
    Date.UTC(night.getUTCFullYear(), night.getUTCMonth(), night.getUTCDate() - daysSinceMonday)
  );
};

const ratio = (n, d) => (d === 0 ? 0 : n / d);

// Pure aggregation over one club's check-in rows (no database); returns aggregates only, never ids.
// `firstVisits` is [{ userId, firstCheckInAt }]: each visitor's earliest check-in at this club ever.
// `byWeekday` is indexed like Date#getUTCDay (0 = Sunday), by the night a check-in belongs to.
export const computeClubFootfall = ({
  checkIns = [],
  firstVisits = [],
  now = new Date(),
  weeks = 12,
}) => {
  const currentWeek = weekStartOf(nightStart(new Date(now)));
  const windowStart = currentWeek.getTime() - (weeks - 1) * WEEK_MS;
  const end = new Date(now);

  const weekly = [];
  const byWeek = new Map();
  for (let i = 0; i < weeks; i++) {
    const start = windowStart + i * WEEK_MS;
    const entry = {
      weekStart: new Date(start).toISOString().slice(0, 10),
      checkIns: 0,
      users: new Set(),
    };
    byWeek.set(start, entry);
    weekly.push(entry);
  }

  const byWeekday = [0, 0, 0, 0, 0, 0, 0];
  const nightsByUser = new Map();
  const earliestByUser = new Map();
  let totalCheckIns = 0;

  for (const c of checkIns) {
    const at = new Date(c.checkedInAt);
    if (at > end) continue;
    const night = nightStart(at);
    const entry = byWeek.get(weekStartOf(night).getTime());
    if (!entry) continue;
    totalCheckIns += 1;
    entry.checkIns += 1;
    entry.users.add(c.userId);
    byWeekday[night.getUTCDay()] += 1;
    if (!nightsByUser.has(c.userId)) nightsByUser.set(c.userId, new Set());
    nightsByUser.get(c.userId).add(night.getTime());
    const prev = earliestByUser.get(c.userId);
    if (prev === undefined || at.getTime() < prev) earliestByUser.set(c.userId, at.getTime());
  }

  const firstByUser = new Map(
    firstVisits.map((f) => [f.userId, new Date(f.firstCheckInAt).getTime()])
  );
  let returning = 0;
  let firstTime = 0;
  for (const [userId, nights] of nightsByUser) {
    const first = firstByUser.get(userId) ?? earliestByUser.get(userId);
    const cameBefore = first < windowStart;
    if (nights.size >= 2 || cameBefore) returning += 1;
    if (!cameBefore) firstTime += 1;
  }
  const uniqueVisitors = nightsByUser.size;

  return {
    totalCheckIns,
    uniqueVisitors,
    returningVisitorRate: ratio(returning, uniqueVisitors),
    firstTimeShare: ratio(firstTime, uniqueVisitors),
    weekly: weekly.map((w) => ({
      weekStart: w.weekStart,
      checkIns: w.checkIns,
      uniqueVisitors: w.users.size,
    })),
    byWeekday,
  };
};
