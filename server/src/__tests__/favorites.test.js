import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const clubFindUnique = jest.fn();
const clubFindMany = jest.fn();
const clubCount = jest.fn();
const favUpsert = jest.fn();
const favDeleteMany = jest.fn();
const favFindMany = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    club: { findUnique: clubFindUnique, findMany: clubFindMany, count: clubCount },
    favorite: { upsert: favUpsert, deleteMany: favDeleteMany, findMany: favFindMany },
    checkIn: { groupBy: jest.fn().mockResolvedValue([]) },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const auth = { Authorization: `Bearer ${jwt.sign({ userId: "u1" }, "test-secret")}` };
const club = { id: "c1", name: "Club", qrSecret: "s", isApproved: true };

beforeEach(() => {
  jest.clearAllMocks();
  userFindUnique.mockResolvedValue({ id: "u1", email: "u@x.com", role: "USER" });
});

describe("PUT /api/clubs/:id/favorite", () => {
  it("upserts so repeating it is idempotent", async () => {
    clubFindUnique.mockResolvedValue(club);
    for (let i = 0; i < 2; i++) {
      const res = await request(app).put("/api/clubs/c1/favorite").set(auth);
      expect(res.status).toBe(200);
      expect(res.body).toEqual({ isFavorite: true });
    }
    expect(favUpsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId_clubId: { userId: "u1", clubId: "c1" } } }),
    );
  });

  it("404s an unapproved or missing club without saving", async () => {
    clubFindUnique.mockResolvedValueOnce({ ...club, isApproved: false });
    expect((await request(app).put("/api/clubs/c1/favorite").set(auth)).status).toBe(404);
    clubFindUnique.mockResolvedValueOnce(null);
    expect((await request(app).put("/api/clubs/c1/favorite").set(auth)).status).toBe(404);
    expect(favUpsert).not.toHaveBeenCalled();
  });
});

describe("DELETE /api/clubs/:id/favorite", () => {
  it("204s even when the club was not a favourite, scoped to the caller", async () => {
    favDeleteMany.mockResolvedValue({ count: 0 });
    const res = await request(app).delete("/api/clubs/c1/favorite").set(auth);
    expect(res.status).toBe(204);
    expect(favDeleteMany).toHaveBeenCalledWith({ where: { userId: "u1", clubId: "c1" } });
  });
});

describe("isFavorite", () => {
  it("is computed from only the caller's favourite rows and hides the join", async () => {
    clubFindMany.mockResolvedValue([
      { ...club, favorites: [{ id: "f1" }] },
      { ...club, id: "c2", favorites: [] },
    ]);
    clubCount.mockResolvedValue(2);
    const res = await request(app).get("/api/clubs").set(auth);
    expect(clubFindMany.mock.calls[0][0].include).toEqual({
      favorites: { where: { userId: "u1" }, select: { id: true } },
    });
    expect(res.body.clubs.map((c) => c.isFavorite)).toEqual([true, false]);
    expect(res.body.clubs[0]).not.toHaveProperty("favorites");
  });

  it("GET /favorites lists approved favourites marked as favourite", async () => {
    favFindMany.mockResolvedValue([{ id: "f1", club }]);
    const res = await request(app).get("/api/clubs/favorites").set(auth);
    expect(res.status).toBe(200);
    expect(favFindMany.mock.calls[0][0].where).toEqual({
      userId: "u1",
      club: { isApproved: true },
    });
    expect(res.body.clubs).toEqual([expect.objectContaining({ id: "c1", isFavorite: true })]);
    expect(res.body.clubs[0]).not.toHaveProperty("qrSecret");
  });
});
