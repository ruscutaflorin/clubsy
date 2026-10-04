import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const userFindMany = jest.fn();
const clubFindUnique = jest.fn();
const clubFindMany = jest.fn();
const clubCount = jest.fn();
const clubUpdate = jest.fn();
const checkInFindMany = jest.fn();
const checkInGroupBy = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, findMany: userFindMany },
    club: {
      findUnique: clubFindUnique,
      findMany: clubFindMany,
      count: clubCount,
      update: clubUpdate,
    },
    checkIn: { findMany: checkInFindMany, groupBy: checkInGroupBy },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const { displayKey } = await import("../services/venueQrService.js");

const tokenFor = (userId) => jwt.sign({ userId }, "test-secret");
const userToken = tokenFor("u1");
const adminToken = tokenFor("a1");
const auth = (t) => ({ Authorization: `Bearer ${t}` });

const club = { id: "c1", name: "Club", city: "X", qrSecret: "s3cret", isApproved: true };

beforeEach(() => {
  jest.clearAllMocks();
  userFindUnique.mockImplementation(async ({ where }) => {
    if (where.id === "u1") return { id: "u1", email: "u@x.com", role: "USER" };
    if (where.id === "a1") return { id: "a1", email: "a@x.com", role: "ADMIN" };
    return null;
  });
  jest.spyOn(console, "log").mockImplementation(() => {});
  jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => jest.restoreAllMocks());

// Every route mounts its own auth middleware, so each one is checked here; the per-feature
// suites only cover what a signed-in caller sees.
const call = (method, path) => request(app)[method](path);

describe("auth wiring", () => {
  it.each([
    ["get", "/api/auth/me"],
    ["get", "/api/auth/username-available"],
    ["patch", "/api/auth/me"],
    ["delete", "/api/auth/me"],
    ["get", "/api/auth/me/export"],
    ["post", "/api/auth/me/password"],
    ["get", "/api/clubs"],
    ["get", "/api/clubs/c1"],
    ["post", "/api/check-ins"],
    ["get", "/api/check-ins/me"],
    ["get", "/api/check-ins/me/stats"],
    ["get", "/api/check-ins/me/cities"],
    ["get", "/api/check-ins/me/achievements"],
    ["delete", "/api/check-ins/ci1"],
  ])("%s %s returns 401 without a token", async (method, path) => {
    const res = await call(method, path);
    expect(res.status).toBe(401);
  });

  it.each([
    ["post", "/api/clubs"],
    ["patch", "/api/clubs/c1"],
    ["patch", "/api/clubs/c1/approve"],
    ["patch", "/api/clubs/c1/unapprove"],
    ["get", "/api/clubs/c1/qr"],
    ["get", "/api/clubs/c1/display-link"],
    ["post", "/api/clubs/c1/qr/rotate"],
    ["get", "/api/admin/metrics"],
    ["get", "/api/admin/metrics/scorecard"],
    ["get", "/api/admin/clubs/ranking"],
    ["get", "/api/admin/clubs/data-health"],
    ["get", "/api/admin/clubs/c1/footfall"],
  ])("%s %s is admin only (401 anonymous, 403 USER)", async (method, path) => {
    expect((await call(method, path)).status).toBe(401);
    const res = await call(method, path).set(auth(userToken)).send({ name: "N" });
    expect(res.status).toBe(403);
    expect(clubUpdate).not.toHaveBeenCalled();
    expect(clubFindUnique).not.toHaveBeenCalled();
    expect(checkInFindMany).not.toHaveBeenCalled();
  });
});

describe("club routes", () => {
  it("GET /api/clubs hides qrSecret from USER", async () => {
    clubFindMany.mockResolvedValue([club]);
    clubCount.mockResolvedValue(1);
    const res = await request(app).get("/api/clubs").set(auth(userToken));
    expect(res.status).toBe(200);
    expect(res.body.clubs).toHaveLength(1);
    res.body.clubs.forEach((c) => expect(c).not.toHaveProperty("qrSecret"));
  });

  it("GET /api/clubs includes qrSecret for ADMIN", async () => {
    clubFindMany.mockResolvedValue([club]);
    clubCount.mockResolvedValue(1);
    const res = await request(app).get("/api/clubs").set(auth(adminToken));
    expect(res.status).toBe(200);
    expect(res.body.clubs[0].qrSecret).toBe("s3cret");
  });

  it("PATCH /api/clubs/:id rejects latitude 200", async () => {
    const res = await request(app)
      .patch("/api/clubs/c1")
      .set(auth(adminToken))
      .send({ latitude: 200 });
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
    expect(clubUpdate).not.toHaveBeenCalled();
  });

  it.each(["qrSecret", "isApproved", "id"])("PATCH /api/clubs/:id rejects %s", async (field) => {
    const res = await request(app)
      .patch("/api/clubs/c1")
      .set(auth(adminToken))
      .send({ name: "N", [field]: "x" });
    expect(res.status).toBe(400);
    expect(clubUpdate).not.toHaveBeenCalled();
  });

  it("PATCH /api/clubs/:id rejects a non-https imageUrl", async () => {
    const res = await request(app)
      .patch("/api/clubs/c1")
      .set(auth(adminToken))
      .send({ imageUrl: "http://x.com/a.png" });
    expect(res.status).toBe(400);
  });

  it("PATCH /api/clubs/:id applies a partial update and returns qrSecret", async () => {
    clubUpdate.mockResolvedValue(club);
    const res = await request(app)
      .patch("/api/clubs/c1")
      .set(auth(adminToken))
      .send({ name: "  New  ", latitude: 44.4, imageUrl: "https://x.com/a.png" });
    expect(res.status).toBe(200);
    expect(res.body.qrSecret).toBe("s3cret");
    expect(clubUpdate).toHaveBeenCalledWith({
      where: { id: "c1" },
      data: { name: "New", latitude: 44.4, imageUrl: "https://x.com/a.png" },
    });
  });
});

// The display page and QR endpoint themselves are covered in venueDisplayController.test.js.
describe("venue display link", () => {
  it("GET /api/clubs/:id/display-link returns the keyed display url", async () => {
    clubFindUnique.mockResolvedValue(club);
    const res = await request(app).get("/api/clubs/c1/display-link").set(auth(adminToken));
    expect(res.status).toBe(200);
    expect(res.body.url).toContain(`/venue-display/c1?key=${displayKey(club)}`);
  });
});

describe("stats, health and fallbacks", () => {
  it("POST /api/check-ins returns 400 {errors} when isMocked is not a boolean", async () => {
    const res = await request(app)
      .post("/api/check-ins")
      .set(auth(userToken))
      .send({
        clubId: "c1",
        qrPayload: "x",
        latitude: 45,
        longitude: 25,
        isMocked: "yes",
      });
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
  });

  it("GET /api/check-ins/me/cities returns per-city progress", async () => {
    const when = new Date("2026-09-01T22:00:00.000Z");
    checkInFindMany.mockResolvedValue([
      { clubId: "c1", checkedInAt: when, club: { id: "c1", city: "X" } },
    ]);
    clubFindMany.mockResolvedValue([
      { id: "c1", city: "X" },
      { id: "c2", city: "X" },
    ]);
    const res = await request(app).get("/api/check-ins/me/cities").set(auth(userToken));
    expect(res.status).toBe(200);
    expect(res.body).toEqual([
      { city: "X", visitedClubs: 1, totalClubs: 2, lastVisitedAt: when.toISOString() },
    ]);
  });

  it("GET /health returns ok", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ status: "ok" });
  });

  it("returns a JSON 404 for an unknown route", async () => {
    const res = await request(app).get("/nope");
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ message: "Not found" });
  });

  it("returns 400 for a malformed JSON body", async () => {
    const res = await request(app)
      .post("/api/auth/signin")
      .set("Content-Type", "application/json")
      .send("{bad json");
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ message: "Malformed JSON body" });
  });
});

