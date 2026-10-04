import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const userFindFirst = jest.fn();
const fFindFirst = jest.fn();
const fFindMany = jest.fn();
const fCreate = jest.fn();
const fDeleteMany = jest.fn();
const bUpsert = jest.fn();
const bDeleteMany = jest.fn();
const bFindMany = jest.fn();
const rCreate = jest.fn();
const rFindMany = jest.fn();
const rFindUnique = jest.fn();
const rUpdate = jest.fn();
const rGroupBy = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, findFirst: userFindFirst },
    friendship: {
      findFirst: fFindFirst,
      findMany: fFindMany,
      create: fCreate,
      deleteMany: fDeleteMany,
    },
    block: { upsert: bUpsert, deleteMany: bDeleteMany, findMany: bFindMany },
    report: {
      create: rCreate,
      findMany: rFindMany,
      findUnique: rFindUnique,
      update: rUpdate,
      groupBy: rGroupBy,
    },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");
const { visibleToUser } = await import("../utils/blocks.js");

const tokenFor = (id) => ({ Authorization: `Bearer ${jwt.sign({ userId: id }, "test-secret")}` });
const auth = tokenFor("u1");
const adminAuth = tokenFor("admin1");

beforeEach(() => {
  jest.resetAllMocks();
  userFindUnique.mockImplementation(async ({ where }) => ({
    id: where.id,
    email: "u@x.com",
    role: where.id === "admin1" ? "ADMIN" : "USER",
  }));
});

describe("POST /api/blocks", () => {
  it("removes any friendship or pending request in both directions, then records the block", async () => {
    const res = await request(app).post("/api/blocks").set(auth).send({ userId: "u2" });
    expect(res.status).toBe(201);
    expect(fDeleteMany).toHaveBeenCalledWith({
      where: {
        OR: [
          { requesterId: "u1", addresseeId: "u2" },
          { requesterId: "u2", addresseeId: "u1" },
        ],
      },
    });
    expect(bUpsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: { blockerId: "u1", blockedId: "u2" } }),
    );
  });

  it("rejects blocking yourself (400) and an unknown user (404)", async () => {
    expect((await request(app).post("/api/blocks").set(auth).send({ userId: "u1" })).status).toBe(400);
    userFindUnique.mockResolvedValueOnce({ id: "u1", role: "USER" }); // auth lookup
    userFindUnique.mockResolvedValueOnce(null);
    expect((await request(app).post("/api/blocks").set(auth).send({ userId: "ghost" })).status).toBe(404);
    expect(bUpsert).not.toHaveBeenCalled();
  });
});

describe("unblocking", () => {
  it("only removes the block and never recreates the friendship", async () => {
    const res = await request(app).delete("/api/blocks/u2").set(auth);
    expect(res.status).toBe(200);
    expect(bDeleteMany).toHaveBeenCalledWith({ where: { blockerId: "u1", blockedId: "u2" } });
    expect(fCreate).not.toHaveBeenCalled();
  });
});

describe("social queries filter blocks in both directions", () => {
  it("visibleToUser excludes users I blocked and users who blocked me", () => {
    expect(visibleToUser("me")).toEqual({
      blocksMade: { none: { blockedId: "me" } },
      blocksReceived: { none: { blockerId: "me" } },
    });
  });

  it("a friend request to a blocked (or blocking) user looks like an unknown username and creates nothing", async () => {
    userFindFirst.mockResolvedValue(null); // the filtered lookup finds nobody
    const res = await request(app).post("/api/friends/requests").set(auth).send({ username: "bobby" });
    expect(res.status).toBe(202);
    expect(userFindFirst.mock.calls[0][0].where).toEqual({ username: "bobby", ...visibleToUser("u1") });
    expect(fCreate).not.toHaveBeenCalled();
  });

  it("the friends list filters both ends of every row", async () => {
    fFindMany.mockResolvedValue([]);
    await request(app).get("/api/friends").set(auth);
    const where = fFindMany.mock.calls[0][0].where;
    expect(where.requester).toEqual(visibleToUser("u1"));
    expect(where.addressee).toEqual(visibleToUser("u1"));
  });
});

