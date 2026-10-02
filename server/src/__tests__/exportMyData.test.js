import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const checkInFindMany = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    checkIn: { findMany: checkInFindMany },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const club = {
  id: "c1",
  name: "Club",
  address: "1 St",
  city: "Town",
  latitude: 1,
  longitude: 2,
};

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  jest.spyOn(console, "log").mockImplementation(() => {});
  userFindUnique.mockReset();
  checkInFindMany.mockReset();
});

describe("GET /api/auth/me/export", () => {
  it("returns the profile and both check-ins without secrets", async () => {
    userFindUnique.mockResolvedValue({
      id: "u1",
      email: "a@b.com",
      name: "A",
      role: "USER",
      createdAt: new Date().toISOString(),
    });
    checkInFindMany.mockResolvedValue([
      { id: "k1", checkedInAt: new Date(), distanceMeters: 10, verificationMethod: "QR_GPS", club },
      { id: "k2", checkedInAt: new Date(), distanceMeters: 20, verificationMethod: "QR_GPS", club },
    ]);
    const token = jwt.sign({ userId: "u1" }, "test-secret");
    const res = await request(app)
      .get("/api/auth/me/export")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.headers["content-disposition"]).toMatch(
      /^attachment; filename="clubsy-export-\d{4}-\d{2}-\d{2}\.json"$/
    );
    expect(res.body.checkIns).toHaveLength(2);
    expect(res.body.user.email).toBe("a@b.com");
    expect(res.body.exportedAt).toBeDefined();
    expect(res.text).not.toContain("password");
    expect(res.text).not.toContain("qrSecret");
    const args = checkInFindMany.mock.calls[0][0];
    expect(args.where).toEqual({ userId: "u1" });
    expect(args.select.club.select.qrSecret).toBeUndefined();
  });

  it("returns 401 without a token", async () => {
    const res = await request(app).get("/api/auth/me/export");
    expect(res.status).toBe(401);
  });
});
