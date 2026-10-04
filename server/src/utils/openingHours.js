export const DAYS = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"];

const TIME_RE = /^([01]\d|2[0-3]):[0-5]\d$/;
const MAX_SLOTS_PER_DAY = 4;

const toMinutes = (time) => {
  const [h, m] = time.split(":").map(Number);
  return h * 60 + m;
};

// Returns an error message, or null when `value` is a valid weekly schedule:
// `{mon: [{open: "23:00", close: "05:00"}], ...}`. A close before the open
// means the slot runs past midnight into the next day.
export const openingHoursError = (value) => {
  if (value === null) return null;
  if (typeof value !== "object" || Array.isArray(value)) {
    return "openingHours must be an object keyed by day";
  }
  for (const [day, slots] of Object.entries(value)) {
    if (!DAYS.includes(day)) return `openingHours has an unknown day "${day}"`;
    if (!Array.isArray(slots) || slots.length > MAX_SLOTS_PER_DAY) {
      return `openingHours.${day} must be a list of at most ${MAX_SLOTS_PER_DAY} slots`;
    }
    for (const slot of slots) {
      if (
        !slot ||
        typeof slot.open !== "string" ||
        typeof slot.close !== "string" ||
        !TIME_RE.test(slot.open) ||
        !TIME_RE.test(slot.close)
      ) {
        return `openingHours.${day} slots need open and close as HH:MM`;
      }
      if (slot.open === slot.close) {
        return `openingHours.${day} slot opens and closes at the same time`;
      }
    }
  }
  return null;
};

const localParts = (date, timezone) => {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone: timezone,
    weekday: "short",
    hour: "2-digit",
    minute: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type).value;
  return {
    day: get("weekday").toLowerCase().slice(0, 3),
    minutes: Number(get("hour")) * 60 + Number(get("minute")),
  };
};

// The wall-clock time at `date` in `timezone` as "YYYY-MM-DDTHH:mm:ss" (no
// offset), so clients can show "Open now" without knowing the zone database.
export const localNowString = (timezone, date = new Date()) => {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: timezone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
    hourCycle: "h23",
  }).formatToParts(date);
  const get = (type) => parts.find((p) => p.type === type).value;
  return `${get("year")}-${get("month")}-${get("day")}T${get("hour")}:${get("minute")}:${get("second")}`;
};

// True when the venue is open at `date` in its own timezone. A slot belongs to
// the day it opens on, so Friday 23:00-05:00 is still open on Saturday 02:00.
export const isOpenAt = (openingHours, timezone, date = new Date()) => {
  if (!openingHours || Array.isArray(openingHours)) return false;
  const { day, minutes } = localParts(date, timezone);
  const yesterday = DAYS[(DAYS.indexOf(day) + 6) % 7];

  const openToday = (openingHours[day] ?? []).some(({ open, close }) => {
    const start = toMinutes(open);
    const end = toMinutes(close);
    return end > start ? minutes >= start && minutes < end : minutes >= start;
  });
  if (openToday) return true;

  return (openingHours[yesterday] ?? []).some(({ open, close }) => {
    const start = toMinutes(open);
    const end = toMinutes(close);
    return end < start && minutes < end;
  });
};
