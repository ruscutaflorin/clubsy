import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const clubFindUnique = jest.fn();
const checkInFindFirst = jest.fn();
const checkInFindMany = jest.fn();
const checkInCreate = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    club: { findUnique: clubFindUnique },
    checkIn: {
      findFirst: checkInFindFirst,
      findMany: checkInFindMany,
      create: checkInCreate,
    },
  },
}));

const { default: app } = await import("../app.js");

process.env.JWT_SECRET = "test-secret";
const token = jwt.sign({ userId: "u1" }, "test-secret");

const club = {
  id: "c1",
  qrSecret: "s3cret",
  latitude: 45,
  longitude: 25,
  isApproved: true,
};

const validBody = {
  clubId: "c1",
  qrPayload: JSON.stringify({ clubId: "c1", secret: "s3cret" }),
  latitude: 45,
  longitude: 25,
};

beforeEach(() => {
  jest.clearAllMocks();
  userFindUnique.mockResolvedValue({ id: "u1", email: "a@b.com", role: "USER" });
  checkInFindFirst.mockResolvedValue(null);
  jest.spyOn(console, "log").mockImplementation(() => {});
  jest.spyOn(console, "error").mockImplementation(() => {});
  jest.spyOn(console, "warn").mockImplementation(() => {});
});

afterEach(() => jest.restoreAllMocks());

describe("POST /api/check-ins", () => {
  it("returns 401 without an auth header", async () => {
    const res = await request(app).post("/api/check-ins").send(validBody);
    expect(res.status).toBe(401);
  });

  it("returns 400 for an invalid QR payload", async () => {
    clubFindUnique.mockResolvedValue(club);
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send({ ...validBody, qrPayload: JSON.stringify({ clubId: "c1", secret: "wrong" }) });
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/Invalid QR/);
  });

  it("returns 400 with distanceMeters when too far from the club", async () => {
    clubFindUnique.mockResolvedValue(club);
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send({ ...validBody, latitude: 46 });
    expect(res.status).toBe(400);
    expect(res.body.distanceMeters).toBeGreaterThan(150);
  });

  it("returns 404 for an unapproved club", async () => {
    clubFindUnique.mockResolvedValue({ ...club, isApproved: false });
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send(validBody);
    expect(res.status).toBe(404);
  });

  it("returns 201 for a valid QR within 150m", async () => {
    clubFindUnique.mockResolvedValue(club);
    checkInCreate.mockResolvedValue({ id: "ci1", clubId: "c1", userId: "u1" });
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send(validBody);
    expect(res.status).toBe(201);
    expect(checkInCreate).toHaveBeenCalledTimes(1);
  });

  it("returns 400 for isMocked true without touching the club", async () => {
    jest.spyOn(console, "warn").mockImplementation(() => {});
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send({ ...validBody, isMocked: true, accuracyMeters: 5 });
    expect(res.status).toBe(400);
    expect(res.body.message).toMatch(/Mock locations/);
    expect(clubFindUnique).not.toHaveBeenCalled();
  });

  it("returns 400 for a missing required field", async () => {
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send({ ...validBody, clubId: undefined });
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
  });
});

describe("GET /api/check-ins/me", () => {
  it("returns 401 without an auth header", async () => {
    const res = await request(app).get("/api/check-ins/me");
    expect(res.status).toBe(401);
  });

  it("returns the caller's check-ins for a valid token", async () => {
    checkInFindMany.mockResolvedValue([{ id: "ci1", clubId: "c1" }]);
    const res = await request(app)
      .get("/api/check-ins/me")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.checkIns).toHaveLength(1);
    expect(checkInFindMany.mock.calls[0][0].where).toEqual({ userId: "u1" });
  });
});

describe("importing app.js", () => {
  it("does not open a port - app is a request handler, not a listening server", () => {
    expect(typeof app).toBe("function");
    expect(typeof app.listen).toBe("function");
    expect(app.address).toBeUndefined();
  });
});
