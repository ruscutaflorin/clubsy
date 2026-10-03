import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const userUpdate = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique: userFindUnique, update: userUpdate } },
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
  userFindUnique.mockResolvedValue({ id: "u1", role: "USER" });
  userUpdate.mockImplementation(async ({ data }) => ({
    id: "u1",
    email: "a@b.c",
    role: "USER",
    name: data.name,
  }));
});

describe("PATCH /api/auth/me", () => {
  it("401 without a token", async () => {
    const res = await request(app).patch("/api/auth/me").send({ name: "Ana" });
    expect(res.status).toBe(401);
  });

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

  it("400 for a 51-character name", async () => {
    const res = await patch({ name: "a".repeat(51) });
    expect(res.status).toBe(400);
    expect(userUpdate).not.toHaveBeenCalled();
  });
});
