// A "night" runs 06:00-06:00 UTC, so a 2am check-in counts as part of the
// previous evening rather than starting a fresh night.
const NIGHT_START_HOUR = 6;

export const nightStart = (date = new Date()) => {
  const boundary = new Date(
    Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate(), NIGHT_START_HOUR)
  );
  if (date.getUTCHours() < NIGHT_START_HOUR) {
    boundary.setUTCDate(boundary.getUTCDate() - 1);
  }
  return boundary;
};

export const nightEnd = (date = new Date()) => {
  const end = new Date(nightStart(date));
  end.setUTCDate(end.getUTCDate() + 1);
  return end;
};
