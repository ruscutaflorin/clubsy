import { jest } from "@jest/globals";

const findUnique = jest.fn();
const create = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique, create } },
}));

const bcrypt = (await import("bcryptjs")).default;
const jwt = (await import("jsonwebtoken")).default;
const { signUp, signIn, getCurrentUser } = await import("../controllers/authController.js");

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
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
