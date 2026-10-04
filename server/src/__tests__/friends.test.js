import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const userFindFirst = jest.fn();
const fFindFirst = jest.fn();
const fFindUnique = jest.fn();
const fFindMany = jest.fn();
const fCreate = jest.fn();
const fUpdate = jest.fn();
const fDelete = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, findFirst: userFindFirst },
    friendship: {
      findFirst: fFindFirst,
      findUnique: fFindUnique,
      findMany: fFindMany,
      create: fCreate,
      update: fUpdate,
      delete: fDelete,
    },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const tokenFor = (id) => ({ Authorization: `Bearer ${jwt.sign({ userId: id }, "test-secret")}` });
const auth = tokenFor("u1");

beforeEach(() => {
  jest.resetAllMocks();
  userFindUnique.mockImplementation(async ({ where }) => ({
    id: where.id,
    email: "u@x.com",
    role: "USER",
  }));
});

const send = (username, headers = auth) =>
  request(app).post("/api/friends/requests").set(headers).send({ username });

describe("POST /api/friends/requests", () => {
  it("creates a pending request for a known username", async () => {
    userFindFirst.mockResolvedValue({ id: "u2" });
    fFindFirst.mockResolvedValue(null);
    const res = await send("Bob_99");
    expect(res.status).toBe(202);
    expect(userFindFirst).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ username: "bob_99" }) }),
    );
    expect(fCreate).toHaveBeenCalledWith({ data: { requesterId: "u1", addresseeId: "u2" } });
  });

  it("answers an unknown username exactly like a known one", async () => {
    userFindFirst.mockResolvedValueOnce({ id: "u2" });
    fFindFirst.mockResolvedValue(null);
    const known = await send("bobby");
    userFindFirst.mockResolvedValueOnce(null);
    const unknown = await send("nobody");
    expect(unknown.status).toBe(known.status);
    expect(unknown.body).toEqual(known.body);
    expect(fCreate).toHaveBeenCalledTimes(1);
  });

  it("rejects requesting yourself with 400", async () => {
    userFindFirst.mockResolvedValue({ id: "u1" });
    const res = await send("me_myself");
    expect(res.status).toBe(400);
    expect(fCreate).not.toHaveBeenCalled();
  });

  it("rejects partial or email-shaped input with 400 and never looks anyone up", async () => {
    expect((await send("bo")).status).toBe(400);
    expect((await send("bob@x.com")).status).toBe(400);
    expect(userFindFirst).not.toHaveBeenCalled();
  });

  it("is a no-op for a duplicate pending request or an existing friendship", async () => {
    userFindFirst.mockResolvedValue({ id: "u2" });
    fFindFirst.mockResolvedValueOnce({
      id: "f1",
      requesterId: "u1",
      addresseeId: "u2",
      status: "PENDING",
    });
    expect((await send("bobby")).status).toBe(202);
    fFindFirst.mockResolvedValueOnce({
      id: "f1",
      requesterId: "u2",
      addresseeId: "u1",
      status: "ACCEPTED",
    });
    expect((await send("bobby")).status).toBe(202);
    expect(fCreate).not.toHaveBeenCalled();
    expect(fUpdate).not.toHaveBeenCalled();
  });

  it("auto-accepts when the other user already requested me", async () => {
    userFindFirst.mockResolvedValue({ id: "u2" });
    fFindFirst.mockResolvedValue({
      id: "f1",
      requesterId: "u2",
      addresseeId: "u1",
      status: "PENDING",
    });
    const res = await send("bobby");
    expect(res.status).toBe(202);
    expect(fCreate).not.toHaveBeenCalled();
    expect(fUpdate).toHaveBeenCalledWith({
      where: { id: "f1" },
      data: { status: "ACCEPTED", respondedAt: expect.any(Date) },
    });
  });

  it("rate-limits to 20 requests per day per user", async () => {
    userFindFirst.mockResolvedValue(null);
    const headers = tokenFor("spammer");
    for (let i = 0; i < 20; i++) {
      expect((await send("bobby", headers)).status).toBe(202);
    }
    expect((await send("bobby", headers)).status).toBe(429);
  });
});

