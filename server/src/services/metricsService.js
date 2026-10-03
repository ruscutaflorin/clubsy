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

const WEEK_MS = 7 * DAY_MS;
const RETENTION_DAYS = 30;
const TARGETS = { partnerClubs: 10, signups: 200, activation: 0.4, retention: 0.25 };

// Pure pilot exit scorecard: the four PLAN.md exit criteria plus weekly active check-in users.
export const computePilotScorecard = ({
  users = [],
  checkIns = [],
  approvedClubCount = 0,
  now = new Date(),
  weeks = 8,
}) => {
  const nowMs = new Date(now).getTime();
  const byUser = new Map();
  for (const c of checkIns) {
    if (!byUser.has(c.userId)) byUser.set(c.userId, []);
    byUser.get(c.userId).push(new Date(c.checkedInAt));
  }

  let eligible = 0;
  let activated = 0;
  let retentionEligible = 0;
  let retained = 0;
  for (const u of users) {
    const signedUp = new Date(u.createdAt).getTime();
    const mine = byUser.get(u.id) ?? [];
    const within = (days) =>
      mine.filter((d) => d.getTime() >= signedUp && d.getTime() <= signedUp + days * DAY_MS);
    if (signedUp > nowMs - ACTIVATION_DAYS * DAY_MS) continue;
    eligible += 1;
    if (within(ACTIVATION_DAYS).length === 0) continue;
    activated += 1;
    if (signedUp > nowMs - RETENTION_DAYS * DAY_MS) continue;
    retentionEligible += 1;
    const nights = new Set(within(RETENTION_DAYS).map((d) => nightStart(d).getTime()));
    if (nights.size >= 2) retained += 1;
  }

  const rate = (id, label, num, den, target) => {
    const value = den === 0 ? null : num / den;
    return { id, label, value, target, met: value !== null && value >= target };
  };

  const wacu = [];
  for (let i = weeks - 1; i >= 0; i--) {
    const end = nowMs - i * WEEK_MS;
    const start = end - WEEK_MS;
    let activeUsers = 0;
    for (const dates of byUser.values()) {
      if (dates.some((d) => d.getTime() > start && d.getTime() <= end)) activeUsers += 1;
    }
    wacu.push({ weekStart: new Date(start).toISOString(), activeUsers });
  }

  return {
    criteria: [
      {
        id: "partner_clubs",
        label: "Partner clubs",
        value: approvedClubCount,
        target: TARGETS.partnerClubs,
        met: approvedClubCount >= TARGETS.partnerClubs,
      },
      {
        id: "signups",
        label: "Signups",
        value: users.length,
        target: TARGETS.signups,
        met: users.length >= TARGETS.signups,
      },
      rate("activation", "Activation (14 days)", activated, eligible, TARGETS.activation),
      rate("retention", "2+ nights in 30 days", retained, retentionEligible, TARGETS.retention),
    ],
    wacu,
  };
};
