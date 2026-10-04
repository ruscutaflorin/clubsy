import { jest } from "@jest/globals";

const findUnique = jest.fn();
const findMany = jest.fn();
const count = jest.fn();
const update = jest.fn();
const groupBy = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { club: { findUnique, findMany, count, update }, checkIn: { groupBy } },
}));

const {
  getClubs,
  getClubById,
  getClubQr,
  rotateClubQr,
  approveClub,
  unapproveClub,
  updateClub,
} = await import(
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
  groupBy.mockResolvedValue([]);
});

describe("club vibe aggregate", () => {
  const row = (clubId, avg, n) => ({ clubId, _avg: { vibe: avg }, _count: { vibe: n } });

  it("is null below 5 ratings and {average, count} from 5, with nothing else", async () => {
    findUnique.mockResolvedValue(club);
    groupBy.mockResolvedValue([row("c1", 4, 4)]);
    let res = makeRes();
    await getClubById({ params: { id: "c1" } }, res);
    expect(res.json.mock.calls[0][0].vibe).toBeNull();

    groupBy.mockResolvedValue([row("c1", 4.3333, 5)]);
    res = makeRes();
    await getClubById({ params: { id: "c1" } }, res);
    expect(res.json.mock.calls[0][0].vibe).toEqual({ average: 4.3, count: 5 });
  });

  it("only counts rated check-ins from the last 90 days", async () => {
    findUnique.mockResolvedValue(club);
    await getClubById({ params: { id: "c1" } }, makeRes());
    const { where } = groupBy.mock.calls[0][0];
    const ageDays = (Date.now() - where.vibeAt.gte.getTime()) / 86400000;
    expect(ageDays).toBeCloseTo(90, 1);
    expect(where.vibe).toEqual({ not: null });
  });

  it("sort=vibe ranks by average with unrated clubs last, then paginates", async () => {
    findMany.mockResolvedValue([
      { id: "a", isApproved: true },
      { id: "b", isApproved: true },
      { id: "c", isApproved: true },
    ]);
    groupBy.mockResolvedValue([row("c", 4.8, 9), row("b", 3.1, 6)]);
    const res = makeRes();
    await getClubs({ query: { sort: "vibe", limit: "2" } }, res);
    const body = res.json.mock.calls[0][0];
    expect(body.clubs.map((c) => c.id)).toEqual(["c", "b"]);
    expect(body.total).toBe(3);
    expect(body.pages).toBe(2);
  });
});

// getClubs' qrSecret filtering is covered at the route in routes.test.js.
describe("getClubById never exposes the QR secret to non-admins", () => {
  it("getClubById omits qrSecret for a USER", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "USER" } }, res);
    expect(res.json).toHaveBeenCalledWith({ id: "c1", name: "Club", isApproved: true, vibe: null });
  });

  it("getClubById keeps qrSecret for an ADMIN", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await getClubById({ params: { id: "c1" }, user: { role: "ADMIN" } }, res);
    expect(res.json).toHaveBeenCalledWith({ ...club, vibe: null });
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
    expect(res.json).toHaveBeenCalledWith({ ...club, isApproved: false, vibe: null });
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
  }, 30000);

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
  }, 30000);

  it("404s for an unknown club and never rotates", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await rotateClubQr({ params: { id: "missing" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(update).not.toHaveBeenCalled();
  });
});

describe("admin club mutations", () => {
  const notFound = Object.assign(new Error("missing"), { code: "P2025" });

  beforeEach(() => jest.spyOn(console, "error").mockImplementation(() => {}));

  it.each([
    ["approveClub", approveClub],
    ["unapproveClub", unapproveClub],
    ["updateClub", updateClub],
  ])("%s maps P2025 to 404", async (_name, handler) => {
    update.mockRejectedValue(notFound);
    const res = makeRes();
    await handler({ params: { id: "nope" }, body: { name: "X" } }, res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({ message: "Club not found" });
  });

  it("approveClub still 500s on other errors", async () => {
    update.mockRejectedValue(new Error("db down"));
    const res = makeRes();
    await approveClub({ params: { id: "c1" } }, res);
    expect(res.status).toHaveBeenCalledWith(500);
  });
});
