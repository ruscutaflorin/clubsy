import { computeCheckInStats } from "../services/statsService.js";

const clubA = { id: "a", name: "Club A", city: "Cluj" };
const clubB = { id: "b", name: "Club B", city: "Cluj" };
const clubC = { id: "c", name: "Club C", city: "Bucharest" };

const checkIn = (club, checkedInAt) => ({
  clubId: club.id,
  club,
  checkedInAt,
});

describe("computeCheckInStats", () => {
  it("returns zeroed stats for an empty history", () => {
    expect(computeCheckInStats([])).toEqual({
      totalCheckIns: 0,
      uniqueClubs: 0,
      uniqueCities: 0,
      mostVisitedClub: null,
      firstCheckInAt: null,
    });
  });

  it("aggregates several clubs across two cities", () => {
    const stats = computeCheckInStats([
      checkIn(clubA, "2026-09-01T20:00:00Z"),
      checkIn(clubA, "2026-09-05T20:00:00Z"),
      checkIn(clubB, "2026-09-03T20:00:00Z"),
      checkIn(clubC, "2026-09-10T20:00:00Z"),
    ]);

    expect(stats.totalCheckIns).toBe(4);
    expect(stats.uniqueClubs).toBe(3);
    expect(stats.uniqueCities).toBe(2);
    expect(stats.mostVisitedClub).toEqual({ id: "a", name: "Club A", visits: 2 });
    expect(stats.firstCheckInAt).toBe("2026-09-01T20:00:00Z");
  });

  it("picks the first-encountered club when visit counts tie", () => {
    const stats = computeCheckInStats([
      checkIn(clubA, "2026-09-01T20:00:00Z"),
      checkIn(clubB, "2026-09-02T20:00:00Z"),
    ]);

    expect(stats.mostVisitedClub).toEqual({ id: "a", name: "Club A", visits: 1 });
  });

  it("finds the earliest check-in regardless of input order", () => {
    const stats = computeCheckInStats([
      checkIn(clubA, "2026-09-10T20:00:00Z"),
      checkIn(clubB, "2026-09-01T20:00:00Z"),
      checkIn(clubC, "2026-09-05T20:00:00Z"),
    ]);

    expect(stats.firstCheckInAt).toBe("2026-09-01T20:00:00Z");
  });
});
