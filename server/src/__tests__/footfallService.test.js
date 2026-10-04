import {
  computeClubFootfall,
  computeClubRanking,
  computeDistanceHealth,
  computeVibeSummary,
} from "../services/footfallService.js";

describe("computeVibeSummary", () => {
  it("averages and buckets ratings, ignoring nulls", () => {
    expect(computeVibeSummary([5, 4, 4, null, 3, 5])).toEqual({
      count: 5,
      average: 4.2,
      distribution: [0, 0, 1, 2, 2],
    });
  });

  it("withholds average and distribution below the floor", () => {
    expect(computeVibeSummary([5, 5, 4, 4])).toEqual({
      count: 4,
      average: null,
      distribution: null,
    });
  });
});

describe("computeDistanceHealth", () => {
  it("is insufficient with null numbers for no data", () => {
    expect(computeDistanceHealth([])).toEqual({
      count: 0,
      medianMeters: null,
      p90Meters: null,
      nearLimitShare: null,
      status: "insufficient",
    });
  });

  it("is insufficient with four distances", () => {
    expect(computeDistanceHealth([10, 20, 30, 40]).status).toBe("insufficient");
  });

  it("is ok for close check-ins", () => {
    const out = computeDistanceHealth([10, 20, 30, 40, 50, 60, 70, 80, 90, 100]);
    expect(out.medianMeters).toBe(50);
    expect(out.p90Meters).toBe(90);
    expect(out.status).toBe("ok");
  });

  it("is marginal when p90 is near the limit", () => {
    const out = computeDistanceHealth([10, 20, 30, 40, 50, 60, 70, 80, 125, 140]);
    expect(out.p90Meters).toBe(125);
    expect(out.status).toBe("marginal");
  });

  it("counts values >= 0.8 x limit as near the limit", () => {
    const out = computeDistanceHealth([10, 20, 30, 40, 50, 60, 70, 119, 120, 149]);
    expect(out.nearLimitShare).toBe(0.2);
  });
});

// Wednesday 2026-10-07 12:00 UTC
const now = new Date("2026-10-07T12:00:00Z");

describe("computeClubFootfall", () => {
  it("returns zeros and 12 weekly buckets with no check-ins", () => {
    const out = computeClubFootfall({ checkIns: [], firstVisits: [], now });
    expect(out.totalCheckIns).toBe(0);
    expect(out.uniqueVisitors).toBe(0);
    expect(out.returningVisitorRate).toBe(0);
    expect(out.firstTimeShare).toBe(0);
    expect(out.weekly).toHaveLength(12);
    expect(out.weekly.every((w) => w.checkIns === 0 && w.uniqueVisitors === 0)).toBe(true);
    expect(out.byWeekday).toEqual([0, 0, 0, 0, 0, 0, 0]);
  });

  it("counts a 02:00 Saturday check-in in Friday's weekday bucket", () => {
    // 2026-10-03 is a Saturday
    const out = computeClubFootfall({
      checkIns: [{ userId: "u1", checkedInAt: "2026-10-03T02:00:00Z" }],
      now,
    });
    expect(out.byWeekday[5]).toBe(1);
    expect(out.byWeekday[6]).toBe(0);
  });

  it("treats a user with visits in two different weeks as returning", () => {
    const out = computeClubFootfall({
      checkIns: [
        { userId: "u1", checkedInAt: "2026-09-25T22:00:00Z" },
        { userId: "u1", checkedInAt: "2026-10-02T22:00:00Z" },
        { userId: "u2", checkedInAt: "2026-10-02T23:00:00Z" },
      ],
      firstVisits: [
        { userId: "u1", firstCheckInAt: "2026-09-25T22:00:00Z" },
        { userId: "u2", firstCheckInAt: "2026-10-02T23:00:00Z" },
      ],
      now,
    });
    expect(out.uniqueVisitors).toBe(2);
    expect(out.returningVisitorRate).toBe(0.5);
    expect(out.firstTimeShare).toBe(1);
  });

  it("buckets visitors by distinct nights in the window and ignores older check-ins", () => {
    const out = computeClubFootfall({
      checkIns: [
        { userId: "a", checkedInAt: "2026-10-02T22:00:00Z" },
        { userId: "b", checkedInAt: "2026-10-02T21:00:00Z" },
        { userId: "b", checkedInAt: "2026-10-02T23:00:00Z" },
        { userId: "c", checkedInAt: "2026-09-25T22:00:00Z" },
        { userId: "c", checkedInAt: "2026-10-02T22:00:00Z" },
        { userId: "d", checkedInAt: "2026-09-11T22:00:00Z" },
        { userId: "d", checkedInAt: "2026-09-18T22:00:00Z" },
        { userId: "d", checkedInAt: "2026-09-25T22:00:00Z" },
        { userId: "d", checkedInAt: "2026-10-02T22:00:00Z" },
        { userId: "a", checkedInAt: "2025-01-01T22:00:00Z" },
        { userId: "a", checkedInAt: "2025-01-02T22:00:00Z" },
      ],
      now,
    });
    expect(out.visitFrequency).toEqual({ once: 2, twice: 1, threePlus: 1 });
    expect(out.regulars).toBe(1);
  });

  it("contains no userId in the output", () => {
    const out = computeClubFootfall({
      checkIns: [{ userId: "secret-user", checkedInAt: "2026-10-02T22:00:00Z" }],
      now,
    });
    expect(JSON.stringify(out)).not.toMatch(/userId|secret-user/);
  });
});

