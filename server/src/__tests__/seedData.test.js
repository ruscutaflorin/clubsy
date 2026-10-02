import { buildSeedClubs } from "../../prisma/seedData.js";
import { distanceInMeters } from "../utils/geo.js";

const center = { latitude: 44.4305, longitude: 26.1015 };

describe("buildSeedClubs", () => {
  const clubs = buildSeedClubs({ center, count: 10 });

  it("returns 10 approved clubs with unique names", () => {
    expect(clubs).toHaveLength(10);
    expect(new Set(clubs.map((c) => c.name)).size).toBe(10);
    expect(clubs.every((c) => c.isApproved === true)).toBe(true);
  });

  it("keeps clubs within 2.5 km of center except the second city", () => {
    const local = clubs.filter((c) => c.city === "Bucharest");
    expect(local.length).toBe(8);
    for (const c of local) {
      const d = distanceInMeters(center.latitude, center.longitude, c.latitude, c.longitude);
      expect(d).toBeLessThan(2500);
    }
  });

  it("has two cities", () => {
    expect(new Set(clubs.map((c) => c.city)).size).toBe(2);
  });

  it("is deterministic and defaults the center", () => {
    expect(buildSeedClubs({ center, count: 10 })).toEqual(clubs);
    expect(buildSeedClubs()).toEqual(clubs);
  });

  it("has no qrSecret field", () => {
    expect(clubs.some((c) => "qrSecret" in c)).toBe(false);
  });
});