describe("admin metrics routes", () => {
  it("400s on a days value outside 7/30/90 without querying", async () => {
    const res = await request(app).get("/api/admin/metrics?days=5").set(auth(adminToken));
    expect(res.status).toBe(400);
    expect(res.body).toEqual({ message: "days must be 7, 30 or 90" });
    expect(checkInFindMany).not.toHaveBeenCalled();
  });

  it("returns 200 for metrics with a valid days value", async () => {
    userFindMany.mockResolvedValue([]);
    checkInFindMany.mockResolvedValue([]);
    const res = await request(app).get("/api/admin/metrics?days=30").set(auth(adminToken));
    expect(res.status).toBe(200);
  });

  it("returns 500 {message} when the metrics query fails", async () => {
    userFindMany.mockRejectedValue(new Error("db down"));
    checkInFindMany.mockResolvedValue([]);
    const res = await request(app).get("/api/admin/metrics").set(auth(adminToken));
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ message: "Failed to compute metrics" });
  });

  it("returns 200 for the scorecard and 500 when it fails", async () => {
    userFindMany.mockResolvedValue([]);
    checkInFindMany.mockResolvedValue([]);
    clubCount.mockResolvedValue(3);
    const ok = await request(app).get("/api/admin/metrics/scorecard").set(auth(adminToken));
    expect(ok.status).toBe(200);

    clubCount.mockRejectedValue(new Error("db down"));
    const bad = await request(app).get("/api/admin/metrics/scorecard").set(auth(adminToken));
    expect(bad.status).toBe(500);
    expect(bad.body).toEqual({ message: "Failed to compute scorecard" });
  });
});

