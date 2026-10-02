import { jest } from "@jest/globals";

const findUnique = jest.fn();
const findMany = jest.fn();
const count = jest.fn();
const update = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { club: { findUnique, findMany, count, update } },
}));

const { getClubs, getClubById, getClubQr, rotateClubQr } = await import(
  "../controllers/clubController.js"
);
const { verifyClubQrPayload } = await import("../services/venueQrService.js");

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const club = { id: "c1", name: "Club", qrSecret: "s3cret", isApproved: true };

beforeEach(() => {
  jest.clearAllMocks();
});

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

describe("getClubs pagination clamping", () => {
  beforeEach(() => {
    findMany.mockResolvedValue([]);
    count.mockResolvedValue(0);
  });

  it("falls back to a default limit of 20 when limit is non-numeric", async () => {
    const res = makeRes();
    await getClubs({ query: { limit: "abc" }, user: { role: "USER" } }, res);
    expect(findMany.mock.calls[0][0].take).toBe(20);
  });

  it("clamps an oversized limit to 50", async () => {
    const res = makeRes();
    await getClubs({ query: { limit: "1000" }, user: { role: "USER" } }, res);
    expect(findMany.mock.calls[0][0].take).toBe(50);
  });

  it("falls back to page 1 for a non-numeric or non-positive page", async () => {
    const res = makeRes();
    await getClubs({ query: { page: "0" }, user: { role: "USER" } }, res);
    expect(findMany.mock.calls[0][0].skip).toBe(0);
  });

  it("computes skip from a valid page and limit", async () => {
    const res = makeRes();
    await getClubs({ query: { page: "3", limit: "10" }, user: { role: "USER" } }, res);
    expect(findMany.mock.calls[0][0].skip).toBe(20);
    expect(findMany.mock.calls[0][0].take).toBe(10);
  });
});

describe("getClubQr", () => {
  it("returns a qrCode data URL for an admin", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await getClubQr({ params: { id: "c1" } }, res);
    const body = res.json.mock.calls[0][0];
    expect(body.qrCode).toMatch(/^data:image\/png;base64,/);
  });

  it("404s for an unknown club", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await getClubQr({ params: { id: "missing" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
  });
});

describe("rotateClubQr", () => {
  it("replaces the secret so the old payload is rejected and the new one accepted", async () => {
    findUnique.mockResolvedValue(club);
    update.mockImplementation(async ({ data }) => ({ ...club, ...data }));
    const res = makeRes();
    await rotateClubQr({ params: { id: "c1" } }, res);

    const newSecret = update.mock.calls[0][0].data.qrSecret;
    expect(newSecret).not.toBe(club.qrSecret);

    const oldPayload = JSON.stringify({ clubId: "c1", secret: club.qrSecret });
    const newPayload = JSON.stringify({ clubId: "c1", secret: newSecret });
    const rotatedClub = { ...club, qrSecret: newSecret };
    expect(verifyClubQrPayload(oldPayload, rotatedClub)).toBe(false);
    expect(verifyClubQrPayload(newPayload, rotatedClub)).toBe(true);

    const body = res.json.mock.calls[0][0];
    expect(body.qrCode).toMatch(/^data:image\/png;base64,/);
  });

  it("404s for an unknown club and never rotates", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await rotateClubQr({ params: { id: "missing" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(update).not.toHaveBeenCalled();
  });
});
