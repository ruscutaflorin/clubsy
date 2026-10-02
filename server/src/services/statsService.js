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
