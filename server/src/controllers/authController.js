import prisma from "../prisma/client.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { validationResult } from "express-validator";
import config from "../config.js";

export const signUp = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (!config.JWT_SECRET) {
      return res.status(500).json({ message: "Server is not configured to issue sessions" });
    }

    const { email, password, name } = req.body;

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    });

    if (existingUser) {
      return res.status(400).json({ message: "User already exists" });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create user in database
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        role: "USER",
      },
    });

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      config.JWT_SECRET,
      { expiresIn: config.JWT_EXPIRES_IN }
    );

    res.status(201).json({
      message: "User created successfully",
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      token,
    });
  } catch (error) {
    console.error("Signup error:", error);
    res.status(500).json({ message: "Error creating user" });
  }
};

export const signIn = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    if (!config.JWT_SECRET) {
      return res.status(500).json({ message: "Server is not configured to issue sessions" });
    }

    const { email, password } = req.body;

    // Find user
    const user = await prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ message: "Invalid credentials" });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      config.JWT_SECRET,
      { expiresIn: config.JWT_EXPIRES_IN }
    );

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
      },
      token,
    });
  } catch (error) {
    console.error("Signin error:", error);
    res.status(500).json({ message: "Error signing in" });
  }
};

export const signOut = async (req, res) => {
  // Since we're using JWT, we don't need to do anything on the server side
  // The client should remove the token
  res.json({ message: "Signed out successfully" });
};

export const getCurrentUser = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        createdAt: true,
      },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.json(user);
  } catch (error) {
    console.error("Get current user error:", error);
    res.status(500).json({ message: "Error fetching user" });
  }
};

// GDPR access/portability: the user's profile and full check-in history as a JSON download.
// Explicit selects only; never password or qrSecret.
export const exportMyData = async (req, res) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { id: true, email: true, name: true, role: true, createdAt: true },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const checkIns = await prisma.checkIn.findMany({
      where: { userId: req.user.id },
      orderBy: { checkedInAt: "asc" },
      select: {
        id: true,
        checkedInAt: true,
        distanceMeters: true,
        verificationMethod: true,
        club: {
          select: {
            id: true,
            name: true,
            address: true,
            city: true,
            latitude: true,
            longitude: true,
          },
        },
      },
    });

    const exportedAt = new Date();
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="clubsy-export-${exportedAt.toISOString().slice(0, 10)}.json"`
    );
    res.json({ exportedAt: exportedAt.toISOString(), user, checkIns });
  } catch (error) {
    console.error("Export data error:", error);
    res.status(500).json({ message: "Error exporting data" });
  }
};

// Erases the account and its check-ins. Requires the current password.
export const deleteMyAccount = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const userId = req.user.id;
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const isValidPassword = await bcrypt.compare(req.body.password, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ message: "Invalid password" });
    }

    if (user.role === "ADMIN") {
      const admins = await prisma.user.count({ where: { role: "ADMIN" } });
      if (admins <= 1) {
        return res.status(409).json({ message: "Cannot delete the last admin" });
      }
    }

    // Every task that adds user-owned rows (favourites, friendships, reports, ...)
    // must add its table to this transaction, before the user delete.
    // When 7.7 lands, bump tokenVersion first.
    await prisma.$transaction([
      prisma.checkIn.deleteMany({ where: { userId } }),
      prisma.user.delete({ where: { id: userId } }),
    ]);

    res.status(204).send();
  } catch (error) {
    console.error("Delete account error:", error);
    res.status(500).json({ message: "Error deleting account" });
  }
};
