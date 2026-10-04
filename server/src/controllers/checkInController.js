import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";
import { verifyClubQrPayload } from "../services/venueQrService.js";
import { distanceInMeters, MAX_CHECK_IN_DISTANCE_METERS } from "../utils/geo.js";
import { isImpossibleTravel } from "../utils/travel.js";
import { nightStart, nightEnd } from "../utils/night.js";
import { computeCheckInStats, computeCityProgress } from "../services/statsService.js";
import { computeAchievements } from "../services/gamificationService.js";

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

    const previous = await prisma.checkIn.findFirst({
      where: { userId },
      orderBy: { checkedInAt: "desc" },
      include: { club: true },
    });

    if (
      previous &&
      isImpossibleTravel(
        {
          latitude: previous.club.latitude,
          longitude: previous.club.longitude,
          at: previous.checkedInAt,
        },
        { latitude: club.latitude, longitude: club.longitude, at: now }
      )
    ) {
      logFailure("implausible_travel", userId, clubId);
      return res
        .status(400)
        .json({ message: "This check-in doesn't match your previous one. Try again later." });
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

const VIBE_EDIT_WINDOW_MS = 7 * 24 * 60 * 60 * 1000;

export const updateCheckIn = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const checkInRecord = await prisma.checkIn.findUnique({ where: { id: req.params.id } });

    if (!checkInRecord || checkInRecord.userId !== req.user.id) {
      return res.status(404).json({ message: "Check-in not found" });
    }

    const { note, vibe, hiddenFromFriends } = req.body;
    const data = {};
    if (hiddenFromFriends !== undefined) data.hiddenFromFriends = hiddenFromFriends;
    if (note !== undefined) data.note = note === null || note.trim() === "" ? null : note.trim();
    if (vibe !== undefined) {
      if (Date.now() - new Date(checkInRecord.checkedInAt).getTime() > VIBE_EDIT_WINDOW_MS) {
        return res.status(409).json({ message: "Ratings can only be changed within 7 days" });
      }
      data.vibe = vibe;
      data.vibeAt = vibe === null ? null : new Date();
    }

    const updated = await prisma.checkIn.update({
      where: { id: checkInRecord.id },
      data,
      include: { club: true },
    });
    res.json(updated);
  } catch (error) {
    console.error("Update check-in error:", error);
    res.status(500).json({ message: "Error updating check-in" });
  }
};

export const getMyAchievements =async (req, res) => {
  try {
    const checkIns = await prisma.checkIn.findMany({
      where: { userId: req.user.id },
      include: { club: true },
    });

    res.json(computeAchievements(checkIns, new Date()));
  } catch (error) {
    console.error("Get achievements error:", error);
    res.status(500).json({ message: "Error fetching achievements" });
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

export const getMyCityProgress = async (req, res) => {
  try {
    const [checkIns, approvedClubs] = await Promise.all([
      prisma.checkIn.findMany({
        where: { userId: req.user.id },
        include: { club: true },
      }),
      prisma.club.findMany({
        where: { isApproved: true },
        select: { id: true, city: true },
      }),
    ]);

    res.json(computeCityProgress(checkIns, approvedClubs));
  } catch (error) {
    console.error("Get city progress error:", error);
    res.status(500).json({ message: "Error fetching city progress" });
  }
};
