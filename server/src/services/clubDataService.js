import { distanceInMeters } from "../utils/geo.js";

const MIN_CLUBS_FOR_OUTLIER_CHECK = 3;

const normalizeCity = (city) => String(city ?? "").trim().toLowerCase();
const normalizeName = (name) => String(name ?? "").toLowerCase().replace(/[^a-z0-9]/g, "");

const isValidCoordinate = (club) => {
  const { latitude, longitude } = club;
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return false;
  if (latitude === 0 && longitude === 0) return false;
  return Math.abs(latitude) <= 90 && Math.abs(longitude) <= 180;
};

const median = (values) => {
  const sorted = [...values].sort((x, y) => x - y);
  const mid = Math.floor(sorted.length / 2);
  return sorted.length % 2 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2;
};

export const findClubDataIssues = (clubs, { duplicateMeters = 75, outlierKm = 30 } = {}) => {
  const invalidCoordinates = [];
  const valid = [];
  for (const club of clubs) {
    if (isValidCoordinate(club)) valid.push(club);
    else invalidCoordinates.push({ id: club.id, name: club.name, city: club.city });
  }

  const nearDuplicates = [];
  for (let i = 0; i < valid.length; i++) {
    for (let j = i + 1; j < valid.length; j++) {
      const a = valid[i];
      const b = valid[j];
      const meters = distanceInMeters(a.latitude, a.longitude, b.latitude, b.longitude);
      const nameA = normalizeName(a.name);
      const sameName =
        nameA !== "" &&
        nameA === normalizeName(b.name) &&
        normalizeCity(a.city) === normalizeCity(b.city);
      if (meters <= duplicateMeters || sameName) {
        nearDuplicates.push({
          a: { id: a.id, name: a.name },
          b: { id: b.id, name: b.name },
          meters: Math.round(meters),
          sameName,
        });
      }
    }
  }
  nearDuplicates.sort((x, y) => x.meters - y.meters);

  const byCity = new Map();
  for (const club of valid) {
    const key = normalizeCity(club.city);
    if (!byCity.has(key)) byCity.set(key, []);
    byCity.get(key).push(club);
  }

  const farFromCity = [];
  for (const group of byCity.values()) {
    if (group.length < MIN_CLUBS_FOR_OUTLIER_CHECK) continue;
    for (const club of group) {
      const others = group.filter((c) => c !== club);
      const km =
        distanceInMeters(
          club.latitude,
          club.longitude,
          median(others.map((c) => c.latitude)),
          median(others.map((c) => c.longitude)),
        ) / 1000;
      if (km > outlierKm) {
        farFromCity.push({
          id: club.id,
          name: club.name,
          city: club.city,
          km: Math.round(km * 10) / 10,
        });
      }
    }
  }
  farFromCity.sort((x, y) => y.km - x.km);

  const incompleteProfiles = [];
  for (const club of clubs) {
    const missing = [];
    const hours = club.openingHours;
    if (!hours || typeof hours !== "object" || Object.keys(hours).length === 0) {
      missing.push("openingHours");
    }
    if (!Array.isArray(club.genres) || club.genres.length === 0) missing.push("genres");
    if (typeof club.description !== "string" || club.description.trim() === "") {
      missing.push("description");
    }
    if (missing.length === 0) continue;
    incompleteProfiles.push({
      id: club.id,
      name: club.name,
      city: club.city,
      isApproved: club.isApproved,
      missing,
    });
  }
  incompleteProfiles.sort(
    (x, y) =>
      Number(Boolean(y.isApproved)) - Number(Boolean(x.isApproved)) ||
      y.missing.length - x.missing.length ||
      String(x.name ?? "").localeCompare(String(y.name ?? "")),
  );

  return { invalidCoordinates, nearDuplicates, farFromCity, incompleteProfiles };
};
