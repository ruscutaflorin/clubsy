import { distanceInMeters } from "../utils/geo.js";

describe("distanceInMeters", () => {
  it("returns 0 for identical points", () => {
    expect(distanceInMeters(44.43, 26.1, 44.43, 26.1)).toBe(0);
  });

  it("measures one degree of latitude as roughly 111km", () => {
    const d = distanceInMeters(0, 0, 1, 0);
    expect(d).toBeGreaterThan(111000);
    expect(d).toBeLessThan(111500);
  });

  it("measures a ~100m offset as inside the 150m check-in radius", () => {
    const d = distanceInMeters(44.43, 26.1, 44.43 + 100 / 111195, 26.1);
    expect(d).toBeGreaterThan(95);
    expect(d).toBeLessThan(105);
  });
});
