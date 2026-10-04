import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";
import { computePilotMetrics, computePilotScorecard } from "../services/metricsService.js";

const userFindUnique = jest.fn();
const userFindMany = jest.fn();
const checkInFindMany = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, findMany: userFindMany },
    checkIn: { findMany: checkInFindMany },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const now = new Date("2026-10-02T12:00:00Z");
const ci = (userId, clubId, at, name = clubId) => ({
  userId,
  clubId,
  checkedInAt: new Date(at),
  club: { name },
});

describe("computePilotMetrics", () => {
  it("gives zeros and no NaN for an empty dataset", () => {
    const m = computePilotMetrics({ users: [], checkIns: [], now, days: 7 });
    expect(m).toMatchObject({
      signups: 0,
      activeCheckInUsers: 0,
      checkIns: 0,
      nightsOut: 0,
      activationRate: 0,
      returningUsers: 0,
      topClubs: [],
    });
    expect(m.daily).toHaveLength(7);
    expect(JSON.stringify(m)).not.toMatch(/NaN|null/);
  });

  it("counts two check-ins by one user on the same night as one night out", () => {
    const m = computePilotMetrics({
      users: [],
      checkIns: [
        ci("u1", "c1", "2026-10-01T22:00:00Z"),
        ci("u1", "c2", "2026-10-02T01:00:00Z"),
      ],
      now,
    });
    expect(m.checkIns).toBe(2);
    expect(m.nightsOut).toBe(1);
    expect(m.returningUsers).toBe(0);
  });

  it("counts returning users with 2+ nights", () => {
    const m = computePilotMetrics({
      users: [],
      checkIns: [ci("u1", "c1", "2026-09-29T22:00:00Z"), ci("u1", "c1", "2026-10-01T22:00:00Z")],
      now,
    });
    expect(m.returningUsers).toBe(1);
    expect(m.nightsOut).toBe(2);
  });

  it("counts activation only for signups inside the window", () => {
    const m = computePilotMetrics({
      users: [
        { id: "old", createdAt: new Date("2026-08-01T00:00:00Z") },
        { id: "a", createdAt: new Date("2026-09-30T00:00:00Z") },
        { id: "b", createdAt: new Date("2026-09-30T00:00:00Z") },
      ],
      checkIns: [ci("old", "c1", "2026-10-01T22:00:00Z"), ci("a", "c1", "2026-10-01T22:00:00Z")],
      now,
    });
    expect(m.signups).toBe(2);
    expect(m.activationRate).toBe(0.5);
  });

  it("orders topClubs ties by name", () => {
    const m = computePilotMetrics({
      users: [],
      checkIns: [
        ci("u1", "c2", "2026-10-01T22:00:00Z", "Zed"),
        ci("u2", "c1", "2026-10-01T22:00:00Z", "Alpha"),
      ],
      now,
    });
    expect(m.topClubs.map((c) => c.name)).toEqual(["Alpha", "Zed"]);
    expect(m.topClubs[0]).toEqual({ id: "c1", name: "Alpha", count: 1, uniqueVisitors: 1 });
  });

  it("contains no email key at any depth", () => {
    const m = computePilotMetrics({
      users: [{ id: "u1", email: "x@y.z", createdAt: new Date("2026-10-01T00:00:00Z") }],
      checkIns: [ci("u1", "c1", "2026-10-01T22:00:00Z")],
      now,
    });
    expect(JSON.stringify(m)).not.toMatch(/email|u1/);
  });
});

describe("GET /api/admin/metrics", () => {
  beforeEach(() => {
    jest.spyOn(console, "log").mockImplementation(() => {});
  });
  afterEach(() => jest.restoreAllMocks());

  const asRole = (role) => {
    userFindUnique.mockResolvedValue({ id: "u1", email: "a@b.c", role });
    return `Bearer ${jwt.sign({ userId: "u1" }, "test-secret")}`;
  };

  it("defaults to a 7-day window for an admin", async () => {
    userFindMany.mockResolvedValue([]);
    checkInFindMany.mockResolvedValue([]);
    const res = await request(app).get("/api/admin/metrics").set("Authorization", asRole("ADMIN"));
    expect(res.status).toBe(200);
    expect(res.body.days).toBe(7);
  });
});

describe("computePilotScorecard", () => {
  const DAY = 24 * 60 * 60 * 1000;
  const ago = (d) => new Date(now.getTime() - d * DAY);
  const crit = (s, id) => s.criteria.find((c) => c.id === id);

  it("handles empty input", () => {
    const s = computePilotScorecard({ now });
    expect(crit(s, "signups").value).toBe(0);
    expect(crit(s, "activation")).toMatchObject({ value: null, met: false });
    expect(crit(s, "retention")).toMatchObject({ value: null, met: false });
    expect(s.wacu).toHaveLength(8);
    expect(s.wacu.every((w) => w.activeUsers === 0)).toBe(true);
  });

  it("counts retention by distinct nights", () => {
    const t = ago(40).getTime();
    const users = [
      { id: "a", createdAt: new Date(t) },
      { id: "b", createdAt: new Date(t) },
    ];
    const day = Math.floor(t / DAY) * DAY + 5 * DAY;
    const checkIns = [
      { userId: "a", checkedInAt: new Date(t + 1 * DAY) },
      { userId: "a", checkedInAt: new Date(t + 3 * DAY) },
      { userId: "b", checkedInAt: new Date(day + 1 * 3600000) },
      { userId: "b", checkedInAt: new Date(day + 3 * 3600000) },
    ];
    const s = computePilotScorecard({ users, checkIns, now });
    expect(crit(s, "activation").value).toBe(1);
    expect(crit(s, "retention").value).toBe(0.5);
  });

  it("excludes recent signups from activation", () => {
    const s = computePilotScorecard({ users: [{ id: "n", createdAt: ago(5) }], now });
    expect(crit(s, "activation").value).toBeNull();
  });

  it("meets partner clubs at 10 and leaks no user ids", () => {
    const s = computePilotScorecard({
      users: [{ id: "u1", createdAt: ago(20) }],
      checkIns: [{ userId: "u1", checkedInAt: ago(19) }],
      approvedClubCount: 10,
      now,
    });
    expect(crit(s, "partner_clubs").met).toBe(true);
    expect(JSON.stringify(s)).not.toMatch(/userId|u1/);
  });
});
