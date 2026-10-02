import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";
import { generateClubQr, generateQrSecret } from "../services/venueQrService.js";

// qrSecret authenticates on-site check-ins; it must never reach non-admin clients.
const forRole = (club, role) => {
  if (role === "ADMIN") return club;
  const { qrSecret, ...rest } = club;
  return rest;
};

// Shared error mapping: Prisma P2025 (record not found) is a 404, not a 500.
const handleClubError = (res, error, label, message) => {
  if (error?.code === "P2025") {
    return res.status(404).json({ message: "Club not found" });
  }
  console.error(`${label}:`, error);
  return res.status(500).json({ message });
};

const EDITABLE_FIELDS = ["name", "address", "city", "latitude", "longitude", "imageUrl"];

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

// Clamps a query param to a positive integer, falling back when it isn't one
// (missing, non-numeric, zero, or negative) - avoids NaN propagating into
// Prisma's skip/take.
const parsePositiveInt = (value, fallback) => {
  const parsed = parseInt(value, 10);
  return Number.isInteger(parsed) && parsed > 0 ? parsed : fallback;
};

export const getClubs = async (req, res) => {
  try {
    const { search, city } = req.query;
    const page = parsePositiveInt(req.query.page, 1);
    const limit = Math.min(parsePositiveInt(req.query.limit, 20), 50);
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
        take: limit,
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
    handleClubError(res, error, "Approve club error", "Error approving club");
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
    handleClubError(res, error, "Unapprove club error", "Error unapproving club");
  }
};

export const updateClub = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const data = {};
    for (const field of EDITABLE_FIELDS) {
      if (req.body[field] !== undefined) data[field] = req.body[field];
    }
    if (Object.keys(data).length === 0) {
      return res.status(400).json({ message: "No fields to update" });
    }

    const club = await prisma.club.update({ where: { id: req.params.id }, data });

    res.json(club);
  } catch (error) {
    handleClubError(res, error, "Update club error", "Error updating club");
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
