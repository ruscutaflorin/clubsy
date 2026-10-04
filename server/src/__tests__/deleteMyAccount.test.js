import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import request from "supertest";

const userFindUnique = jest.fn();
const userCount = jest.fn();
const userDelete = jest.fn((a) => ({ op: "user.delete", a }));
const checkInDeleteMany = jest.fn((a) => ({ op: "checkIn.deleteMany", a }));
const favoriteDeleteMany = jest.fn((a) => ({ op: "favorite.deleteMany", a }));
const transaction = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique, count: userCount, delete: userDelete },
    checkIn: { deleteMany: checkInDeleteMany },
    favorite: { deleteMany: favoriteDeleteMany },
    $transaction: transaction,
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const token = jwt.sign({ userId: "u1" }, "test-secret");
const hash = bcrypt.hashSync("secret-pass", 4);
const del = (body) =>
  request(app).delete("/api/auth/me").set("Authorization", `Bearer ${token}`).send(body);

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  userFindUnique.mockReset();
  userCount.mockReset();
  transaction.mockReset();
  transaction.mockResolvedValue([]);
  userFindUnique.mockResolvedValue({ id: "u1", role: "USER", password: hash });
});

describe("DELETE /api/auth/me", () => {
  it("401 on wrong password and never deletes", async () => {
    const res = await del({ password: "nope" });
    expect(res.status).toBe(401);
    expect(transaction).not.toHaveBeenCalled();
  });

  it("400 without a password", async () => {
    const res = await del({});
    expect(res.status).toBe(400);
    expect(transaction).not.toHaveBeenCalled();
  });

  it("204 and deletes check-ins before the user", async () => {
    const res = await del({ password: "secret-pass" });
    expect(res.status).toBe(204);
    const ops = transaction.mock.calls[0][0].map((o) => o.op);
    expect(ops).toEqual(["checkIn.deleteMany", "favorite.deleteMany", "user.delete"]);
    expect(checkInDeleteMany).toHaveBeenCalledWith({ where: { userId: "u1" } });
    expect(userDelete).toHaveBeenCalledWith({ where: { id: "u1" } });
  });

  it("409 for the last admin", async () => {
    userFindUnique.mockResolvedValue({ id: "u1", role: "ADMIN", password: hash });
    userCount.mockResolvedValue(1);
    const res = await del({ password: "secret-pass" });
    expect(res.status).toBe(409);
    expect(res.body.message).toBeDefined();
    expect(transaction).not.toHaveBeenCalled();
  });

  it("204 for an admin when another admin exists", async () => {
    userFindUnique.mockResolvedValue({ id: "u1", role: "ADMIN", password: hash });
    userCount.mockResolvedValue(2);
    const res = await del({ password: "secret-pass" });
    expect(res.status).toBe(204);
  });
});
