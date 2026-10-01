import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";

const findUnique = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { user: { findUnique } },
}));

const { authMiddleware, adminMiddleware } = await import("../middlewares/authMiddleware.js");

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

describe("authMiddleware", () => {
  beforeEach(() => {
    process.env.JWT_SECRET = "test-secret";
    findUnique.mockReset();
    jest.spyOn(console, "log").mockImplementation(() => {});
    jest.spyOn(console, "error").mockImplementation(() => {});
  });
  afterEach(() => jest.restoreAllMocks());

  it("rejects a missing header with 401", async () => {
    const res = makeRes();
    const next = jest.fn();
    await authMiddleware({ headers: {} }, res, next);
    expect(res.status).toHaveBeenCalledWith(401);
    expect(next).not.toHaveBeenCalled();
  });

  it("rejects a header without a token with 401", async () => {
    const res = makeRes();
    await authMiddleware({ headers: { authorization: "Bearer" } }, res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: "No token provided" });
  });

  it("rejects when the user no longer exists", async () => {
    findUnique.mockResolvedValue(null);
    const token = jwt.sign({ userId: "u1" }, "test-secret");
    const res = makeRes();
    await authMiddleware({ headers: { authorization: `Bearer ${token}` } }, res, jest.fn());
    expect(res.status).toHaveBeenCalledWith(401);
    expect(res.json).toHaveBeenCalledWith({ message: "User not found" });
  });

  it("sets req.user and calls next for a valid token", async () => {
    findUnique.mockResolvedValue({ id: "u1", email: "a@b.c", role: "USER" });
    const token = jwt.sign({ userId: "u1" }, "test-secret");
    const req = { headers: { authorization: `Bearer ${token}` } };
    const next = jest.fn();
    await authMiddleware(req, makeRes(), next);
    expect(req.user).toEqual({ id: "u1", email: "a@b.c", role: "USER" });
    expect(next).toHaveBeenCalled();
  });
});

describe("adminMiddleware", () => {
  it("forbids non-admins", () => {
    const res = makeRes();
    const next = jest.fn();
    adminMiddleware({ user: { role: "USER" } }, res, next);
    expect(res.status).toHaveBeenCalledWith(403);
    expect(next).not.toHaveBeenCalled();
  });

  it("allows admins", () => {
    const next = jest.fn();
    adminMiddleware({ user: { role: "ADMIN" } }, makeRes(), next);
    expect(next).toHaveBeenCalled();
  });
});
