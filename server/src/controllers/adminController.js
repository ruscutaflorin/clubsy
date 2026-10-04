import prisma from "../prisma/client.js";
import { computePilotMetrics, computePilotScorecard } from "../services/metricsService.js";
import {
  computeClubFootfall,
  computeClubRanking,
  computeDistanceHealth,
} from "../services/footfallService.js";

import { findClubDataIssues } from "../services/clubDataService.js";

const ALLOWED_DAYS =[7, 30, 90];
const DAY_MS = 24 * 60 * 60 * 1000;

export const getMetrics = async (req, res) => {
  const days = Number(req.query.days ?? "7");
  if (!ALLOWED_DAYS.includes(days)) {
    return res.status(400).json({ message: "days must be 7, 30 or 90" });
  }
  try {
    const now = new Date();
    const since = new Date(now.getTime() - (days + 14) * DAY_MS);
    const [users, checkIns] = await Promise.all([
      prisma.user.findMany({
        where: { createdAt: { gte: since } },
        select: { id: true, createdAt: true },
      }),
      prisma.checkIn.findMany({
        where: { checkedInAt: { gte: since } },
        select: {
          userId: true,
          clubId: true,
          checkedInAt: true,
          club: { select: { name: true } },
        },
      }),
    ]);
    res.json(computePilotMetrics({ users, checkIns, now, days }));
  } catch (error) {
    console.error("Metrics error:", error);
    res.status(500).json({ message: "Failed to compute metrics" });
  }
};

export const getScorecard = async (req, res) => {
  try {
    const [users, checkIns, approvedClubCount] = await Promise.all([
      prisma.user.findMany({ select: { id: true, createdAt: true } }),
      prisma.checkIn.findMany({ select: { userId: true, checkedInAt: true } }),
      prisma.club.count({ where: { isApproved: true } }),
    ]);
    res.json(computePilotScorecard({ users, checkIns, approvedClubCount, now: new Date() }));
  } catch (error) {
    console.error("Scorecard error:", error);
    res.status(500).json({ message: "Failed to compute scorecard" });
  }
};

const ALLOWED_FOOTFALL_WEEKS = [4, 12, 26, 52];

export const getClubFootfall = async (req, res) => {
  const weeks = Number(req.query.weeks ?? "12");
  if (!ALLOWED_FOOTFALL_WEEKS.includes(weeks)) {
    return res.status(400).json({ message: "weeks must be 4, 12, 26 or 52" });
  }
  try {
    const club = await prisma.club.findUnique({
      where: { id: req.params.id },
      select: { id: true },
    });
    if (!club) return res.status(404).json({ message: "Club not found" });

    const now = new Date();
    // One extra week of slack so the oldest Monday-aligned bucket is fully covered.
    const since = new Date(now.getTime() - (weeks + 1) * 7 * DAY_MS);
    const checkIns = await prisma.checkIn.findMany({
      where: { clubId: club.id, checkedInAt: { gte: since } },
      select: { userId: true, checkedInAt: true, distanceMeters: true },
    });
    const visitorIds = [...new Set(checkIns.map((c) => c.userId))];
    const firsts = visitorIds.length
      ? await prisma.checkIn.groupBy({
          by: ["userId"],
          where: { clubId: club.id, userId: { in: visitorIds } },
          _min: { checkedInAt: true },
        })
      : [];
    const firstVisits = firsts.map((f) => ({
      userId: f.userId,
      firstCheckInAt: f._min.checkedInAt,
    }));
    const distances = checkIns.map((c) => c.distanceMeters).filter((d) => typeof d === "number");
    res.json({
      ...computeClubFootfall({ checkIns, firstVisits, now, weeks }),
      distance: computeDistanceHealth(distances),
    });
  } catch (error) {
    console.error("Club footfall error:", error);
    res.status(500).json({ message: "Failed to compute footfall" });
  }
};

const RANKING_WEEKS = 4;

export const getClubRanking = async (req, res) => {
  try {
    const now = new Date();
    const since = new Date(now.getTime() - 2 * RANKING_WEEKS * 7 * DAY_MS);
    const [clubs, checkIns] = await Promise.all([
      prisma.club.findMany({
        where: { isApproved: true },
        select: { id: true, name: true, city: true },
      }),
      prisma.checkIn.findMany({
        where: { checkedInAt: { gte: since } },
        select: { clubId: true, userId: true, checkedInAt: true },
      }),
    ]);
    res.json(computeClubRanking({ clubs, checkIns, now, weeks: RANKING_WEEKS }));
  } catch (error) {
    console.error("Club ranking error:", error);
    res.status(500).json({ message: "Failed to compute club ranking" });
  }
};

export const getClubDataHealth = async (req, res) => {
  try {
    const clubs = await prisma.club.findMany({
      select: {
        id: true,
        name: true,
        city: true,
        latitude: true,
        longitude: true,
        isApproved: true,
      },
    });
    res.json(findClubDataIssues(clubs));
  } catch (error) {
    console.error("Club data health error:", error);
    res.status(500).json({ message: "Failed to compute club data health" });
  }
};
