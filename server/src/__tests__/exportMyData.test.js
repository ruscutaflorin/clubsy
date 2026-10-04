import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const checkInFindMany = jest.fn();
const favoriteFindMany = jest.fn();
const friendshipFindMany = jest.fn();
const blockFindMany = jest.fn();
const reportFindMany = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    checkIn: { findMany: checkInFindMany },
    favorite: { findMany: favoriteFindMany },
    friendship: { findMany: friendshipFindMany },
    block: { findMany: blockFindMany },
    report: { findMany: reportFindMany },
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
  for (const fn of [favoriteFindMany, friendshipFindMany, blockFindMany, reportFindMany]) {
    fn.mockReset().mockResolvedValue([]);
  }
});

describe("GET /api/auth/me/export", () => {
  it("returns the profile and both check-ins, selecting no secrets", async () => {
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
    // The rows above are mocked, so secrets are kept out by the explicit selects.
    const userQuery = userFindUnique.mock.calls.find(([q]) => q.select?.createdAt)[0];
    expect(userQuery.select).toEqual({
      id: true,
      email: true,
      name: true,
      role: true,
      createdAt: true,
      username: true,
      homeCity: true,
      acceptedTermsAt: true,
      termsVersion: true,
      ageConfirmedAt: true,
      shareNightsWithFriends: true,
    });
    const args = checkInFindMany.mock.calls[0][0];
    expect(args.where).toEqual({ userId: "u1" });
    expect(args.select.club.select.qrSecret).toBeUndefined();
  });

  it("includes notes, favourites, friendships, own blocks and own reports without leaking others", async () => {
    userFindUnique.mockResolvedValue({ id: "u1", email: "a@b.com", name: "A" });
    checkInFindMany.mockResolvedValue([
      { id: "k1", checkedInAt: new Date(), note: "great DJ", vibe: 4, club },
    ]);
    favoriteFindMany.mockResolvedValue([
      { createdAt: new Date(), club: { id: "c1", name: "Club", city: "Town" } },
    ]);
    friendshipFindMany.mockResolvedValue([
      {
        status: "ACCEPTED",
        createdAt: new Date(),
        respondedAt: new Date(),
        requesterId: "u2",
        requester: { username: "bob", name: "Bob" },
        addressee: { username: "me", name: "A" },
      },
    ]);
    blockFindMany.mockResolvedValue([
      { createdAt: new Date(), blocked: { username: "eve", name: "Eve" } },
    ]);
    reportFindMany.mockResolvedValue([
      { reason: "SPAM", details: "x", status: "OPEN", createdAt: new Date() },
    ]);
    const token = jwt.sign({ userId: "u1" }, "test-secret");
    const res = await request(app)
      .get("/api/auth/me/export")
      .set("Authorization", `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body.checkIns[0]).toMatchObject({ note: "great DJ", vibe: 4 });
    expect(res.body.favorites).toHaveLength(1);
    expect(res.body.friendships).toHaveLength(1);
    expect(res.body.friendships[0]).toMatchObject({
      direction: "received",
      other: { username: "bob", name: "Bob" },
    });
    expect(res.body.blocks).toHaveLength(1);
    expect(res.body.reportsFiled).toHaveLength(1);
    const body = JSON.stringify(res.body);
    for (const leaked of ["password", "tokenVersion", "reportedUserId", "u2"]) {
      expect(body).not.toContain(leaked);
    }
    expect(blockFindMany.mock.calls[0][0].where).toEqual({ blockerId: "u1" });
    expect(reportFindMany.mock.calls[0][0].where).toEqual({ reporterId: "u1" });
  });
});
