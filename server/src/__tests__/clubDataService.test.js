import { findClubDataIssues } from "../services/clubDataService.js";

const club = (id, name, city, latitude, longitude) => ({
  id,
  name,
  city,
  latitude,
  longitude,
  isApproved: true,
});

// ~111.2 m per 0.001 degree of latitude
const LAT_PER_METER = 1 / 111195;

describe("findClubDataIssues", () => {
  it("returns three empty lists for no clubs", () => {
    expect(findClubDataIssues([])).toEqual({
      invalidCoordinates: [],
      nearDuplicates: [],
      farFromCity: [],
    });
  });

  it("lists two clubs 40 m apart as one near-duplicate pair", () => {
    const { nearDuplicates } = findClubDataIssues([
      club("a", "Alpha", "Cluj", 46.77, 23.59),
      club("b", "Beta", "Cluj", 46.77 + 40 * LAT_PER_METER, 23.59),
    ]);
    expect(nearDuplicates).toHaveLength(1);
    expect(nearDuplicates[0].meters).toBeGreaterThanOrEqual(39);
    expect(nearDuplicates[0].meters).toBeLessThanOrEqual(41);
    expect(nearDuplicates[0].sameName).toBe(false);
  });

  it("pairs same normalised name in the same city even when far apart", () => {
    const { nearDuplicates } = findClubDataIssues([
      club("a", "Club  X!", "Cluj", 46.77, 23.59),
      club("b", "club x", " cluj ", 46.77 + 5000 * LAT_PER_METER, 23.59),
    ]);
    expect(nearDuplicates).toHaveLength(1);
    expect(nearDuplicates[0].sameName).toBe(true);
  });

  it("puts a 0,0 club only in invalidCoordinates", () => {
    const result = findClubDataIssues([
      club("a", "Zero", "Cluj", 0, 0),
      club("b", "Other", "Cluj", 0, 0.0001),
    ]);
    expect(result.invalidCoordinates.map((c) => c.id)).toEqual(["a"]);
    expect(result.nearDuplicates).toEqual([]);
    expect(result.farFromCity).toEqual([]);
  });

  it("flags out-of-range and non-finite coordinates", () => {
    const { invalidCoordinates } = findClubDataIssues([
      club("a", "A", "C", 91, 10),
      club("b", "B", "C", 10, 181),
      club("c", "C", "C", NaN, 10),
    ]);
    expect(invalidCoordinates.map((c) => c.id)).toEqual(["a", "b", "c"]);
  });

  it("flags a club 50 km from the other two in its city", () => {
    const { farFromCity } = findClubDataIssues([
      club("a", "A", "Cluj", 46.77, 23.59),
      club("b", "B", "Cluj", 46.78, 23.6),
      club("c", "C", "Cluj", 46.77 + 50000 * LAT_PER_METER, 23.59),
    ]);
    expect(farFromCity.map((c) => c.id)).toEqual(["c"]);
    expect(farFromCity[0].km).toBeGreaterThan(49);
  });

  it("never reports farFromCity for a city with two clubs", () => {
    const { farFromCity } = findClubDataIssues([
      club("a", "A", "Cluj", 46.77, 23.59),
      club("b", "B", "Cluj", 47.77, 24.59),
    ]);
    expect(farFromCity).toEqual([]);
  });
});
