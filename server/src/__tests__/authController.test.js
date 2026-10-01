import { jest } from "@jest/globals";

const findUnique = jest.fn();
const create = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique, create } },
}));

const bcrypt = (await import("bcryptjs")).default;
const jwt = (await import("jsonwebtoken")).default;
const { signUp, signIn, getCurrentUser } = await import("../controllers/authController.js");
const { signUpValidation, signInValidation } = await import("../routes/authRoutes.js");

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

// Runs the route's real express-validator chain against a bare req, the way Express
// would before the controller sees it, so validation is exercised end to end.
const validated = async (validators, body) => {
  const req = { body };
  for (const validator of validators) {
    await validator.run(req);
  }
  return req;
};

beforeEach(() => {
  jest.clearAllMocks();
  process.env.JWT_SECRET = "test-secret";
  jest.spyOn(console, "error").mockImplementation(() => {});
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

  it("rejects a bad email with 400 {errors} and creates no user", async () => {
    const req = await validated(signUpValidation, {
      email: "not-an-email",
      password: "password1",
      name: "A",
    });
    const res = makeRes();
    await signUp(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json.mock.calls[0][0].errors).toBeDefined();
    expect(findUnique).not.toHaveBeenCalled();
    expect(create).not.toHaveBeenCalled();
  });

  it("rejects a short password with 400 {errors} and creates no user", async () => {
    const req = await validated(signUpValidation, {
      email: "a@b.c",
      password: "short",
      name: "A",
    });
    const res = makeRes();
    await signUp(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(create).not.toHaveBeenCalled();
  });

  it("rejects a missing name with 400 {errors} and creates no user", async () => {
    const req = await validated(signUpValidation, {
      email: "a@b.c",
      password: "password1",
      name: "",
    });
    const res = makeRes();
    await signUp(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(create).not.toHaveBeenCalled();
  });

  it("accepts valid input and returns 201 with a token", async () => {
    findUnique.mockResolvedValue(null);
    create.mockImplementation(async ({ data }) => ({ id: "u1", ...data }));
    const req = await validated(signUpValidation, {
      email: "a@b.com",
      password: "password1",
      name: "A",
    });
    const res = makeRes();
    await signUp(req, res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(res.json.mock.calls[0][0].token).toBeDefined();
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

  it("rejects a missing password with 400 {errors}", async () => {
    const req = await validated(signInValidation, { email: "a@b.c", password: "" });
    const res = makeRes();
    await signIn(req, res);
    expect(res.status).toHaveBeenCalledWith(400);
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

describe("getCurrentUser", () => {
  it("returns 404 when the user no longer exists", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await getCurrentUser({ user: { id: "u1" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });
});
