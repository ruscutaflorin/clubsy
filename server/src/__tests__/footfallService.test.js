import { computeClubFootfall } from "../services/footfallService.js";

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

  it("contains no userId in the output", () => {
    const out = computeClubFootfall({
      checkIns: [{ userId: "secret-user", checkedInAt: "2026-10-02T22:00:00Z" }],
      now,
    });
    expect(JSON.stringify(out)).not.toMatch(/userId|secret-user/);
  });
});
