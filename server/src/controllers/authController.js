import prisma from "../prisma/client.js";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { validationResult } from "express-validator";
import crypto from "node:crypto";
import config from "../config.js";
import { getEmailSender } from "../services/emailService.js";

const issueToken = (user) =>
  jwt.sign(
    { userId: user.id, email: user.email, role: user.role, tv: user.tokenVersion ?? 0 },
    config.JWT_SECRET,
    { expiresIn: config.JWT_EXPIRES_IN }
  );

const profileSelect = {
  username: true,
  homeCity: true,
  acceptedTermsAt: true,
  termsVersion: true,
  ageConfirmedAt: true,
};

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

    // Create user in database; consent is validated by the route and stamped here
    const now = new Date();
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        role: "USER",
        acceptedTermsAt: now,
        termsVersion: config.TERMS_VERSION,
        ageConfirmedAt: now,
      },
    });

    // Generate JWT token
    const token = issueToken(user);

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
    const token = issueToken(user);

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

// Invalidates every token issued so far, including the caller's.
export const signOutAll = async (req, res) => {
  try {
    await prisma.user.update({
      where: { id: req.user.id },
      data: { tokenVersion: { increment: 1 } },
    });
    res.json({ message: "Signed out of all devices" });
  } catch (error) {
    console.error("Sign out all error:", error);
    res.status(500).json({ message: "Error signing out" });
  }
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
        ...profileSelect,
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

// Changes the password of the signed-in user. Requires the current password.
export const changePassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { currentPassword, newPassword } = req.body;
    const user = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const isValidPassword = await bcrypt.compare(currentPassword, user.password);
    if (!isValidPassword) {
      return res.status(401).json({ message: "Invalid password" });
    }

    if (newPassword === currentPassword) {
      return res
        .status(400)
        .json({ message: "New password must be different from the current one" });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: await bcrypt.hash(newPassword, 10),
        tokenVersion: { increment: 1 },
      },
    });

    // Other devices are signed out; this one gets a fresh token.
    res.json({
      message: "Password changed",
      token: issueToken({ ...user, tokenVersion: (user.tokenVersion ?? 0) + 1 }),
    });
  } catch (error) {
    console.error("Change password error:", error);
    res.status(500).json({ message: "Error changing password" });
  }
};

// Updates name, username and homeCity of the signed-in user. Only the fields sent are written.
export const updateMyProfile = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const existing = await prisma.user.findUnique({ where: { id: req.user.id } });
    if (!existing) {
      return res.status(404).json({ message: "User not found" });
    }

    const data = {};
    if (req.body.name !== undefined) data.name = req.body.name;
    if (req.body.homeCity !== undefined) data.homeCity = req.body.homeCity || null;
    if (req.body.username !== undefined) {
      data.username = req.body.username;
      const taken = await prisma.user.findFirst({
        where: {
          username: { equals: data.username, mode: "insensitive" },
          NOT: { id: req.user.id },
        },
        select: { id: true },
      });
      if (taken) {
        return res.status(409).json({ message: "Username is already taken" });
      }
    }

    const user = await prisma.user.update({
      where: { id: req.user.id },
      data,
      select: { id: true, email: true, name: true, role: true, ...profileSelect },
    });

    res.json({ user });
  } catch (error) {
    if (error?.code === "P2002") {
      return res.status(409).json({ message: "Username is already taken" });
    }
    console.error("Update profile error:", error);
    res.status(500).json({ message: "Error updating profile" });
  }
};

// Live availability check for the edit-profile form. The caller's own username counts as free.
export const checkUsernameAvailable = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const taken = await prisma.user.findFirst({
      where: {
        username: { equals: req.query.u, mode: "insensitive" },
        NOT: { id: req.user.id },
      },
      select: { id: true },
    });
    res.json({ available: !taken });
  } catch (error) {
    console.error("Username check error:", error);
    res.status(500).json({ message: "Error checking username" });
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
    await prisma.$transaction([
      prisma.user.update({ where: { id: userId }, data: { tokenVersion: { increment: 1 } } }),
      prisma.checkIn.deleteMany({ where: { userId } }),
      prisma.favorite.deleteMany({ where: { userId } }),
      prisma.user.delete({ where: { id: userId } }),
    ]);

    res.status(204).send();
  } catch (error) {
    console.error("Delete account error:", error);
    res.status(500).json({ message: "Error deleting account" });
  }
};

const RESET_CODE_TTL_MS = 15 * 60 * 1000;

const hashCode = (code) => crypto.createHash("sha256").update(code).digest("hex");

// Always 202, whether or not the email belongs to an account.
export const forgotPassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const user = await prisma.user.findUnique({ where: { email: req.body.email } });
    if (user) {
      const code = crypto.randomInt(0, 1000000).toString().padStart(6, "0");
      // Only the newest code works.
      await prisma.passwordResetToken.updateMany({
        where: { userId: user.id, usedAt: null },
        data: { usedAt: new Date() },
      });
      await prisma.passwordResetToken.create({
        data: {
          userId: user.id,
          tokenHash: hashCode(code),
          expiresAt: new Date(Date.now() + RESET_CODE_TTL_MS),
        },
      });
      await getEmailSender().send({
        to: user.email,
        subject: "Your Clubsy password reset code",
        text: `Your Clubsy password reset code is ${code}. It expires in 15 minutes. If you didn't ask for it, ignore this email.`,
      });
    }
  } catch (error) {
    // Don't leak account existence through failures either.
    console.error("Forgot password error:", error);
  }
  res.status(202).json({ message: "If that email has an account, a code is on its way" });
};

export const resetPassword = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, code, newPassword } = req.body;
    const invalid = () => res.status(400).json({ message: "Invalid or expired code" });

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) return invalid();

    const token = await prisma.passwordResetToken.findFirst({
      where: {
        userId: user.id,
        tokenHash: hashCode(code),
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (!token) return invalid();

    // Claim the token atomically so concurrent requests can't both use it.
    const claimed = await prisma.passwordResetToken.updateMany({
      where: { id: token.id, usedAt: null },
      data: { usedAt: new Date() },
    });
    if (claimed.count !== 1) return invalid();

    await prisma.user.update({
      where: { id: user.id },
      data: {
        password: await bcrypt.hash(newPassword, 10),
        tokenVersion: { increment: 1 },
      },
    });

    res.json({ message: "Password reset" });
  } catch (error) {
    console.error("Reset password error:", error);
    res.status(500).json({ message: "Error resetting password" });
  }
};
