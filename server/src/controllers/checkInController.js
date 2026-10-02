import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";
import { verifyClubQrPayload } from "../services/venueQrService.js";
import { distanceInMeters } from "../utils/geo.js";
import { nightStart, nightEnd } from "../utils/night.js";
import { computeCheckInStats } from "../services/statsService.js";

const MAX_CHECK_IN_DISTANCE_METERS = 150;

const logFailure = (reason, userId, clubId) =>
  console.warn(JSON.stringify({ evt: "checkin_failed", reason, userId, clubId }));

export const checkIn = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { clubId, qrPayload, latitude, longitude, isMocked } = req.body;
    const userId = req.user.id;

    // Checked before anything else so the attempt reveals nothing about the QR.
    if (isMocked === true) {
      logFailure("mock_location", userId, clubId);
      return res.status(400).json({ message: "Mock locations aren't allowed for check-ins" });
    }

    const club = await prisma.club.findUnique({ where: { id: clubId } });

    if (!club || !club.isApproved) {
      logFailure("club_not_found", userId, clubId);
      return res.status(404).json({ message: "Club not found" });
    }

    if (!verifyClubQrPayload(qrPayload, club)) {
      logFailure("invalid_qr", userId, clubId);
      return res.status(400).json({ message: "Invalid QR code for this club" });
    }

    const distance = distanceInMeters(latitude, longitude, club.latitude, club.longitude);

    if (distance > MAX_CHECK_IN_DISTANCE_METERS) {
      logFailure("too_far", userId, clubId);
      return res.status(400).json({
        message: "You're too far from this club to check in",
        distanceMeters: distance,
      });
    }

    const now = new Date();
    const existingTonight = await prisma.checkIn.findFirst({
      where: {
        userId,
        clubId,
        checkedInAt: { gte: nightStart(now), lt: nightEnd(now) },
      },
    });

    if (existingTonight) {
      logFailure("already_checked_in", userId, clubId);
      return res.status(409).json({ message: "You've already checked in at this club tonight" });
    }

    const checkInRecord = await prisma.checkIn.create({
      data: {
        userId,
        clubId,
        verificationMethod: "QR",
        distanceMeters: distance,
      },
      include: { club: true },
    });

    res.status(201).json(checkInRecord);
  } catch (error) {
    console.error("Check in error:", error);
    res.status(500).json({ message: "Error checking in" });
  }
};

export const getMyCheckIns = async (req, res) => {
  try {
    const checkIns = await prisma.checkIn.findMany({
      where: { userId: req.user.id },
      include: { club: true },
      orderBy: { checkedInAt: "desc" },
    });

    res.json({ checkIns });
  } catch (error) {
    console.error("Get check-ins error:", error);
    res.status(500).json({ message: "Error fetching check-ins" });
  }
};

export const deleteCheckIn = async (req, res) => {
  try {
    const checkInRecord = await prisma.checkIn.findUnique({ where: { id: req.params.id } });

    // Same 404 for "missing" and "someone else's" so ids can't be probed.
    if (!checkInRecord || checkInRecord.userId !== req.user.id) {
      return res.status(404).json({ message: "Check-in not found" });
    }

    await prisma.checkIn.delete({ where: { id: checkInRecord.id } });
    res.status(204).send();
  } catch (error) {
    console.error("Delete check-in error:", error);
    res.status(500).json({ message: "Error deleting check-in" });
  }
};

export const getMyCheckInStats = async (req, res) => {
  try {
    const checkIns = await prisma.checkIn.findMany({
      where: { userId: req.user.id },
      include: { club: true },
    });

    res.json(computeCheckInStats(checkIns));
  } catch (error) {
    console.error("Get check-in stats error:", error);
    res.status(500).json({ message: "Error fetching check-in stats" });
  }
};
