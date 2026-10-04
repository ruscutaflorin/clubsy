import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";

export const REPORT_REASONS = ["SPAM", "HARASSMENT", "INAPPROPRIATE", "IMPERSONATION", "OTHER"];
export const FLAG_THRESHOLD = 3;

const userSelect = { id: true, username: true, name: true };

export const createReport = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { userId, reason, details } = req.body;
    if (userId === req.user.id) {
      return res.status(400).json({ message: "You can't report yourself" });
    }

    const target = await prisma.user.findUnique({ where: { id: userId }, select: { id: true } });
    if (!target) {
      return res.status(404).json({ message: "User not found" });
    }

    await prisma.report.create({
      data: { reporterId: req.user.id, reportedUserId: userId, reason, details: details || null },
    });
    res.status(201).json({ message: "Report received" });
  } catch (error) {
    console.error("Create report error:", error);
    res.status(500).json({ message: "Error sending report" });
  }
};

export const listReports = async (req, res) => {
  try {
    const status = ["OPEN", "ACTIONED", "DISMISSED"].includes(req.query.status)
      ? req.query.status
      : "OPEN";
    const reports = await prisma.report.findMany({
      where: { status },
      orderBy: { createdAt: "asc" },
      take: 200,
      include: { reporter: { select: userSelect }, reportedUser: { select: userSelect } },
    });

    const open = await prisma.report.groupBy({
      by: ["reportedUserId"],
      where: {
        status: "OPEN",
        reportedUserId: { in: [...new Set(reports.map((r) => r.reportedUserId))] },
      },
      _count: { _all: true },
    });
    const openCounts = new Map(open.map((g) => [g.reportedUserId, g._count._all]));

    res.json({
      reports: reports.map((r) => {
        const openReports = openCounts.get(r.reportedUserId) || 0;
        return { ...r, openReports, flagged: openReports >= FLAG_THRESHOLD };
      }),
    });
  } catch (error) {
    console.error("List reports error:", error);
    res.status(500).json({ message: "Error fetching reports" });
  }
};

export const resolveReport = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const report = await prisma.report.findUnique({ where: { id: req.params.id } });
    if (!report) {
      return res.status(404).json({ message: "Report not found" });
    }
    if (report.status !== "OPEN") {
      return res.status(409).json({ message: "Report already handled" });
    }

    await prisma.report.update({
      where: { id: report.id },
      data: { status: req.body.status, handledById: req.user.id, handledAt: new Date() },
    });
    res.json({ message: "Report resolved" });
  } catch (error) {
    console.error("Resolve report error:", error);
    res.status(500).json({ message: "Error resolving report" });
  }
};
