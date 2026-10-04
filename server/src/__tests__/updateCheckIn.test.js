import { jest } from "@jest/globals";
import jwt from "jsonwebtoken";
import request from "supertest";

const findUnique = jest.fn();
const checkInUpdate = jest.fn();
const userFindUnique = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: {
    user: { findUnique: userFindUnique },
    checkIn: { findUnique, update: checkInUpdate },
  },
}));

process.env.JWT_SECRET = "test-secret";
const { default: app } = await import("../app.js");

const token = jwt.sign({ userId: "u1" }, "test-secret");
const patch = (id, body) =>
  request(app).patch(`/api/check-ins/${id}`).set("Authorization", `Bearer ${token}`).send(body);

const recent = () => new Date(Date.now() - 60 * 60 * 1000);
const daysAgo = (n) => new Date(Date.now() - n * 24 * 60 * 60 * 1000);

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  findUnique.mockReset();
  checkInUpdate.mockReset().mockImplementation(async ({ data }) => ({ id: "c1", ...data }));
  userFindUnique.mockReset().mockResolvedValue({ id: "u1", role: "USER" });
});
afterEach(() => jest.restoreAllMocks());

describe("PATCH /api/check-ins/:id", () => {
  it("saves a trimmed note and a vibe stamped with vibeAt for the owner", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u1", checkedInAt: recent() });
    const res = await patch("c1", { note: "  great DJ  ", vibe: 4 });
    expect(res.status).toBe(200);
    const { data } = checkInUpdate.mock.calls[0][0];
    expect(data.note).toBe("great DJ");
    expect(data.vibe).toBe(4);
    expect(data.vibeAt).toBeInstanceOf(Date);
  });

  it("404 for another user's check-in and no update", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u2", checkedInAt: recent() });
    const res = await patch("c1", { vibe: 3 });
    expect(res.status).toBe(404);
    expect(checkInUpdate).not.toHaveBeenCalled();
  });

  it.each([[6], [0], [2.5]])("400 for vibe %s", async (vibe) => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u1", checkedInAt: recent() });
    const res = await patch("c1", { vibe });
    expect(res.status).toBe(400);
    expect(checkInUpdate).not.toHaveBeenCalled();
  });

  it("400 for a note over 280 characters", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u1", checkedInAt: recent() });
    const res = await patch("c1", { note: "x".repeat(281) });
    expect(res.status).toBe(400);
  });

  it("409 when rating more than 7 days after the check-in", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u1", checkedInAt: daysAgo(8) });
    const res = await patch("c1", { vibe: 5 });
    expect(res.status).toBe(409);
    expect(checkInUpdate).not.toHaveBeenCalled();
  });

  it("still lets the owner edit the note after the vibe window closes", async () => {
    findUnique.mockResolvedValue({ id: "c1", userId: "u1", checkedInAt: daysAgo(30) });
    const res = await patch("c1", { note: "with Ana" });
    expect(res.status).toBe(200);
    expect(checkInUpdate.mock.calls[0][0].data).toEqual({ note: "with Ana" });
  });
});
