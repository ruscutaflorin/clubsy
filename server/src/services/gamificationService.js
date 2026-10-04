import { nightStart } from "../utils/night.js";
import { BADGE_CATALOGUE } from "./badgeCatalogue.js";

// Pure functions over a user's check-ins (each including its club) and `now`.
// Assumption: night_owl, nights and weeks use UTC (clubs have no timezone column yet), matching
// utils/night.js. A check-in belongs to the ISO week (Mon-Sun, UTC) of its nightStart.
const DAY_MS = 24 * 60 * 60 * 1000;
const WEEK_MS = 7 * DAY_MS;

const toDate = (value) => new Date(value);

// Index of the week (Monday 00:00 UTC / 7 days) containing the night of `date`.
const weekStartOf = (date) => {
  const night = nightStart(toDate(date));
  const dayStart = Date.UTC(night.getUTCFullYear(), night.getUTCMonth(), night.getUTCDate());
  return dayStart - ((night.getUTCDay() + 6) % 7) * DAY_MS;
};

const weekIndexOf = (date) => Math.round(weekStartOf(date) / WEEK_MS);

const sortedAsc = (checkIns) =>
  [...checkIns].sort((a, b) => toDate(a.checkedInAt) - toDate(b.checkedInAt));

const nightKey = (date) => nightStart(toDate(date)).getTime();

export const weeklyStreak = (checkIns, now = new Date()) => {
  const weeks = [...new Set(checkIns.map((c) => weekIndexOf(c.checkedInAt)))].sort((a, b) => a - b);
  const weekSet = new Set(weeks);

  let longestStreak = 0;
  let run = 0;
  weeks.forEach((week, i) => {
    run = i > 0 && weeks[i - 1] === week - 1 ? run + 1 : 1;
    longestStreak = Math.max(longestStreak, run);
  });

  const currentWeek = weekIndexOf(now);
  // The current week doesn't break the streak until it's over.
  let cursor = weekSet.has(currentWeek) ? currentWeek : currentWeek - 1;
  let streak = 0;
  while (weekSet.has(cursor)) {
    streak += 1;
    cursor -= 1;
  }

  return { streak, longestStreak, atRisk: streak > 0 && !weekSet.has(currentWeek) };
};

const evaluate = (badge, sorted) => {
  const { kind, target } = badge;
  const done = (current, earnedAt) => ({
    earnedAt: current >= target ? (earnedAt ?? null) : null,
    progress: { current: Math.min(current, target), target },
  });

  if (kind === "checkIns") {
    return done(sorted.length, sorted[target - 1]?.checkedInAt);
  }

  if (kind === "clubs" || kind === "cities") {
    const seen = new Set();
    let earnedAt = null;
    for (const c of sorted) {
      seen.add(kind === "clubs" ? c.clubId : c.club.city);
      if (seen.size === target && !earnedAt) earnedAt = c.checkedInAt;
    }
    return done(seen.size, earnedAt);
  }

  if (kind === "regular") {
    const nightsByClub = new Map();
    let best = 0;
    let earnedAt = null;
    for (const c of sorted) {
      const nights = nightsByClub.get(c.clubId) ?? new Set();
      nights.add(nightKey(c.checkedInAt));
      nightsByClub.set(c.clubId, nights);
      best = Math.max(best, nights.size);
      if (nights.size === target && !earnedAt) earnedAt = c.checkedInAt;
    }
    return done(best, earnedAt);
  }

  if (kind === "nightOwl") {
    const hit = sorted.find((c) => {
      const hour = toDate(c.checkedInAt).getUTCHours();
      return hour >= 3 && hour < 6;
    });
    return done(hit ? 1 : 0, hit?.checkedInAt);
  }

  if (kind === "weekend") {
    const daysByWeek = new Map();
    let earnedAt = null;
    for (const c of sorted) {
      const day = nightStart(toDate(c.checkedInAt)).getUTCDay();
      if (day !== 5 && day !== 6) continue;
      const week = weekIndexOf(c.checkedInAt);
      const days = daysByWeek.get(week) ?? new Set();
      days.add(day);
      daysByWeek.set(week, days);
      if (days.size === 2 && !earnedAt) earnedAt = c.checkedInAt;
    }
    return done(earnedAt ? 1 : 0, earnedAt);
  }

  if (kind !== "streak") throw new Error(`Unknown badge kind: ${kind}`);

  // streak: the first check-in of the week that completes a run of `target` weeks.
  const firstInWeek = new Map();
  for (const c of sorted) {
    const week = weekIndexOf(c.checkedInAt);
    if (!firstInWeek.has(week)) firstInWeek.set(week, c.checkedInAt);
  }
  const weeks = [...firstInWeek.keys()].sort((a, b) => a - b);
  let run = 0;
  let best = 0;
  let earnedAt = null;
  weeks.forEach((week, i) => {
    run = i > 0 && weeks[i - 1] === week - 1 ? run + 1 : 1;
    best = Math.max(best, run);
    if (run === target && !earnedAt) earnedAt = firstInWeek.get(week);
  });
  return done(best, earnedAt);
};

export const badges = (checkIns) => {
  const sorted = sortedAsc(checkIns);
  return BADGE_CATALOGUE.map((badge) => {
    const { earnedAt, progress } = evaluate(badge, sorted);
    return {
      id: badge.id,
      title: badge.title,
      description: badge.description,
      earnedAt,
      progress,
    };
  });
};

export const weeklyChallenges = (checkIns, now = new Date()) => {
  const week = weekIndexOf(now);
  const endsAt = new Date(weekStartOf(now) + WEEK_MS);
  const sorted = sortedAsc(checkIns);

  const firstSeen = new Map();
  for (const c of sorted) {
    if (!firstSeen.has(c.clubId)) firstSeen.set(c.clubId, weekIndexOf(c.checkedInAt));
  }

  const thisWeek = sorted.filter((c) => weekIndexOf(c.checkedInAt) === week);
  const weekClubs = [...new Set(thisWeek.map((c) => c.clubId))];
  const nights = new Set(thisWeek.map((c) => nightKey(c.checkedInAt))).size;
  const newClubs = weekClubs.filter((id) => firstSeen.get(id) === week).length;

  const make = (id, title, current, target) => ({
    id,
    title,
    progress: { current: Math.min(current, target), target },
    completed: current >= target,
    endsAt,
  });

  return [
    make("two_clubs", "Check in at 2 different clubs", weekClubs.length, 2),
    make("two_nights", "Go out on 2 nights", nights, 2),
    make("new_club", "Visit a club you've never been to", newClubs, 1),
  ];
};

// Display only: never stored and nothing can spend it.
export const points = (checkIns) => {
  const clubs = new Set(checkIns.map((c) => c.clubId)).size;
  const earned = badges(checkIns).filter((b) => b.earnedAt).length;
  return checkIns.length * 10 + clubs * 25 + earned * 50;
};

export const computeAchievements = (checkIns, now = new Date()) => {
  const { streak, longestStreak, atRisk } = weeklyStreak(checkIns, now);
  return {
    streak: { current: streak, longest: longestStreak, atRisk },
    badges: badges(checkIns),
    challenges: weeklyChallenges(checkIns, now),
    points: points(checkIns),
  };
};
