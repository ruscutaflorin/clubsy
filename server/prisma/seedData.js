const DEFAULT_CENTER = { latitude: 44.4305, longitude: 26.1015 };
const METERS_PER_DEGREE_LAT = 111320;

const LOCAL_CLUBS = [
  { name: "Velvet Lantern", street: "Strada Lipscani" },
  { name: "The Copper Owl", street: "Strada Smârdan" },
  { name: "Neon Orchard", street: "Strada Franceză" },
  { name: "Midnight Atlas", street: "Strada Covaci" },
  { name: "Paper Moon Cellar", street: "Strada Blănari" },
  { name: "Static Bloom", street: "Strada Gabroveni" },
  { name: "Echo Harbor", street: "Strada Ion Brezoianu" },
  { name: "Glass Fox", street: "Strada Selari" },
  { name: "Saffron Room", street: "Strada Stavropoleos" },
  { name: "Lowtide Social", street: "Strada Șelari" },
];

const OTHER_CITY = {
  city: "Cluj-Napoca",
  center: { latitude: 46.7712, longitude: 23.6236 },
  clubs: [
    { name: "Amber Vinyl", street: "Strada Memorandumului" },
    { name: "Hollow Crown", street: "Strada Matei Corvin" },
  ],
};

const offsetCoordinates = (center, northMeters, eastMeters) => ({
  latitude: center.latitude + northMeters / METERS_PER_DEGREE_LAT,
  longitude:
    center.longitude +
    eastMeters / (METERS_PER_DEGREE_LAT * Math.cos((center.latitude * Math.PI) / 180)),
});

const round = (value) => Math.round(value * 1e6) / 1e6;

export const slugify = (name) =>
  name
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");

// Pure and deterministic: no secrets here, they are added when written to the database.
export const buildSeedClubs = ({ center = DEFAULT_CENTER, count = 10 } = {}) => {
  const otherCount = Math.min(OTHER_CITY.clubs.length, Math.max(count - 1, 0));
  const localCount = Math.min(Math.max(count - otherCount, 0), LOCAL_CLUBS.length);

  const local = LOCAL_CLUBS.slice(0, localCount).map((club, i) => {
    const angle = (2 * Math.PI * i) / localCount;
    const radius = 400 + ((i * 370) % 1400); // 400 m .. 1.8 km
    const { latitude, longitude } = offsetCoordinates(
      center,
      Math.sin(angle) * radius,
      Math.cos(angle) * radius,
    );
    return {
      name: club.name,
      address: `${club.street} ${10 + i * 7}`,
      city: "Bucharest",
      latitude: round(latitude),
      longitude: round(longitude),
      isApproved: true,
    };
  });

  const other = OTHER_CITY.clubs.slice(0, otherCount).map((club, i) => {
    const { latitude, longitude } = offsetCoordinates(OTHER_CITY.center, i * 300, i * -250);
    return {
      name: club.name,
      address: `${club.street} ${5 + i * 11}`,
      city: OTHER_CITY.city,
      latitude: round(latitude),
      longitude: round(longitude),
      isApproved: true,
    };
  });

  return [...local, ...other];
};
