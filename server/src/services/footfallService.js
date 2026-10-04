import { nightStart } from "../utils/night.js";
import { MAX_CHECK_IN_DISTANCE_METERS } from "../utils/geo.js";

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

const nearestRank = (sorted, p) => sorted[Math.max(0, Math.ceil(p * sorted.length) - 1)];

// Distribution of stored check-in distances (metres) for one club; no ids.
export const computeDistanceHealth = (distances, { limit = MAX_CHECK_IN_DISTANCE_METERS } = {}) => {
  const count = distances.length;
  if (count === 0) {
    return {
      count,
      medianMeters: null,
      p90Meters: null,
      nearLimitShare: null,
      status: "insufficient",
    };
  }
  const sorted = [...distances].sort((a, b) => a - b);
  const threshold = 0.8 * limit;
  const medianMeters = Math.round(nearestRank(sorted, 0.5));
  const p90Meters = Math.round(nearestRank(sorted, 0.9));
  const nearLimitShare = sorted.filter((d) => d >= threshold).length / count;
  const status = count < 5 ? "insufficient" : p90Meters >= threshold ? "marginal" : "ok";
  return { count, medianMeters, p90Meters, nearLimitShare, status };
};

// Aggregate 1-5 vibe ratings; below `min` ratings the average and distribution are withheld.
export const computeVibeSummary = (ratings, { min = 5 } = {}) => {
  const valid = ratings.filter((r) => Number.isInteger(r) && r >= 1 && r <= 5);
  const count = valid.length;
  if (count < min) return { count, average: null, distribution: null };
  const distribution = [0, 0, 0, 0, 0];
  for (const r of valid) distribution[r - 1] += 1;
  const average = Math.round((valid.reduce((a, b) => a + b, 0) / count) * 10) / 10;
  return { count, average, distribution };
};

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

// Pure ranking of clubs by check-ins in the last `weeks` weeks vs the same span before; aggregates only, never ids.
// `clubs` is [{ id, name, city }] (approved only); `checkIns` is [{ clubId, userId, checkedInAt }].
export const computeClubRanking = ({ clubs = [], checkIns = [], now = new Date(), weeks = 4 }) => {
  const end = new Date(now).getTime();
  const span = weeks * WEEK_MS;
  const entries = new Map(
    clubs.map((c) => [
      c.id,
      {
        id: c.id,
        name: c.name,
        city: c.city,
        checkIns: 0,
        visitors: new Set(),
        previousCheckIns: 0,
      },
    ])
  );

  for (const c of checkIns) {
    const entry = entries.get(c.clubId);
    if (!entry) continue;
    const at = new Date(c.checkedInAt).getTime();
    if (at > end - span && at <= end) {
      entry.checkIns += 1;
      entry.visitors.add(c.userId);
    } else if (at > end - 2 * span && at <= end - span) {
      entry.previousCheckIns += 1;
    }
  }

  const ranked = [...entries.values()].map((e) => ({
    id: e.id,
    name: e.name,
    city: e.city,
    checkIns: e.checkIns,
    uniqueVisitors: e.visitors.size,
    previousCheckIns: e.previousCheckIns,
    change: e.checkIns - e.previousCheckIns,
  }));
  ranked.sort(
    (a, b) =>
      b.checkIns - a.checkIns ||
      b.uniqueVisitors - a.uniqueVisitors ||
      (a.name < b.name ? -1 : a.name > b.name ? 1 : 0)
  );
  return { weeks, clubs: ranked };
};