describe("GET /api/blocks", () => {
  it("lists the users I blocked", async () => {
    bFindMany.mockResolvedValue([
      { id: "b1", blocked: { id: "u2", username: "bob", name: "Bob" }, createdAt: "2026-10-01" },
    ]);
    const res = await request(app).get("/api/blocks").set(auth);
    expect(res.body.blocked).toEqual([
      { id: "b1", user: { id: "u2", username: "bob", name: "Bob" }, createdAt: "2026-10-01" },
    ]);
    expect(bFindMany.mock.calls[0][0].where).toEqual({ blockerId: "u1" });
  });
});

describe("POST /api/reports", () => {
  const report = (body) => request(app).post("/api/reports").set(auth).send(body);

  it("stores an open report", async () => {
    const res = await report({ userId: "u2", reason: "SPAM", details: "sends junk" });
    expect(res.status).toBe(201);
    expect(rCreate).toHaveBeenCalledWith({
      data: { reporterId: "u1", reportedUserId: "u2", reason: "SPAM", details: "sends junk" },
    });
  });

  it("rejects an unknown reason, details over 500 chars and self-reports", async () => {
    expect((await report({ userId: "u2", reason: "RUDE" })).status).toBe(400);
    expect((await report({ userId: "u2", reason: "SPAM", details: "x".repeat(501) })).status).toBe(400);
    expect((await report({ userId: "u1", reason: "SPAM" })).status).toBe(400);
    expect(rCreate).not.toHaveBeenCalled();
  });
});

describe("admin report queue", () => {
  it("is admin-only", async () => {
    expect((await request(app).get("/api/admin/reports").set(auth)).status).toBe(403);
    expect(rFindMany).not.toHaveBeenCalled();
  });

  it("flags a user with 3 or more open reports", async () => {
    const row = (id, reportedUserId) => ({ id, reportedUserId, status: "OPEN" });
    rFindMany.mockResolvedValue([row("r1", "u2"), row("r2", "u3")]);
    rGroupBy.mockResolvedValue([
      { reportedUserId: "u2", _count: { _all: 3 } },
      { reportedUserId: "u3", _count: { _all: 2 } },
    ]);
    const res = await request(app).get("/api/admin/reports").set(adminAuth);
    expect(res.status).toBe(200);
    expect(res.body.reports.map((r) => [r.id, r.openReports, r.flagged])).toEqual([
      ["r1", 3, true],
      ["r2", 2, false],
    ]);
  });

  it("resolves an open report once, recording who handled it", async () => {
    rFindUnique.mockResolvedValueOnce({ id: "r1", status: "OPEN" });
    const res = await request(app)
      .post("/api/admin/reports/r1/resolve")
      .set(adminAuth)
      .send({ status: "ACTIONED" });
    expect(res.status).toBe(200);
    expect(rUpdate).toHaveBeenCalledWith({
      where: { id: "r1" },
      data: { status: "ACTIONED", handledById: "admin1", handledAt: expect.any(Date) },
    });

    rFindUnique.mockResolvedValueOnce({ id: "r1", status: "DISMISSED" });
    const again = await request(app)
      .post("/api/admin/reports/r1/resolve")
      .set(adminAuth)
      .send({ status: "ACTIONED" });
    expect(again.status).toBe(409);
    expect(rUpdate).toHaveBeenCalledTimes(1);
  });

  it("rejects a resolve status other than ACTIONED or DISMISSED", async () => {
    const res = await request(app)
      .post("/api/admin/reports/r1/resolve")
      .set(adminAuth)
      .send({ status: "OPEN" });
    expect(res.status).toBe(400);
  });
});
