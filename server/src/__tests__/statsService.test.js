import { computeCheckInStats, computeCityProgress } from "../services/statsService.js";

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

describe("computeCityProgress", () => {
  const approved = [
    { id: "a", city: "Cluj" },
    { id: "b", city: "Cluj" },
    { id: "c", city: "Bucharest" },
    { id: "d", city: "Bucharest" },
    { id: "e", city: "Bucharest" },
  ];

  it("returns [] with no check-ins", () => {
    expect(computeCityProgress([], approved)).toEqual([]);
  });

  it("sorts by visitedClubs desc then city name", () => {
    const result = computeCityProgress(
      [
        checkIn(clubA, "2026-09-01T22:00:00.000Z"),
        checkIn(clubC, "2026-09-02T22:00:00.000Z"),
        checkIn(clubB, "2026-09-03T22:00:00.000Z"),
      ],
      approved,
    );
    expect(result).toEqual([
      { city: "Cluj", visitedClubs: 2, totalClubs: 2, lastVisitedAt: "2026-09-03T22:00:00.000Z" },
      {
        city: "Bucharest",
        visitedClubs: 1,
        totalClubs: 3,
        lastVisitedAt: "2026-09-02T22:00:00.000Z",
      },
    ]);
  });

  it("breaks ties by city name", () => {
    const result = computeCityProgress(
      [checkIn(clubA, "2026-09-01T22:00:00.000Z"), checkIn(clubC, "2026-09-01T22:00:00.000Z")],
      approved,
    );
    expect(result.map((r) => r.city)).toEqual(["Bucharest", "Cluj"]);
  });

  it("counts repeat visits to one club once", () => {
    const result = computeCityProgress(
      [checkIn(clubA, "2026-09-01T22:00:00.000Z"), checkIn(clubA, "2026-09-05T22:00:00.000Z")],
      approved,
    );
    expect(result[0].visitedClubs).toBe(1);
    expect(result[0].lastVisitedAt).toBe("2026-09-05T22:00:00.000Z");
  });

  it("does not inflate totalClubs with an unapproved visited club", () => {
    const gone = { id: "z", name: "Gone", city: "Cluj" };
    const result = computeCityProgress(
      [checkIn(clubA, "2026-09-01T22:00:00.000Z"), checkIn(gone, "2026-09-02T22:00:00.000Z")],
      approved,
    );
    expect(result[0].totalClubs).toBe(2);
    expect(result[0].visitedClubs).toBe(2);
  });

  it("caps visitedClubs at totalClubs", () => {
    const extra = ["z1", "z2", "z3"].map((id) => ({ id, name: id, city: "Cluj" }));
    const result = computeCityProgress(
      [clubA, clubB, ...extra].map((c) => checkIn(c, "2026-09-01T22:00:00.000Z")),
      approved,
    );
    expect(result[0].visitedClubs).toBe(2);
  });
});