describe("GET /api/friends", () => {
  it("splits rows into friends, incoming and outgoing from my point of view", async () => {
    const u = (id) => ({ id, username: id, name: id });
    fFindMany.mockResolvedValue([
      { id: "a", requesterId: "u1", addresseeId: "u2", status: "ACCEPTED", requester: u("u1"), addressee: u("u2") },
      { id: "b", requesterId: "u3", addresseeId: "u1", status: "ACCEPTED", requester: u("u3"), addressee: u("u1") },
      { id: "c", requesterId: "u4", addresseeId: "u1", status: "PENDING", requester: u("u4"), addressee: u("u1") },
      { id: "d", requesterId: "u1", addresseeId: "u5", status: "PENDING", requester: u("u1"), addressee: u("u5") },
    ]);
    const res = await request(app).get("/api/friends").set(auth);
    expect(res.status).toBe(200);
    expect(res.body.friends.map((f) => f.user.id)).toEqual(["u2", "u3"]);
    expect(res.body.incoming.map((f) => [f.id, f.user.id])).toEqual([["c", "u4"]]);
    expect(res.body.outgoing.map((f) => [f.id, f.user.id])).toEqual([["d", "u5"]]);
  });
});

describe("accept / decline / cancel / unfriend", () => {
  const row = (over) => ({
    id: "f1",
    requesterId: "u2",
    addresseeId: "u1",
    status: "PENDING",
    ...over,
  });

  it("accept: only the addressee of a pending request", async () => {
    fFindUnique.mockResolvedValueOnce(row());
    expect((await request(app).post("/api/friends/requests/f1/accept").set(auth)).status).toBe(200);
    expect(fUpdate).toHaveBeenCalledWith({
      where: { id: "f1" },
      data: { status: "ACCEPTED", respondedAt: expect.any(Date) },
    });

    for (const bad of [
      row({ requesterId: "u1", addresseeId: "u2" }),
      row({ status: "ACCEPTED" }),
      null,
    ]) {
      fFindUnique.mockResolvedValueOnce(bad);
      expect((await request(app).post("/api/friends/requests/f1/accept").set(auth)).status).toBe(404);
    }
    expect(fUpdate).toHaveBeenCalledTimes(1);
  });

  it("decline: deletes a pending request addressed to me, not one I sent", async () => {
    fFindUnique.mockResolvedValueOnce(row());
    expect((await request(app).post("/api/friends/requests/f1/decline").set(auth)).status).toBe(200);
    expect(fDelete).toHaveBeenCalledWith({ where: { id: "f1" } });

    fFindUnique.mockResolvedValueOnce(row({ requesterId: "u1", addresseeId: "u2" }));
    expect((await request(app).post("/api/friends/requests/f1/decline").set(auth)).status).toBe(404);
    expect(fDelete).toHaveBeenCalledTimes(1);
  });

  it("cancel: deletes a pending request I sent, not one sent to me", async () => {
    fFindUnique.mockResolvedValueOnce(row({ requesterId: "u1", addresseeId: "u2" }));
    expect((await request(app).delete("/api/friends/requests/f1").set(auth)).status).toBe(200);
    expect(fDelete).toHaveBeenCalledWith({ where: { id: "f1" } });

    fFindUnique.mockResolvedValueOnce(row());
    expect((await request(app).delete("/api/friends/requests/f1").set(auth)).status).toBe(404);
    expect(fDelete).toHaveBeenCalledTimes(1);
  });

  it("unfriend: either side of an accepted friendship, never a stranger or a pending row", async () => {
    fFindUnique.mockResolvedValueOnce(row({ status: "ACCEPTED" }));
    expect((await request(app).delete("/api/friends/f1").set(auth)).status).toBe(200);
    fFindUnique.mockResolvedValueOnce(
      row({ status: "ACCEPTED", requesterId: "u1", addresseeId: "u2" }),
    );
    expect((await request(app).delete("/api/friends/f1").set(auth)).status).toBe(200);
    expect(fDelete).toHaveBeenCalledTimes(2);

    fFindUnique.mockResolvedValueOnce(row({ status: "ACCEPTED", requesterId: "u8", addresseeId: "u9" }));
    expect((await request(app).delete("/api/friends/f1").set(auth)).status).toBe(404);
    fFindUnique.mockResolvedValueOnce(row());
    expect((await request(app).delete("/api/friends/f1").set(auth)).status).toBe(404);
    expect(fDelete).toHaveBeenCalledTimes(2);
  });
});
