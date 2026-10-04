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

// Verification branches (QR, distance, mock location, approval) are owned by checkInController.test.js;
// these cases cover the route's validation chain end to end.
describe("POST /api/check-ins", () => {
  it("returns 201 for a valid QR within 150m, accepting isMocked false and an accuracy", async () => {
    clubFindUnique.mockResolvedValue(club);
    checkInCreate.mockResolvedValue({ id: "ci1", clubId: "c1", userId: "u1" });
    const res = await request(app)
      .post("/api/check-ins")
      .set("Authorization", `Bearer ${token}`)
      .send({ ...validBody, isMocked: false, accuracyMeters: 8.5 });
    expect(res.status).toBe(201);
    expect(checkInCreate).toHaveBeenCalledTimes(1);
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