describe("computeClubRanking", () => {
  const DAY = 24 * 60 * 60 * 1000;
  const ago = (days) => new Date(now.getTime() - days * DAY);
  const clubs = [
    { id: "a", name: "Alpha", city: "Cluj" },
    { id: "b", name: "Beta", city: "Cluj" },
    { id: "c", name: "Gamma", city: "Iasi" },
  ];

  it("lists a club with no check-ins with zeros", () => {
    const out = computeClubRanking({ clubs, checkIns: [], now });
    expect(out.weeks).toBe(4);
    expect(out.clubs).toHaveLength(3);
    expect(out.clubs[0]).toEqual({
      id: "a",
      name: "Alpha",
      city: "Cluj",
      checkIns: 0,
      uniqueVisitors: 0,
      previousCheckIns: 0,
      change: 0,
    });
  });

  it("counts two check-ins by one user as 2 check-ins, 1 visitor", () => {
    const out = computeClubRanking({
      clubs,
      checkIns: [
        { clubId: "a", userId: "u1", checkedInAt: ago(1) },
        { clubId: "a", userId: "u1", checkedInAt: ago(2) },
      ],
      now,
    });
    expect(out.clubs[0]).toMatchObject({ id: "a", checkIns: 2, uniqueVisitors: 1 });
  });

  it("counts 5 weeks ago as previous and 9 weeks ago nowhere", () => {
    const out = computeClubRanking({
      clubs,
      checkIns: [
        { clubId: "a", userId: "u1", checkedInAt: ago(35) },
        { clubId: "a", userId: "u2", checkedInAt: ago(63) },
        { clubId: "zzz", userId: "u3", checkedInAt: ago(1) },
      ],
      now,
    });
    const a = out.clubs.find((c) => c.id === "a");
    expect(a).toMatchObject({ checkIns: 0, previousCheckIns: 1, change: -1 });
  });

  it("sorts by check-ins, then visitors, then name", () => {
    const ci = (clubId, userId) => ({ clubId, userId, checkedInAt: ago(1) });
    const out = computeClubRanking({
      clubs,
      checkIns: [
        ci("c", "u1"),
        ci("c", "u2"),
        ci("b", "u1"),
        ci("b", "u1"),
        ci("a", "u1"),
        ci("a", "u1"),
      ],
      now,
    });
    expect(out.clubs.map((c) => c.id)).toEqual(["c", "a", "b"]);
  });

  it("never outputs user ids", () => {
    const out = computeClubRanking({
      clubs,
      checkIns: [{ clubId: "a", userId: "secret-user-id", checkedInAt: ago(1) }],
      now,
    });
    expect(JSON.stringify(out)).not.toMatch(/userId|secret-user-id/);
  });
});
