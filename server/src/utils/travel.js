import { distanceInMeters } from "./geo.js";

const MIN_DISTANCE_METERS = 1000;

export const isImpossibleTravel = (previous, next, maxSpeedKmh = 250) => {
  const meters = distanceInMeters(
    previous.latitude,
    previous.longitude,
    next.latitude,
    next.longitude
  );
  if (meters < MIN_DISTANCE_METERS) return false;

  const hours = (new Date(next.at).getTime() - new Date(previous.at).getTime()) / 3600000;
  if (hours <= 0) return true;

  return meters / 1000 / hours > maxSpeedKmh;
};
