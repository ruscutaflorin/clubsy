import { jest } from "@jest/globals";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import request from "supertest";

const userFindUnique = jest.fn();
const queryRaw = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique: userFindUnique }, $queryRaw: queryRaw },
}));

process.env.JWT_SECRET = "test-secret";
process.env.CORS_ORIGINS = "https://good.example";

const { default: app } = await import("../app.js");

beforeEach(() => {
  jest.spyOn(console, "log").mockImplementation(() => {});
  jest.spyOn(console, "error").mockImplementation(() => {});
});

afterEach(() => jest.restoreAllMocks());

// The sign-in limiter is shared across this file (10 per minute per IP):
// the token test uses 1 request and the rate-limit test uses the other 9 plus the rejected one.
describe("token lifetime", () => {
  it("signs tokens that last 30 days by default", async () => {
    userFindUnique.mockResolvedValueOnce({
      id: "u1",
      email: "a@b.com",
      role: "USER",
      name: "A",
      password: await bcrypt.hash("password1", 4),
    });
    const res = await request(app)
      .post("/api/auth/signin")
      .send({ email: "a@b.com", password: "password1" });
    expect(res.status).toBe(200);
    const { exp, iat } = jwt.decode(res.body.token);
    expect(exp - iat).toBe(30 * 24 * 60 * 60);
  });
});

describe("rate limiting", () => {
  it("returns 429 on the 11th sign-in within a minute", async () => {
    userFindUnique.mockResolvedValue(null);
    const send = () =>
      request(app).post("/api/auth/signin").send({ email: "a@b.com", password: "x" });
    for (let i = 0; i < 9; i++) {
      expect((await send()).status).toBe(401);
    }
    expect((await send()).status).toBe(429);
  });
});

describe("CORS", () => {
  it("omits Access-Control-Allow-Origin for a disallowed origin", async () => {
    const res = await request(app).get("/health").set("Origin", "https://evil.example");
    expect(res.headers["access-control-allow-origin"]).toBeUndefined();
  });

  it("allows a listed origin", async () => {
    const res = await request(app).get("/health").set("Origin", "https://good.example");
    expect(res.headers["access-control-allow-origin"]).toBe("https://good.example");
  });
});

describe("security headers", () => {
  it("sets helmet headers", async () => {
    const res = await request(app).get("/health");
    expect(res.headers["x-content-type-options"]).toBe("nosniff");
  });
});

describe("GET /health/ready", () => {
  it("returns 200 when the database answers", async () => {
    queryRaw.mockResolvedValue([{ "?column?": 1 }]);
    const res = await request(app).get("/health/ready");
    expect(res.status).toBe(200);
  });

  it("returns 503 when the query rejects", async () => {
    queryRaw.mockRejectedValue(new Error("down"));
    const res = await request(app).get("/health/ready");
    expect(res.status).toBe(503);
  });
});
