import { jest } from "@jest/globals";
import request from "supertest";

const findUnique = jest.fn();
const create = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique, create } },
}));

const bcrypt = (await import("bcryptjs")).default;
const jwt = (await import("jsonwebtoken")).default;
const { signUp, signIn, getCurrentUser } = await import("../controllers/authController.js");
const { default: app } = await import("../app.js");

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

// Validation goes through the real routes; the sign-in/up limiter allows 10 requests per
// minute per IP in this file, and these tests send 6.
const signUpRequest = (body) => request(app).post("/api/auth/signup").send(body);
const signInRequest = (body) => request(app).post("/api/auth/signin").send(body);

beforeEach(() => {
  jest.clearAllMocks();
  process.env.JWT_SECRET = "test-secret";
  jest.spyOn(console, "error").mockImplementation(() => {});
  jest.spyOn(console, "log").mockImplementation(() => {});
});

describe("signUp", () => {
  it("rejects an existing email with 400", async () => {
    findUnique.mockResolvedValue({ id: "u1" });
    const res = makeRes();
    await signUp({ body: { email: "a@b.c", password: "pw", name: "A" } }, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(create).not.toHaveBeenCalled();
  });

  it("returns 500 and creates no user when JWT_SECRET is unset", async () => {
    delete process.env.JWT_SECRET;
    const res = makeRes();
    await signUp({ body: { email: "a@b.c", password: "password1", name: "A" } }, res);
    expect(res.status).toHaveBeenCalledWith(500);
    expect(create).not.toHaveBeenCalled();
  });

  it.each([
    ["a bad email", { email: "not-an-email", password: "password1", name: "A" }],
    ["a short password", { email: "a@b.c", password: "short", name: "A" }],
    ["a missing name", { email: "a@b.c", password: "password1", name: "" }],
  ])("POST /signup rejects %s with 400 {errors} and creates no user", async (_label, body) => {
    const res = await signUpRequest(body);
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
    expect(findUnique).not.toHaveBeenCalled();
    expect(create).not.toHaveBeenCalled();
  });

  it("POST /signup accepts valid input and returns 201 with a token", async () => {
    findUnique.mockResolvedValue(null);
    create.mockImplementation(async ({ data }) => ({ id: "u1", ...data }));
    const res = await signUpRequest({ email: "a@b.com", password: "password1", name: "A" });
    expect(res.status).toBe(201);
    expect(typeof res.body.token).toBe("string");
  });

  it("stores a hashed password and never returns it", async () => {
    findUnique.mockResolvedValue(null);
    create.mockImplementation(async ({ data }) => ({ id: "u1", ...data }));
    const res = makeRes();
    await signUp({ body: { email: "a@b.c", password: "pw", name: "A" } }, res);
    const stored = create.mock.calls[0][0].data;
    expect(stored.password).not.toBe("pw");
    expect(await bcrypt.compare("pw", stored.password)).toBe(true);
    expect(stored.role).toBe("USER");
    const body = res.json.mock.calls[0][0];
    expect(res.status).toHaveBeenCalledWith(201);
    expect(body.user).toEqual({ id: "u1", email: "a@b.c", name: "A", role: "USER" });
    expect(jwt.verify(body.token, "test-secret").userId).toBe("u1");
  });
});

describe("signIn", () => {
  it("returns 401 for an unknown user", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await signIn({ body: { email: "a@b.c", password: "pw" } }, res);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  it("POST /signin rejects a missing password with 400 {errors}", async () => {
    const res = await signInRequest({ email: "a@b.c", password: "" });
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
    expect(findUnique).not.toHaveBeenCalled();
  });

  it("returns 500 and no token when JWT_SECRET is unset", async () => {
    delete process.env.JWT_SECRET;
    findUnique.mockResolvedValue({ id: "u1", password: await bcrypt.hash("pw", 4) });
    const res = makeRes();
    await signIn({ body: { email: "a@b.c", password: "pw" } }, res);
    expect(res.status).toHaveBeenCalledWith(500);
    const body = res.json.mock.calls[0][0];
    expect(body.token).toBeUndefined();
  });

  it("returns 401 for a wrong password", async () => {
    findUnique.mockResolvedValue({ id: "u1", password: await bcrypt.hash("right", 4) });
    const res = makeRes();
    await signIn({ body: { email: "a@b.c", password: "wrong" } }, res);
    expect(res.status).toHaveBeenCalledWith(401);
  });

  it("returns a token and no password on success", async () => {
    findUnique.mockResolvedValue({
      id: "u1",
      email: "a@b.c",
      name: "A",
      role: "USER",
      password: await bcrypt.hash("pw", 4),
    });
    const res = makeRes();
    await signIn({ body: { email: "a@b.c", password: "pw" } }, res);
    const body = res.json.mock.calls[0][0];
    expect(body.user).toEqual({ id: "u1", email: "a@b.c", name: "A", role: "USER" });
    expect(jwt.verify(body.token, "test-secret").userId).toBe("u1");
  });
});

describe("signIn email normalization", () => {
  it("POST /signin looks the user up by the lowercased email", async () => {
    findUnique.mockResolvedValue(null);
    await signInRequest({ email: "ANA@X.COM", password: "pw" });
    expect(findUnique).toHaveBeenCalledWith({ where: { email: "ana@x.com" } });
  });
});

describe("getCurrentUser", () => {
  it("returns the user without a password", async () => {
    const user = { id: "u1", email: "a@b.c", name: "A", role: "USER", createdAt: new Date() };
    findUnique.mockResolvedValue(user);
    const res = makeRes();
    await getCurrentUser({ user: { id: "u1" } }, res);
    expect(res.json).toHaveBeenCalledWith(user);
    const select = findUnique.mock.calls[0][0].select;
    expect(select.password).toBeUndefined();
    expect(select.createdAt).toBe(true);
  });

  it("returns 404 when the user no longer exists", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await getCurrentUser({ user: { id: "u1" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });
});
