import prisma from "../prisma/client.js";
import { visibleToUser } from "../utils/blocks.js";
import { nightStart } from "../utils/night.js";

const PAGE_SIZE = 20;

// Check-ins a friend lets the viewer see: both sides share, not hidden, night already over
// (checkedInAt before the current night's start == now >= nightEnd(checkedInAt)).
// Returns null when the viewer doesn't share, since sharing is opt-in on both sides.
const visibleCheckInsWhere = async (viewerId) => {
  const me = await prisma.user.findUnique({ where: { id: viewerId } });
  if (!me?.shareNightsWithFriends) return null;
  const friendships = await prisma.friendship.findMany({
    where: {
      status: "ACCEPTED",
      OR: [{ requesterId: viewerId }, { addresseeId: viewerId }],
    },
  });
  const friendIds = friendships.map((f) =>
    f.requesterId === viewerId ? f.addresseeId : f.requesterId
  );
  return {
    userId: { in: friendIds },
    hiddenFromFriends: false,
    checkedInAt: { lt: nightStart(new Date()) },
    user: { is: { shareNightsWithFriends: true, ...visibleToUser(viewerId) } },
  };
};

export const getFeed = async (req, res) => {
  try {
    const where = await visibleCheckInsWhere(req.user.id);
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    if (!where) return res.json({ nights: [], page, hasMore: false });
    const rows = await prisma.checkIn.findMany({
      where,
      orderBy: { checkedInAt: "desc" },
      skip: (page - 1) * PAGE_SIZE,
      take: PAGE_SIZE + 1,
      include: {
        club: { select: { id: true, name: true, city: true } },
        user: { select: { id: true, username: true, name: true } },
      },
    });
    // Date of the night only; the check-in time itself is never exposed.
    const nights = rows.slice(0, PAGE_SIZE).map((c) => ({
      id: c.id,
      nightDate: nightStart(c.checkedInAt).toISOString().slice(0, 10),
      club: c.club,
      user: c.user,
    }));
    res.json({ nights, page, hasMore: rows.length > PAGE_SIZE });
  } catch (error) {
    console.error("getFeed error:", error);
    res.status(500).json({ message: "Failed to load feed" });
  }
};

export const getFriendNights = async (req, res) => {
  try {
    const base = await visibleCheckInsWhere(req.user.id);
    const page = Math.max(parseInt(req.query.page, 10) || 1, 1);
    if (!base) {
      return res.json({ nights: [], page, hasMore: false, sharedClubCount: 0, newToYou: [] });
    }
    // Narrowing to one id inside the friend list: non-friends just get an empty list.
    const where = { ...base, AND: [{ userId: req.params.userId }] };
    const rows = await prisma.checkIn.findMany({
      where,
      orderBy: { checkedInAt: "desc" },
      skip: (page - 1) * PAGE_SIZE,
      take: PAGE_SIZE + 1,
      include: { club: { select: { id: true, name: true, city: true } } },
    });
    const nights = rows.slice(0, PAGE_SIZE).map((c) => ({
      id: c.id,
      nightDate: nightStart(c.checkedInAt).toISOString().slice(0, 10),
      club: c.club,
    }));
    const body = { nights, page, hasMore: rows.length > PAGE_SIZE };
    if (page === 1) {
      const [theirs, mine] = await Promise.all([
        prisma.checkIn.findMany({
          where,
          distinct: ["clubId"],
          select: { clubId: true, club: { select: { id: true, name: true, city: true } } },
        }),
        prisma.checkIn.findMany({
          where: { userId: req.user.id },
          distinct: ["clubId"],
          select: { clubId: true },
        }),
      ]);
      const mineIds = new Set(mine.map((c) => c.clubId));
      body.sharedClubCount = theirs.filter((c) => mineIds.has(c.clubId)).length;
      body.newToYou = theirs
        .filter((c) => !mineIds.has(c.clubId))
        .map((c) => ({ id: c.club.id, name: c.club.name, city: c.club.city }))
        .sort((a, b) => a.name.localeCompare(b.name));
    }
    res.json(body);
  } catch (error) {
    console.error("getFriendNights error:", error);
    res.status(500).json({ message: "Failed to load friend's nights" });
  }
};

export const getClubFriendCount = async (req, res) => {
  try {
    const where = await visibleCheckInsWhere(req.user.id);
    if (!where) return res.json({ count: 0 });
    const rows = await prisma.checkIn.findMany({
      where: { ...where, clubId: req.params.clubId },
      distinct: ["userId"],
      select: { userId: true },
    });
    res.json({ count: rows.length });
  } catch (error) {
    console.error("getClubFriendCount error:", error);
    res.status(500).json({ message: "Failed to load friend count" });
  }
};
