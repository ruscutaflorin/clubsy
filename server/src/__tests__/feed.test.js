import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const fFindMany = jest.fn();
const ciFindMany = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    friendship: { findMany: fFindMany },
    checkIn: { findMany: ciFindMany },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");
const { nightStart } = await import("../utils/night.js");

const auth = { Authorization: `Bearer ${jwt.sign({ userId: "u1" }, "test-secret")}` };

beforeEach(() => {
  jest.resetAllMocks();
  userFindUnique.mockImplementation(async ({ where }) => ({
    id: where.id,
    email: "u@x.com",
    role: "USER",
    shareNightsWithFriends: true,
  }));
  fFindMany.mockResolvedValue([
    { requesterId: "u1", addresseeId: "u2" },
    { requesterId: "u3", addresseeId: "u1" },
  ]);
});

describe("GET /api/feed", () => {
  it("only asks for ended nights of unhidden, sharing, unblocked friends", async () => {
    ciFindMany.mockResolvedValue([]);
    await request(app).get("/api/feed").set(auth);
    const { where } = ciFindMany.mock.calls[0][0];
    expect(where.userId).toEqual({ in: ["u2", "u3"] });
    expect(where.hiddenFromFriends).toBe(false);
    expect(where.user.is.shareNightsWithFriends).toBe(true);
    expect(where.user.is.blocksMade).toEqual({ none: { blockedId: "u1" } });
    expect(where.user.is.blocksReceived).toEqual({ none: { blockerId: "u1" } });
    // Tonight's check-in is excluded until 06:00: the cutoff is the current night's start.
    expect(where.checkedInAt.lt.getTime()).toBe(nightStart(new Date()).getTime());
  });

  it("returns nothing when the viewer doesn't share their own nights", async () => {
    userFindUnique.mockImplementation(async ({ where }) => ({
      id: where.id,
      role: "USER",
      shareNightsWithFriends: false,
    }));
    const res = await request(app).get("/api/feed").set(auth);
    expect(res.body.nights).toEqual([]);
    expect(ciFindMany).not.toHaveBeenCalled();
  });

  it("shows club and night date but never the check-in time, and paginates", async () => {
    const rows = Array.from({ length: 21 }, (_, i) => ({
      id: `c${i}`,
      checkedInAt: new Date("2026-10-02T01:30:00Z"),
      clubId: "k1",
      club: { id: "k1", name: "Club", city: "X" },
      user: { id: "u2", username: "bob", name: "Bob" },
    }));
    ciFindMany.mockResolvedValue(rows);
    const res = await request(app).get("/api/feed?page=2").set(auth);
    expect(res.body.nights).toHaveLength(20);
    expect(res.body.hasMore).toBe(true);
    expect(res.body.nights[0].nightDate).toBe("2026-10-01");
    expect(ciFindMany.mock.calls[0][0].skip).toBe(20);
    expect(JSON.stringify(res.body)).not.toMatch(/checkedInAt|01:30/);
  });
});

describe("GET /api/feed/friends/:userId", () => {
  const row = (id, clubId) => ({
    id,
    checkedInAt: new Date("2026-10-02T01:30:00Z"),
    clubId,
    club: { id: clubId, name: `Club ${clubId}`, city: "X" },
  });

  it("narrows the visible check-ins to the requested friend", async () => {
    ciFindMany.mockResolvedValue([]);
    await request(app).get("/api/feed/friends/u2").set(auth);
    const { where } = ciFindMany.mock.calls[0][0];
    expect(where.userId).toEqual({ in: ["u2", "u3"] });
    expect(where.AND).toEqual([{ userId: "u2" }]);
    expect(where.hiddenFromFriends).toBe(false);
    expect(where.checkedInAt.lt.getTime()).toBe(nightStart(new Date()).getTime());
  });

  it("returns an empty list without querying when the viewer doesn't share", async () => {
    userFindUnique.mockImplementation(async ({ where }) => ({
      id: where.id,
      role: "USER",
      shareNightsWithFriends: false,
    }));
    const res = await request(app).get("/api/feed/friends/u2").set(auth);
    expect(res.body.nights).toEqual([]);
    expect(res.body.sharedClubCount).toBe(0);
    expect(ciFindMany).not.toHaveBeenCalled();
  });

  it("counts clubs both have been to and never exposes the check-in time", async () => {
    ciFindMany.mockImplementation(async ({ where, distinct }) => {
      if (where.userId === "u1") return [{ clubId: "B" }, { clubId: "C" }];
      if (distinct) return [{ clubId: "A" }, { clubId: "B" }];
      return [row("c1", "A"), row("c2", "B")];
    });
    const res = await request(app).get("/api/feed/friends/u2").set(auth);
    expect(res.body.sharedClubCount).toBe(1);
    expect(res.body.nights[0]).toEqual({
      id: "c1",
      nightDate: "2026-10-01",
      club: { id: "A", name: "Club A", city: "X" },
    });
    expect(JSON.stringify(res.body)).not.toMatch(/checkedInAt|01:30/);
  });

  it("requires a token", async () => {
    const res = await request(app).get("/api/feed/friends/u2");
    expect(res.status).toBe(401);
  });
});

describe("GET /api/feed/clubs/:clubId/friends-count", () => {
  it("counts distinct qualifying friends only", async () => {
    ciFindMany.mockResolvedValue([{ userId: "u2" }, { userId: "u3" }]);
    const res = await request(app).get("/api/feed/clubs/k1/friends-count").set(auth);
    expect(res.body).toEqual({ count: 2 });
    expect(ciFindMany.mock.calls[0][0].where.clubId).toBe("k1");
  });
});
