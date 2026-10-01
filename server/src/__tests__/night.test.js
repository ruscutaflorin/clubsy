import { nightStart, nightEnd } from "../utils/night.js";

const d = (iso) => new Date(iso);

describe("nightStart", () => {
  it("puts 23:00 and the following 02:00 in the same night", () => {
    const evening = nightStart(d("2026-09-12T23:00:00Z"));
    const earlyMorning = nightStart(d("2026-09-13T02:00:00Z"));
    expect(evening.toISOString()).toBe(earlyMorning.toISOString());
  });

  it("starts a new night at 07:00", () => {
    const previousNight = nightStart(d("2026-09-12T23:00:00Z"));
    const nextDay = nightStart(d("2026-09-13T07:00:00Z"));
    expect(nextDay.toISOString()).not.toBe(previousNight.toISOString());
    expect(nextDay.toISOString()).toBe("2026-09-13T06:00:00.000Z");
  });

  it("treats exactly 06:00 as the start of that day's night", () => {
    expect(nightStart(d("2026-09-12T06:00:00Z")).toISOString()).toBe(
      "2026-09-12T06:00:00.000Z"
    );
  });
});

describe("nightEnd", () => {
  it("is 24 hours after nightStart", () => {
    const now = d("2026-09-12T23:00:00Z");
    expect(nightEnd(now).getTime() - nightStart(now).getTime()).toBe(24 * 60 * 60 * 1000);
  });
});
