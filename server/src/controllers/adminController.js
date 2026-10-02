import prisma from "../prisma/client.js";
import { computePilotMetrics } from "../services/metricsService.js";

const ALLOWED_DAYS = [7, 30, 90];
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
