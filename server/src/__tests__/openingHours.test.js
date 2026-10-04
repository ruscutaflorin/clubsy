import { isOpenAt, openingHoursError } from "../utils/openingHours.js";

const TZ = "Europe/Bucharest";
// Bucharest is UTC+3 in October (EEST until 2026-10-25), so local = UTC + 3h.
const local = (iso) => new Date(`${iso}+03:00`);

const hours = {
  fri: [{ open: "23:00", close: "05:00" }],
  sat: [{ open: "22:00", close: "04:00" }],
  wed: [{ open: "20:00", close: "23:00" }],
};

describe("isOpenAt", () => {
  it.each([
    ["Friday 23:30, after opening", "2026-10-02T23:30:00", true],
    ["Saturday 02:00, still Friday's slot", "2026-10-03T02:00:00", true],
    ["Saturday 06:00, Friday's slot has ended", "2026-10-03T06:00:00", false],
    ["Saturday 12:00, between Friday's close and Saturday's open", "2026-10-03T12:00:00", false],
    ["Sunday 03:00, Saturday's slot is still running", "2026-10-04T03:00:00", true],
    ["Sunday 05:00, Saturday's slot has ended", "2026-10-04T05:00:00", false],
    ["Thursday 23:30, no Thursday slot", "2026-10-01T23:30:00", false],
    ["Friday 04:00, no Thursday slot spills over", "2026-10-02T04:00:00", false],
    ["Wednesday 21:00 inside a same-day slot", "2026-09-30T21:00:00", true],
    ["Wednesday 23:00 exactly at a same-day close", "2026-09-30T23:00:00", false],
  ])("%s", (_label, iso, expected) => {
    expect(isOpenAt(hours, TZ, local(iso))).toBe(expected);
  });

  it("reads the clock in the club's timezone, not UTC", () => {
    // 21:30 UTC on Friday is 00:30 Saturday in Bucharest.
    expect(isOpenAt(hours, TZ, new Date("2026-10-02T21:30:00Z"))).toBe(true);
    expect(isOpenAt(hours, "UTC", new Date("2026-10-02T21:30:00Z"))).toBe(false);
  });

  it("is closed without a schedule", () => {
    expect(isOpenAt(null, TZ, new Date())).toBe(false);
  });
});

describe("openingHoursError", () => {
  it("accepts null, an empty schedule and overnight slots", () => {
    expect(openingHoursError(null)).toBeNull();
    expect(openingHoursError({})).toBeNull();
    expect(openingHoursError(hours)).toBeNull();
  });

  it.each([
    ["an array", []],
    ["a string", "24/7"],
    ["an unknown day", { monday: [] }],
    ["slots that are not a list", { mon: { open: "22:00", close: "04:00" } }],
    ["a bad time", { mon: [{ open: "7pm", close: "04:00" }] }],
    ["a missing close", { mon: [{ open: "22:00" }] }],
    ["an equal open and close", { mon: [{ open: "22:00", close: "22:00" }] }],
  ])("rejects %s", (_label, value) => {
    expect(openingHoursError(value)).toEqual(expect.any(String));
  });
});
