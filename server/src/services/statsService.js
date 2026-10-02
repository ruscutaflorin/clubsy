// Pure aggregation over a user's check-ins (each including its club), so it can be
// unit-tested without a database.
export const computeCheckInStats = (checkIns) => {
  if (checkIns.length === 0) {
    return {
      totalCheckIns: 0,
      uniqueClubs: 0,
      uniqueCities: 0,
      mostVisitedClub: null,
      firstCheckInAt: null,
    };
  }

  const cities = new Set();
  const visitsByClub = new Map();
  let firstCheckInAt = checkIns[0].checkedInAt;

  for (const checkIn of checkIns) {
    cities.add(checkIn.club.city);

    const entry = visitsByClub.get(checkIn.clubId) ?? { club: checkIn.club, visits: 0 };
    entry.visits += 1;
    visitsByClub.set(checkIn.clubId, entry);

    if (new Date(checkIn.checkedInAt) < new Date(firstCheckInAt)) {
      firstCheckInAt = checkIn.checkedInAt;
    }
  }

  let mostVisited = null;
  for (const entry of visitsByClub.values()) {
    if (!mostVisited || entry.visits > mostVisited.visits) {
      mostVisited = entry;
    }
  }

  return {
    totalCheckIns: checkIns.length,
    uniqueClubs: visitsByClub.size,
    uniqueCities: cities.size,
    mostVisitedClub: {
      id: mostVisited.club.id,
      name: mostVisited.club.name,
      visits: mostVisited.visits,
    },
    firstCheckInAt,
  };
};

// Per-city collection progress: how many of a city's approved clubs the user has visited.
// Only cities with at least one check-in appear. A visited club that is no longer approved
// still counts as visited, but visitedClubs is capped at totalClubs for display.
export const computeCityProgress = (checkIns, approvedClubs) => {
  const totals = new Map();
  for (const club of approvedClubs) {
    totals.set(club.city, (totals.get(club.city) ?? 0) + 1);
  }

  const cities = new Map();
  for (const checkIn of checkIns) {
    const city = checkIn.club.city;
    const entry = cities.get(city) ?? { clubs: new Set(), lastVisitedAt: checkIn.checkedInAt };
    entry.clubs.add(checkIn.clubId);
    if (new Date(checkIn.checkedInAt) > new Date(entry.lastVisitedAt)) {
      entry.lastVisitedAt = checkIn.checkedInAt;
    }
    cities.set(city, entry);
  }

  return [...cities.entries()]
    .map(([city, entry]) => {
      const totalClubs = totals.get(city) ?? 0;
      return {
        city,
        visitedClubs: Math.min(entry.clubs.size, totalClubs),
        totalClubs,
        lastVisitedAt: entry.lastVisitedAt,
      };
    })
    .sort((a, b) => b.visitedClubs - a.visitedClubs || a.city.localeCompare(b.city));
};
