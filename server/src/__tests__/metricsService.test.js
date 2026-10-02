import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";
import { computePilotMetrics } from "../services/metricsService.js";

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

  it("rejects a USER with 403", async () => {
    const res = await request(app).get("/api/admin/metrics").set("Authorization", asRole("USER"));
    expect(res.status).toBe(403);
  });

  it("rejects days=5 with 400", async () => {
    const res = await request(app)
      .get("/api/admin/metrics?days=5")
      .set("Authorization", asRole("ADMIN"));
    expect(res.status).toBe(400);
  });

  it("returns aggregates for an admin", async () => {
    userFindMany.mockResolvedValue([]);
    checkInFindMany.mockResolvedValue([]);
    const res = await request(app).get("/api/admin/metrics").set("Authorization", asRole("ADMIN"));
    expect(res.status).toBe(200);
    expect(res.body.days).toBe(7);
  });
});
