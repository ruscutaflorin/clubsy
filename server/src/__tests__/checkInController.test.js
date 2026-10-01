import { jest } from "@jest/globals";

const findUnique = jest.fn();
const create = jest.fn();
const findMany = jest.fn();
const findFirst = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { club: { findUnique }, checkIn: { create, findMany, findFirst } },
}));

const { checkIn, getMyCheckIns, getMyCheckInStats } = await import(
  "../controllers/checkInController.js"
);

const makeRes = () => {
  const res = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  return res;
};

const club = { id: "c1", qrSecret: "s3cret", latitude: 45, longitude: 25, isApproved: true };
const makeReq = (body = {}) => ({
  user: { id: "u1" },
  body: {
    clubId: "c1",
    qrPayload: JSON.stringify({ clubId: "c1", secret: "s3cret" }),
    latitude: 45,
    longitude: 25,
    ...body,
  },
});

describe("checkIn", () => {
  beforeEach(() => {
    findUnique.mockReset();
    create.mockReset();
    findMany.mockReset();
    findFirst.mockReset().mockResolvedValue(null);
    jest.spyOn(console, "error").mockImplementation(() => {});
  });
  afterEach(() => jest.restoreAllMocks());

  it("returns 404 for an unknown club", async () => {
    findUnique.mockResolvedValue(null);
    const res = makeRes();
    await checkIn(makeReq(), res);
    expect(res.status).toHaveBeenCalledWith(404);
    expect(create).not.toHaveBeenCalled();
  });

  it("returns 404 for an unapproved club", async () => {
    findUnique.mockResolvedValue({ ...club, isApproved: false });
    const res = makeRes();
    await checkIn(makeReq(), res);
    expect(res.status).toHaveBeenCalledWith(404);
  });

  it("rejects a wrong QR secret", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await checkIn(makeReq({ qrPayload: JSON.stringify({ clubId: "c1", secret: "bad" }) }), res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({ message: "Invalid QR code for this club" });
    expect(create).not.toHaveBeenCalled();
  });

  it("rejects a check-in from too far away", async () => {
    findUnique.mockResolvedValue(club);
    const res = makeRes();
    await checkIn(makeReq({ latitude: 45.01 }), res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json.mock.calls[0][0].distanceMeters).toBeGreaterThan(150);
    expect(create).not.toHaveBeenCalled();
  });

  it("creates a check-in when QR and proximity both pass", async () => {
    findUnique.mockResolvedValue(club);
    create.mockResolvedValue({ id: "ci1" });
    const res = makeRes();
    await checkIn(makeReq(), res);
    expect(res.status).toHaveBeenCalledWith(201);
    expect(create.mock.calls[0][0].data).toMatchObject({
      userId: "u1",
      clubId: "c1",
      verificationMethod: "QR",
    });
  });

  it("rejects a second check-in at the same club the same night with 409", async () => {
    findUnique.mockResolvedValue(club);
    findFirst.mockResolvedValue({ id: "ci-earlier" });
    const res = makeRes();
    await checkIn(makeReq(), res);
    expect(res.status).toHaveBeenCalledWith(409);
    expect(create).not.toHaveBeenCalled();
  });

  it("allows a check-in at a different club the same night", async () => {
    const club2 = { ...club, id: "c2" };
    findUnique.mockResolvedValue(club2);
    findFirst.mockResolvedValue(null);
    create.mockResolvedValue({ id: "ci2" });
    const res = makeRes();
    await checkIn(
      makeReq({
        clubId: "c2",
        qrPayload: JSON.stringify({ clubId: "c2", secret: "s3cret" }),
      }),
      res
    );
    expect(res.status).toHaveBeenCalledWith(201);
  });

  it("returns 500 when the database fails", async () => {
    findUnique.mockRejectedValue(new Error("db"));
    const res = makeRes();
    await checkIn(makeReq(), res);
    expect(res.status).toHaveBeenCalledWith(500);
  });
});

describe("getMyCheckIns", () => {
  it("lists only the caller's check-ins", async () => {
    findMany.mockResolvedValue([]);
    const res = makeRes();
    await getMyCheckIns({ user: { id: "u1" } }, res);
    expect(findMany.mock.calls[0][0].where).toEqual({ userId: "u1" });
    expect(res.json).toHaveBeenCalledWith({ checkIns: [] });
  });
});

describe("getMyCheckInStats", () => {
  it("returns aggregated stats for the caller only", async () => {
    findMany.mockResolvedValue([
      { clubId: "c1", club: { id: "c1", name: "Club", city: "Cluj" }, checkedInAt: "2026-09-01T20:00:00Z" },
    ]);
    const res = makeRes();
    await getMyCheckInStats({ user: { id: "u1" } }, res);
    expect(findMany.mock.calls[0][0].where).toEqual({ userId: "u1" });
    expect(res.json).toHaveBeenCalledWith({
      totalCheckIns: 1,
      uniqueClubs: 1,
      uniqueCities: 1,
      mostVisitedClub: { id: "c1", name: "Club", visits: 1 },
      firstCheckInAt: "2026-09-01T20:00:00Z",
    });
  });

  it("returns 500 when the database fails", async () => {
    findMany.mockRejectedValue(new Error("db"));
    const res = makeRes();
    await getMyCheckInStats({ user: { id: "u1" } }, res);
    expect(res.status).toHaveBeenCalledWith(500);
  });
});
