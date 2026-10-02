import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";
import request from "supertest";

const userFindUnique = jest.fn();
const userUpdate = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique: userFindUnique, update: userUpdate } },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const token = jwt.sign({ userId: "u1" }, "test-secret");
const hash = bcrypt.hashSync("secret-pass", 4);
const change = (body) =>
  request(app).post("/api/auth/me/password").set("Authorization", `Bearer ${token}`).send(body);

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  userFindUnique.mockReset();
  userUpdate.mockReset();
  userUpdate.mockResolvedValue({});
  userFindUnique.mockResolvedValue({ id: "u1", role: "USER", password: hash });
});

describe("POST /api/auth/me/password", () => {
  it("401 without a token", async () => {
    const res = await request(app)
      .post("/api/auth/me/password")
      .send({ currentPassword: "secret-pass", newPassword: "brand-new-pass" });
    expect(res.status).toBe(401);
  });

  it("401 on wrong current password and never updates", async () => {
    const res = await change({ currentPassword: "nope", newPassword: "brand-new-pass" });
    expect(res.status).toBe(401);
    expect(userUpdate).not.toHaveBeenCalled();
  });

  it("400 for a 7-character new password", async () => {
    const res = await change({ currentPassword: "secret-pass", newPassword: "1234567" });
    expect(res.status).toBe(400);
    expect(userUpdate).not.toHaveBeenCalled();
  });

  it("400 when the new password equals the current one", async () => {
    const res = await change({ currentPassword: "secret-pass", newPassword: "secret-pass" });
    expect(res.status).toBe(400);
    expect(res.body.message).toBeDefined();
    expect(userUpdate).not.toHaveBeenCalled();
  });

  it("200 and stores a bcrypt hash of the new password", async () => {
    const res = await change({ currentPassword: "secret-pass", newPassword: "brand-new-pass" });
    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Password changed");
    expect(res.body).not.toHaveProperty("password");
    const { where, data } = userUpdate.mock.calls[0][0];
    expect(where).toEqual({ id: "u1" });
    expect(await bcrypt.compare("brand-new-pass", data.password)).toBe(true);
  });
});
