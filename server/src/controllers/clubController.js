import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";
import { generateClubQr, generateQrSecret } from "../services/venueQrService.js";

// qrSecret authenticates on-site check-ins; it must never reach non-admin clients.
const forRole = (club, role) => {
  if (role === "ADMIN") return club;
  const { qrSecret, ...rest } = club;
  return rest;
};

export const createClub = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, address, city, latitude, longitude, imageUrl } = req.body;

    const club = await prisma.club.create({
      data: {
        name,
        address,
        city,
        latitude,
        longitude,
        imageUrl: imageUrl || undefined,
        qrSecret: generateQrSecret(),
      },
    });

    const qrCode = await generateClubQr(club);

    res.status(201).json({ ...club, qrCode });
  } catch (error) {
    console.error("Create club error:", error);
    res.status(500).json({ message: "Error creating club" });
  }
};

export const getClubs = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, city } = req.query;
    const skip = (page - 1) * limit;

    const where = {
      ...(req.user?.role !== "ADMIN" && { isApproved: true }),
      ...(city && { city: { equals: city, mode: "insensitive" } }),
      ...(search && {
        OR: [
          { name: { contains: search, mode: "insensitive" } },
          { address: { contains: search, mode: "insensitive" } },
          { city: { contains: search, mode: "insensitive" } },
        ],
      }),
    };

    const [clubs, total] = await Promise.all([
      prisma.club.findMany({
        where,
        skip,
        take: parseInt(limit),
        orderBy: { name: "asc" },
      }),
      prisma.club.count({ where }),
    ]);

    res.json({
      clubs: clubs.map((club) => forRole(club, req.user?.role)),
      total,
      pages: Math.ceil(total / limit),
    });
  } catch (error) {
    console.error("Get clubs error:", error);
    res.status(500).json({ message: "Error fetching clubs" });
  }
};

export const getClubById = async (req, res) => {
  try {
    const { id } = req.params;

    const club = await prisma.club.findUnique({ where: { id } });

    if (!club || (!club.isApproved && req.user?.role !== "ADMIN")) {
      return res.status(404).json({ message: "Club not found" });
    }

    res.json(forRole(club, req.user?.role));
  } catch (error) {
    console.error("Get club error:", error);
    res.status(500).json({ message: "Error fetching club" });
  }
};

export const approveClub = async (req, res) => {
  try {
    const { id } = req.params;

    const club = await prisma.club.update({
      where: { id },
      data: { isApproved: true },
    });

    res.json(club);
  } catch (error) {
    console.error("Approve club error:", error);
    res.status(500).json({ message: "Error approving club" });
  }
};

export const unapproveClub = async (req, res) => {
  try {
    const { id } = req.params;

    const club = await prisma.club.update({
      where: { id },
      data: { isApproved: false },
    });

    res.json(club);
  } catch (error) {
    console.error("Unapprove club error:", error);
    res.status(500).json({ message: "Error unapproving club" });
  }
};

export const getClubQr = async (req, res) => {
  try {
    const { id } = req.params;

    const club = await prisma.club.findUnique({ where: { id } });

    if (!club) {
      return res.status(404).json({ message: "Club not found" });
    }

    const qrCode = await generateClubQr(club);

    res.json({ qrCode });
  } catch (error) {
    console.error("Get club QR error:", error);
    res.status(500).json({ message: "Error fetching club QR" });
  }
};

export const rotateClubQr = async (req, res) => {
  try {
    const { id } = req.params;

    const club = await prisma.club.findUnique({ where: { id } });

    if (!club) {
      return res.status(404).json({ message: "Club not found" });
    }

    const rotated = await prisma.club.update({
      where: { id },
      data: { qrSecret: generateQrSecret() },
    });

    const qrCode = await generateClubQr(rotated);

    res.json({ qrCode });
  } catch (error) {
    console.error("Rotate club QR error:", error);
    res.status(500).json({ message: "Error rotating club QR" });
  }
};
