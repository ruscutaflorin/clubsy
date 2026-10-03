import { isImpossibleTravel } from "../utils/travel.js";
import { distanceInMeters } from "../utils/geo.js";

const t0 = new Date("2026-01-01T22:00:00Z");
const after = (minutes) => new Date(t0.getTime() + minutes * 60000);
// ~1 degree of latitude is ~111.19 km
const at = (km, minutes) => ({ latitude: 45 + km / 111.195, longitude: 25, at: after(minutes) });
const origin = { latitude: 45, longitude: 25, at: t0 };

describe("isImpossibleTravel", () => {
  it("flags 100 km in 10 minutes", () => {
    expect(isImpossibleTravel(origin, at(100, 10))).toBe(true);
  });

  it("allows 100 km in 2 hours", () => {
    expect(isImpossibleTravel(origin, at(100, 120))).toBe(false);
  });

  it("ignores 500 m apart 1 minute later", () => {
    expect(isImpossibleTravel(origin, at(0.5, 1))).toBe(false);
  });

  it("allows exactly the speed limit", () => {
    const next = at(100, 60);
    const km = distanceInMeters(origin.latitude, origin.longitude, next.latitude, next.longitude);
    expect(isImpossibleTravel(origin, next, km / 1000)).toBe(false);
  });

  it("flags a simultaneous check-in far away", () => {
    expect(isImpossibleTravel(origin, at(50, 0))).toBe(true);
  });
});
