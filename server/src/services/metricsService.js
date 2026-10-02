import { nightStart } from "../utils/night.js";

const DAY_MS = 24 * 60 * 60 * 1000;
const ACTIVATION_DAYS = 14;
const TOP_CLUBS = 5;

const dayKey = (date) => date.toISOString().slice(0, 10);

// Pure aggregation over user and check-in rows (no database); returns aggregates only.
export const computePilotMetrics = ({ users = [], checkIns = [], now = new Date(), days = 7 }) => {
  const end = new Date(now);
  const start = new Date(end.getTime() - days * DAY_MS);
  const inWindow = (date) => date >= start && date <= end;

  const windowCheckIns = checkIns
    .map((c) => ({ ...c, at: new Date(c.checkedInAt) }))
    .filter((c) => inWindow(c.at));

  const activeUsers = new Set(windowCheckIns.map((c) => c.userId));
  const nights = new Set();
  const nightsByUser = new Map();
  const clubs = new Map();
  for (const c of windowCheckIns) {
    const night = nightStart(c.at).getTime();
    nights.add(`${c.userId}|${night}`);
    if (!nightsByUser.has(c.userId)) nightsByUser.set(c.userId, new Set());
    nightsByUser.get(c.userId).add(night);

    const entry = clubs.get(c.clubId) ?? {
      id: c.clubId,
      name: c.club?.name ?? "",
      count: 0,
      visitors: new Set(),
    };
    entry.count += 1;
    entry.visitors.add(c.userId);
    clubs.set(c.clubId, entry);
  }

  const signups = users
    .map((u) => ({ id: u.id, at: new Date(u.createdAt) }))
    .filter((u) => inWindow(u.at));
  const activated = signups.filter((u) =>
    checkIns.some((c) => {
      if (c.userId !== u.id) return false;
      const at = new Date(c.checkedInAt).getTime();
      return at >= u.at.getTime() && at <= u.at.getTime() + ACTIVATION_DAYS * DAY_MS;
    })
  ).length;

  const topClubs = [...clubs.values()]
    .sort((a, b) => b.count - a.count || a.name.localeCompare(b.name))
    .slice(0, TOP_CLUBS)
    .map((c) => ({ id: c.id, name: c.name, count: c.count, uniqueVisitors: c.visitors.size }));

  const daily = [];
  const byDay = new Map();
  for (let i = days - 1; i >= 0; i--) {
    const entry = {
      date: dayKey(new Date(end.getTime() - i * DAY_MS)),
      checkIns: 0,
      users: new Set(),
    };
    byDay.set(entry.date, entry);
    daily.push(entry);
  }
  for (const c of windowCheckIns) {
    const entry = byDay.get(dayKey(c.at));
    if (!entry) continue;
    entry.checkIns += 1;
    entry.users.add(c.userId);
  }

  return {
    days,
    signups: signups.length,
    activeCheckInUsers: activeUsers.size,
    checkIns: windowCheckIns.length,
    nightsOut: nights.size,
    activationRate: signups.length === 0 ? 0 : activated / signups.length,
    returningUsers: [...nightsByUser.values()].filter((n) => n.size >= 2).length,
    topClubs,
    daily: daily.map((d) => ({ date: d.date, checkIns: d.checkIns, activeUsers: d.users.size })),
  };
};
