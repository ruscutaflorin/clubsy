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

const club = { id: "c1", name: "Club", qrSecret: "s3cret", isApproved: true };

describe("club read endpoints never expose the QR secret to non-admins", () => {
  it("getClubById omits qrSecret for a USER", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "USER" } }, res);
    expect(res.json).toHaveBeenCalledWith({ id: "c1", name: "Club", isApproved: true });
  });

  it("getClubById keeps qrSecret for an ADMIN", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "ADMIN" } }, res);
    expect(res.json).toHaveBeenCalledWith(club);
  });

  it("getClubById 404s a non-admin asking for an unapproved club", async () => {
    findUnique.mockResolvedValue({ ...club, isApproved: false });
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "USER" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({ message: "Club not found" });
  });

  it("getClubById lets an ADMIN see an unapproved club", async () => {
    findUnique.mockResolvedValue({ ...club, isApproved: false });
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "ADMIN" } }, res);
    expect(res.status).not.toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({ ...club, isApproved: false });
  });

  it("getClubs omits qrSecret from every club for a USER", async () => {
    findMany.mockResolvedValue([club]);
    count.mockResolvedValue(1);
    const res = makeRes();
    await getClubs({ query: {}, user: { role: "USER" } }, res);
    expect(res.json).toHaveBeenCalledWith({
      clubs: [{ id: "c1", name: "Club", isApproved: true }],
      total: 1,
      pages: 1,
    });
  });

  it("getClubs keeps qrSecret for an ADMIN", async () => {
    findMany.mockResolvedValue([club]);
    count.mockResolvedValue(1);
    const res = makeRes();
    await getClubs({ query: {}, user: { role: "ADMIN" } }, res);
    expect(res.json).toHaveBeenCalledWith({ clubs: [club], total: 1, pages: 1 });
  });
});
