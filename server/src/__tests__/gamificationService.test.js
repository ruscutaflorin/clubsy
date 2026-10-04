import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const findMany = jest.fn();
const userFindUnique = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    checkIn: { findMany },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");
const { weeklyStreak, badges, weeklyChallenges, points } = await import(
  "../services/gamificationService.js"
);

const ci = (iso, clubId = "c1", city = "A") => ({
  checkedInAt: new Date(iso),
  clubId,
  club: { id: clubId, city },
});
// Wednesday; the ISO weeks start on Mondays 09-14, 09-21, 09-28 and 10-05.
const NOW = new Date("2026-10-07T12:00:00Z");
const badge = (list, id) => list.find((b) => b.id === id);

describe("weeklyStreak", () => {
  it("is 0 for empty history and no badge is earned", () => {
    expect(weeklyStreak([], NOW)).toEqual({ streak: 0, longestStreak: 0, atRisk: false });
    const all = badges([]);
    expect(all.every((b) => b.earnedAt === null)).toBe(true);
    expect(new Set(all.map((b) => b.id)).size).toBe(all.length);
  });

  it("counts W1-W3 when the current week has no check-in yet", () => {
    const list = [ci("2026-09-15T22:00:00Z"), ci("2026-09-22T22:00:00Z"), ci("2026-09-29T22:00:00Z")];
    expect(weeklyStreak(list, NOW).streak).toBe(3);
  });

  it("resets on a gap but keeps longestStreak", () => {
    const list = [
      ci("2026-09-01T22:00:00Z"),
      ci("2026-09-08T22:00:00Z"),
      ci("2026-09-15T22:00:00Z"),
      ci("2026-09-29T22:00:00Z"),
    ];
    expect(weeklyStreak(list, NOW)).toEqual({ streak: 1, longestStreak: 3, atRisk: true });
  });

  it("assigns a Sunday 02:00 check-in to the previous week", () => {
    const list = [ci("2026-10-04T02:00:00Z")];
    expect(weeklyStreak(list, new Date("2026-10-05T12:00:00Z")).streak).toBe(1);
    expect(weeklyStreak(list, new Date("2026-10-12T12:00:00Z")).streak).toBe(0);
  });

  it("flags atRisk when the current week has no check-in yet", () => {
    const prev = [ci("2026-09-22T22:00:00Z"), ci("2026-09-29T22:00:00Z")];
    expect(weeklyStreak(prev, NOW)).toMatchObject({ streak: 2, atRisk: true });
    expect(weeklyStreak([...prev, ci("2026-10-06T22:00:00Z")], NOW)).toMatchObject({
      streak: 3,
      atRisk: false,
    });
    expect(weeklyStreak([], NOW).atRisk).toBe(false);
  });

  it("treats Monday 03:00 UTC as the previous week's night", () => {
    const list = [ci("2026-09-29T22:00:00Z"), ci("2026-10-05T03:00:00Z")];
    expect(weeklyStreak(list, NOW)).toMatchObject({ atRisk: true });
  });
});

describe("badges", () => {
  it("earnedAt for explorer_5 is the 5th distinct club's time", () => {
    const list = [1, 2, 3, 4, 5, 6].map((n) => ci(`2026-09-0${n}T22:00:00Z`, `c${n}`));
    const b = badge(badges(list), "explorer_5");
    expect(b.earnedAt).toEqual(new Date("2026-09-05T22:00:00Z"));
    expect(badge(badges(list), "explorer_15").progress).toEqual({ current: 6, target: 15 });
  });

  it("night_owl, weekend_warrior and streak_4", () => {
    expect(badge(badges([ci("2026-09-02T04:00:00Z")]), "night_owl").earnedAt).not.toBeNull();
    expect(badge(badges([ci("2026-09-02T08:00:00Z")]), "night_owl").earnedAt).toBeNull();
    const weekend = [ci("2026-09-18T22:00:00Z"), ci("2026-09-19T22:00:00Z", "c2")];
    expect(badge(badges(weekend), "weekend_warrior").earnedAt).toEqual(
      new Date("2026-09-19T22:00:00Z")
    );
    const streak = ["2026-09-01", "2026-09-08", "2026-09-15", "2026-09-22"].map((d) =>
      ci(`${d}T22:00:00Z`)
    );
    expect(badge(badges(streak), "streak_4").earnedAt).toEqual(new Date("2026-09-22T22:00:00Z"));
  });

  it("globetrotter and regular", () => {
    const list = [ci("2026-09-01T22:00:00Z", "c1", "A"), ci("2026-09-02T22:00:00Z", "c2", "B")];
    expect(badge(badges(list), "globetrotter_3").progress).toEqual({ current: 2, target: 3 });
    const reg = [1, 2, 3, 4, 5].map((n) => ci(`2026-09-0${n}T22:00:00Z`));
    expect(badge(badges(reg), "regular_5").earnedAt).toEqual(new Date("2026-09-05T22:00:00Z"));
  });
});

describe("weeklyChallenges and points", () => {
  it("tracks progress and resets at the week boundary", () => {
    const list = [ci("2026-10-06T22:00:00Z", "c1"), ci("2026-10-07T22:00:00Z", "c2")];
    expect(weeklyChallenges(list, NOW).map((c) => c.completed)).toEqual([true, true, true]);
    const next = weeklyChallenges(list, new Date("2026-10-12T12:00:00Z"));
    expect(next.map((c) => c.progress.current)).toEqual([0, 0, 0]);
  });

  it("endsAt is the next Monday 00:00 UTC", () => {
    const ends = weeklyChallenges([], NOW).map((c) => c.endsAt.toISOString());
    expect(ends).toEqual(Array(3).fill("2026-10-12T00:00:00.000Z"));
  });

  it("new-club challenge ignores clubs visited before this week", () => {
    const list = [ci("2026-09-20T22:00:00Z", "c1"), ci("2026-10-06T22:00:00Z", "c1")];
    expect(weeklyChallenges(list, NOW)[2].completed).toBe(false);
  });

  it("points: 10 per check-in, 25 per club, 50 per badge", () => {
    expect(points([])).toBe(0);
    expect(points([ci("2026-09-01T22:00:00Z")])).toBe(10 + 25 + 50);
  });
});

describe("GET /api/check-ins/me/achievements", () => {
  it("returns all four sections, evaluated from the caller's check-ins", async () => {
    userFindUnique.mockResolvedValue({ id: "u1", role: "USER" });
    findMany.mockResolvedValue([ci("2026-09-01T22:00:00Z")]);
    const token = jwt.sign({ userId: "u1" }, "test-secret");
    const res = await request(app)
      .get("/api/check-ins/me/achievements")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(Object.keys(res.body).sort()).toEqual(["badges", "challenges", "points", "streak"]);
    expect(badge(res.body.badges, "first_pin").earnedAt).toBe("2026-09-01T22:00:00.000Z");
  });
});
