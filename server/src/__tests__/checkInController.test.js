import { jest } from "@jest/globals";

const findUnique = jest.fn();
const create = jest.fn();
const findMany = jest.fn();
const findFirst = jest.fn();
jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { club: { findUnique }, checkIn: { create, findMany, findFirst } },
}));

const { checkIn, getMyCheckInStats } = await import("../controllers/checkInController.js");
const { nightStart, nightEnd } = await import("../utils/night.js");

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
    jest.spyOn(console, "warn").mockImplementation(() => {});
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

  it("rejects a mocked location before looking up the club", async () => {
    const warn = jest.spyOn(console, "warn").mockImplementation(() => {});
    const res = makeRes();
    await checkIn(makeReq({ isMocked: true }), res);
    expect(res.status).toHaveBeenCalledWith(400);
    expect(res.json).toHaveBeenCalledWith({
      message: "Mock locations aren't allowed for check-ins",
    });
    expect(findUnique).not.toHaveBeenCalled();
    expect(JSON.parse(warn.mock.calls[0][0])).toEqual({
      evt: "checkin_failed",
      reason: "mock_location",
      userId: "u1",
      clubId: "c1",
    });
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

  it("scopes the once-a-night check to this club and tonight, so other clubs stay allowed", async () => {
    findUnique.mockResolvedValue({ ...club, id: "c2" });
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
    const now = new Date();
    expect(findFirst.mock.calls[0][0].where).toEqual({
      userId: "u1",
      clubId: "c2",
      checkedInAt: { gte: nightStart(now), lt: nightEnd(now) },
    });
  });

  describe("impossible travel", () => {
    // ~300 km north of the club at (45, 25)
    const farClub = { latitude: 47.7, longitude: 25 };

    it("rejects a check-in 300 km from one 30 minutes earlier", async () => {
      findUnique.mockResolvedValue(club);
      findFirst
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce({ checkedInAt: new Date(Date.now() - 30 * 60000), club: farClub });
      const res = makeRes();
      await checkIn(makeReq(), res);
      expect(res.status).toHaveBeenCalledWith(400);
      expect(res.json).toHaveBeenCalledWith({
        message: "This check-in doesn't match your previous one. Try again later.",
      });
      expect(create).not.toHaveBeenCalled();
    });

    it("allows a check-in 300 km from one 2 days earlier", async () => {
      findUnique.mockResolvedValue(club);
      findFirst
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce({ checkedInAt: new Date(Date.now() - 48 * 3600000), club: farClub });
      create.mockResolvedValue({ id: "ci1" });
      const res = makeRes();
      await checkIn(makeReq(), res);
      expect(res.status).toHaveBeenCalledWith(201);
    });
  });

  it("returns 500 when the database fails", async () => {
    findUnique.mockRejectedValue(new Error("db"));
    const res = makeRes();
    await checkIn(makeReq(), res);
    expect(res.status).toHaveBeenCalledWith(500);
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
