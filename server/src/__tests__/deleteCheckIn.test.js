import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const findUnique = jest.fn();
const checkInDelete = jest.fn();
const userFindUnique = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    checkIn: { findUnique, delete: checkInDelete },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const token = jwt.sign({ userId: "u1" }, "test-secret");
const del = (id) =>
  request(app).delete(`/api/check-ins/${id}`).set("Authorization", `Bearer ${token}`);

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  findUnique.mockReset();
  checkInDelete.mockReset().mockResolvedValue({});
  userFindUnique.mockReset().mockResolvedValue({ id: "u1", role: "USER" });
});
afterEach(() => jest.restoreAllMocks());

describe("DELETE /api/check-ins/:id", () => {
  it("204 and deletes the owner's check-in", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u1" });
    const res = await del("c1");
    expect(res.status).toBe(204);
    expect(checkInDelete).toHaveBeenCalledWith({ where: { id: "c1" } });
  });

  it("404 for another user's check-in and no delete", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u2" });
    const res = await del("c1");
    expect(res.status).toBe(404);
    expect(checkInDelete).not.toHaveBeenCalled();
  });

  it("404 for an unknown id", async () => {
    findUnique.mockResolvedValue(null);
    const res = await del("nope");
    expect(res.status).toBe(404);
    expect(checkInDelete).not.toHaveBeenCalled();
  });
});
