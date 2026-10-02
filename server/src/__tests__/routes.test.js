import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import request from "supertest";

const userFindUnique = jest.fn();
const userCreate = jest.fn();
const clubFindUnique = jest.fn();
const clubFindMany = jest.fn();
const clubCount = jest.fn();
const clubUpdate = jest.fn();
const checkInFindMany = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, create: userCreate },
    club: {
      findUnique: clubFindUnique,
      findMany: clubFindMany,
      count: clubCount,
      update: clubUpdate,
    },
    checkIn: { findMany: checkInFindMany },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

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

describe("auth routes", () => {
  it("signup returns 400 {errors} for a bad email", async () => {
    const res = await request(app)
      .post("/api/auth/signup")
      .send({ email: "nope", password: "password1", name: "Ana" });
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
  });

  it("signup returns 201 with a token", async () => {
    userFindUnique.mockResolvedValue(null);
    userCreate.mockResolvedValue({ id: "u9", email: "ana@x.com", name: "Ana", role: "USER" });
    const res = await request(app)
      .post("/api/auth/signup")
      .send({ email: "ana@x.com", password: "password1", name: "Ana" });
    expect(res.status).toBe(201);
    expect(typeof res.body.token).toBe("string");
  });

  it("signin returns 401 for a wrong password", async () => {
    userFindUnique.mockResolvedValue({
      id: "u1",
      email: "ana@x.com",
      password: await bcrypt.hash("right-password", 4),
    });
    const res = await request(app)
      .post("/api/auth/signin")
      .send({ email: "ana@x.com", password: "wrong-password" });
    expect(res.status).toBe(401);
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

  it("GET /api/clubs/:id returns 404 for an unapproved club as USER", async () => {
    clubFindUnique.mockResolvedValue({ ...club, isApproved: false });
    const res = await request(app).get("/api/clubs/c1").set(auth(userToken));
    expect(res.status).toBe(404);
  });

  const p2025 = () => Object.assign(new Error("x"), { code: "P2025" });

  it.each(["approve", "unapprove"])(
    "PATCH /api/clubs/:id/%s returns 404 for an unknown id",
    async (action) => {
      clubUpdate.mockRejectedValue(p2025());
      const res = await request(app).patch(`/api/clubs/nope/${action}`).set(auth(adminToken));
      expect(res.status).toBe(404);
      expect(res.body).toEqual({ message: "Club not found" });
    },
  );

  it("PATCH /api/clubs/:id returns 404 for an unknown id", async () => {
    clubUpdate.mockRejectedValue(p2025());
    const res = await request(app)
      .patch("/api/clubs/nope")
      .set(auth(adminToken))
      .send({ name: "N" });
    expect(res.status).toBe(404);
  });

  it("PATCH /api/clubs/:id returns 403 for USER", async () => {
    const res = await request(app).patch("/api/clubs/c1").set(auth(userToken)).send({ name: "N" });
    expect(res.status).toBe(403);
    expect(clubUpdate).not.toHaveBeenCalled();
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

  it("PATCH /api/clubs/:id/approve returns 403 for USER", async () => {
    const res = await request(app).patch("/api/clubs/c1/approve").set(auth(userToken));
    expect(res.status).toBe(403);
    expect(clubUpdate).not.toHaveBeenCalled();
  });
});

describe("stats, health and fallbacks", () => {
  it("GET /api/check-ins/me/stats returns aggregated stats", async () => {
    checkInFindMany.mockResolvedValue([
      { clubId: "c1", checkedInAt: new Date(), club: { id: "c1", city: "X" } },
    ]);
    const res = await request(app).get("/api/check-ins/me/stats").set(auth(userToken));
    expect(res.status).toBe(200);
    expect(res.body.totalCheckIns).toBe(1);
    expect(res.body.uniqueCities).toBe(1);
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
