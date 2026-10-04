import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";

export const blockUser = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const me = req.user.id;
    const { userId } = req.body;
    if (userId === me) {
      return res.status(400).json({ message: "You can't block yourself" });
    }

    const target = await prisma.user.findUnique({ where: { id: userId }, select: { id: true } });
    if (!target) {
      return res.status(404).json({ message: "User not found" });
    }

    // Blocking ends any friendship or pending request, in either direction. Unblocking
    // later does not bring it back.
    await prisma.friendship.deleteMany({
      where: {
        OR: [
          { requesterId: me, addresseeId: userId },
          { requesterId: userId, addresseeId: me },
        ],
      },
    });
    await prisma.block.upsert({
      where: { blockerId_blockedId: { blockerId: me, blockedId: userId } },
      create: { blockerId: me, blockedId: userId },
      update: {},
    });

    res.status(201).json({ message: "User blocked" });
  } catch (error) {
    console.error("Block user error:", error);
    res.status(500).json({ message: "Error blocking user" });
  }
};

export const unblockUser = async (req, res) => {
  try {
    await prisma.block.deleteMany({
      where: { blockerId: req.user.id, blockedId: req.params.userId },
    });
    res.json({ message: "User unblocked" });
  } catch (error) {
    console.error("Unblock user error:", error);
    res.status(500).json({ message: "Error unblocking user" });
  }
};

export const listBlocks = async (req, res) => {
  try {
    const rows = await prisma.block.findMany({
      where: { blockerId: req.user.id },
      orderBy: { createdAt: "desc" },
      include: { blocked: { select: { id: true, username: true, name: true } } },
    });
    res.json({
      blocked: rows.map((r) => ({ id: r.id, user: r.blocked, createdAt: r.createdAt })),
    });
  } catch (error) {
    console.error("List blocks error:", error);
    res.status(500).json({ message: "Error fetching blocked users" });
  }
};
