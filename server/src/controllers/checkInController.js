import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";
import { verifyClubQrPayload } from "../services/venueQrService.js";
import { distanceInMeters } from "../utils/geo.js";
import { nightStart, nightEnd } from "../utils/night.js";

const MAX_CHECK_IN_DISTANCE_METERS = 150;

export const checkIn = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { clubId, qrPayload, latitude, longitude } = req.body;
    const userId = req.user.id;

    const club = await prisma.club.findUnique({ where: { id: clubId } });

    if (!club || !club.isApproved) {
      return res.status(404).json({ message: "Club not found" });
    }

    if (!verifyClubQrPayload(qrPayload, club)) {
      return res.status(400).json({ message: "Invalid QR code for this club" });
    }

    const distance = distanceInMeters(latitude, longitude, club.latitude, club.longitude);

    if (distance > MAX_CHECK_IN_DISTANCE_METERS) {
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
