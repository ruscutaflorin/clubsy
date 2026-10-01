import { jest } from "@jest/globals";

const findUnique = jest.fn();
const findMany = jest.fn();
const count = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { club: { findUnique, findMany, count } },
}));

const { getClubs, getClubById } = await import("../controllers/clubController.js");

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const club = { id: "c1", name: "Club", qrSecret: "s3cret" };

describe("club read endpoints never expose the QR secret", () => {
  it("getClubById omits qrSecret", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "USER" } }, res);
    expect(res.json).toHaveBeenCalledWith({ id: "c1", name: "Club" });
  });

  it("getClubs omits qrSecret from every club", async () => {
    findMany.mockResolvedValue([club]);
    count.mockResolvedValue(1);
    const res = makeRes();
    await getClubs({ query: {}, user: { role: "USER" } }, res);
    expect(res.json).toHaveBeenCalledWith({
      clubs: [{ id: "c1", name: "Club" }],
      total: 1,
      pages: 1,
    });
  });
});
