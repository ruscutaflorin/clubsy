import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

// A tiny stateful user so the version bump is observable through the real middleware.
const dbUser = { id: "u1", email: "a@b.c", role: "USER", tokenVersion: 0 };
const userFindUnique = jest.fn(async () => ({ ...dbUser }));
const userUpdate = jest.fn(async ({ data }) => {
  if (data.tokenVersion?.increment) dbUser.tokenVersion += data.tokenVersion.increment;
  return { ...dbUser };
});

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique: userFindUnique, update: userUpdate } },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const bearer = (tv) => `Bearer ${jwt.sign({ userId: "u1", tv }, "test-secret")}`;

beforeEach(() => {
  dbUser.tokenVersion = 0;
});

describe("POST /api/auth/signout-all", () => {
  it("invalidates older tokens; a token with the new version works", async () => {
    const old = bearer(0);
    expect((await request(app).get("/api/auth/me").set("Authorization", old)).status).toBe(200);

    const res = await request(app).post("/api/auth/signout-all").set("Authorization", old);
    expect(res.status).toBe(200);

    expect((await request(app).get("/api/auth/me").set("Authorization", old)).status).toBe(401);
    expect(
      (await request(app).get("/api/auth/me").set("Authorization", bearer(1))).status
    ).toBe(200);
  });
});