describe("admin club ranking route", () => {
  it("returns 200 with ranked clubs and no user ids for an admin", async () => {
    clubFindMany.mockResolvedValue([
      { id: "c1", name: "Alpha", city: "X" },
      { id: "c2", name: "Beta", city: "Y" },
    ]);
    checkInFindMany.mockResolvedValue([{ clubId: "c2", userId: "u1", checkedInAt: new Date() }]);
    const res = await request(app).get("/api/admin/clubs/ranking").set(auth(adminToken));
    expect(res.status).toBe(200);
    expect(res.body.clubs.map((c) => c.id)).toEqual(["c2", "c1"]);
    expect(JSON.stringify(res.body)).not.toContain("userId");
    expect(JSON.stringify(res.body)).not.toContain("u1");
  });
});

describe("admin club data health route", () => {
  it("returns 200 with the three lists and no qrSecret for an admin", async () => {
    clubFindMany.mockResolvedValue([
      { id: "c1", name: "Zero", city: "X", latitude: 0, longitude: 0, isApproved: false },
    ]);
    const res = await request(app).get("/api/admin/clubs/data-health").set(auth(adminToken));
    expect(res.status).toBe(200);
    expect(Object.keys(res.body).sort()).toEqual([
      "farFromCity",
      "invalidCoordinates",
      "nearDuplicates",
    ]);
    expect(res.body.invalidCoordinates).toHaveLength(1);
    expect(JSON.stringify(res.body)).not.toContain("qrSecret");
  });
});

describe("admin club footfall route", () => {
  it("returns 404 for an unknown club", async () => {
    clubFindUnique.mockResolvedValue(null);
    const res = await request(app).get("/api/admin/clubs/nope/footfall").set(auth(adminToken));
    expect(res.status).toBe(404);
    expect(res.body.message).toBeDefined();
  });

  it("defaults to 12 weekly buckets, with distance health and no user ids", async () => {
    clubFindUnique.mockResolvedValue({ id: "c1" });
    checkInFindMany.mockResolvedValue([
      { userId: "u1", checkedInAt: new Date(), distanceMeters: 42 },
    ]);
    checkInGroupBy.mockResolvedValue([{ userId: "u1", _min: { checkedInAt: new Date() } }]);
    const res = await request(app).get("/api/admin/clubs/c1/footfall").set(auth(adminToken));
    expect(res.status).toBe(200);
    expect(res.body.weekly).toHaveLength(12);
    expect(res.body.distance.count).toBe(1);
    expect(JSON.stringify(res.body)).not.toMatch(/userId|u1/);
  });

  it("honours ?weeks=4", async () => {
    clubFindUnique.mockResolvedValue({ id: "c1" });
    checkInFindMany.mockResolvedValue([]);
    const res = await request(app).get("/api/admin/clubs/c1/footfall?weeks=4").set(auth(adminToken));
    expect(res.status).toBe(200);
    expect(res.body.weekly).toHaveLength(4);
  });

  it.each(["5", "abc"])("rejects ?weeks=%s before querying", async (w) => {
    const res = await request(app).get(`/api/admin/clubs/c1/footfall?weeks=${w}`).set(auth(adminToken));
    expect(res.status).toBe(400);
    expect(res.body.message).toBe("weeks must be 4, 12, 26 or 52");
    expect(checkInFindMany).not.toHaveBeenCalled();
  });
});
