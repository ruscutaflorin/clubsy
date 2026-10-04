import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const userUpdate = jest.fn();
const userFindFirst = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, update: userUpdate, findFirst: userFindFirst },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const token = jwt.sign({ userId: "u1" }, "test-secret");
const patch = (body) =>
  request(app).patch("/api/auth/me").set("Authorization", `Bearer ${token}`).send(body);

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  userFindUnique.mockReset();
  userUpdate.mockReset();
  userFindFirst.mockReset();
  userFindUnique.mockResolvedValue({ id: "u1", role: "USER" });
  userUpdate.mockImplementation(async ({ data }) => ({
    id: "u1",
    email: "a@b.c",
    role: "USER",
    ...data,
  }));
});

describe("GET /api/auth/username-available", () => {
  const check = (u) =>
    request(app)
      .get("/api/auth/username-available")
      .query({ u })
      .set("Authorization", `Bearer ${token}`);

  it("reports availability, ignoring the caller's own row", async () => {
    userFindFirst.mockResolvedValueOnce({ id: "u2" }).mockResolvedValueOnce(null);
    expect((await check("Taken")).body).toEqual({ available: false });
    expect((await check("free_1")).body).toEqual({ available: true });
    expect(userFindFirst.mock.calls[0][0].where.NOT).toEqual({ id: "u1" });
  });

  it("400 for an invalid username", async () => {
    expect((await check("no spaces")).status).toBe(400);
    expect(userFindFirst).not.toHaveBeenCalled();
  });
});

describe("PATCH /api/auth/me", () => {
  it("200 and writes the trimmed name only", async () => {
    const res = await patch({ name: "  Ana  " });
    expect(res.status).toBe(200);
    expect(res.body.user.name).toBe("Ana");
    expect(userUpdate.mock.calls[0][0].data).toEqual({ name: "Ana" });
    expect(res.body).not.toHaveProperty("password");
    expect(res.body.user).not.toHaveProperty("password");
  });

  it("ignores role and email in the body", async () => {
    const res = await patch({ name: "Ana", role: "ADMIN", email: "x@y.z" });
    expect(res.status).toBe(200);
    expect(userUpdate.mock.calls[0][0].data).toEqual({ name: "Ana" });
  });

  it("400 for an empty name", async () => {
    const res = await patch({ name: "   " });
    expect(res.status).toBe(400);
    expect(userUpdate).not.toHaveBeenCalled();
  });

  it("writes a lowercased username and a homeCity, clearing an empty city", async () => {
    userFindFirst.mockResolvedValue(null);
    const res = await patch({ username: " Ana_01 ", homeCity: " Cluj " });
    expect(res.status).toBe(200);
    expect(userUpdate.mock.calls[0][0].data).toEqual({ username: "ana_01", homeCity: "Cluj" });
    await patch({ homeCity: "" });
    expect(userUpdate.mock.calls[1][0].data).toEqual({ homeCity: null });
  });

  it("409 when another user has the username (case-insensitive lookup)", async () => {
    userFindFirst.mockResolvedValue({ id: "u2" });
    const res = await patch({ username: "TAKEN_one" });
    expect(res.status).toBe(409);
    const where = userFindFirst.mock.calls[0][0].where;
    expect(where.username).toEqual({ equals: "taken_one", mode: "insensitive" });
    expect(where.NOT).toEqual({ id: "u1" });
    expect(userUpdate).not.toHaveBeenCalled();
  });

  it("409 when the unique index wins a race", async () => {
    userFindFirst.mockResolvedValue(null);
    userUpdate.mockRejectedValue({ code: "P2002" });
    const res = await patch({ username: "racer" });
    expect(res.status).toBe(409);
  });

  it.each(["ab", "a".repeat(21), "bad name", "ana-1", "añá"])(
    "400 for invalid username %j",
    async (username) => {
      const res = await patch({ username });
      expect(res.status).toBe(400);
      expect(userUpdate).not.toHaveBeenCalled();
    }
  );

  it("400 for a 51-character name", async () => {
    const res = await patch({ name: "a".repeat(51) });
    expect(res.status).toBe(400);
    expect(userUpdate).not.toHaveBeenCalled();
  });
});
