import prisma from "../prisma/client.js";
import { validationResult } from "express-validator";
import { visibleToUser } from "../utils/blocks.js";

const userSelect = { id: true, username: true, name: true };

// Same body for every outcome of a send (unknown user, duplicate, auto-accept) so the
// response can't be used to probe which usernames exist.
const REQUEST_ACCEPTED = { message: "If that username exists, a friend request has been sent" };

export const sendFriendRequest = async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const me = req.user.id;
    const target = await prisma.user.findFirst({
      where: { username: req.body.username, ...visibleToUser(me) },
      select: { id: true },
    });

    if (target && target.id === me) {
      return res.status(400).json({ message: "You can't send a friend request to yourself" });
    }

    if (target) {
      const existing = await prisma.friendship.findFirst({
        where: {
          OR: [
            { requesterId: me, addresseeId: target.id },
            { requesterId: target.id, addresseeId: me },
          ],
        },
      });

      if (!existing) {
        await prisma.friendship.create({ data: { requesterId: me, addresseeId: target.id } });
      } else if (existing.status === "PENDING" && existing.requesterId === target.id) {
        await prisma.friendship.update({
          where: { id: existing.id },
          data: { status: "ACCEPTED", respondedAt: new Date() },
        });
      }
      // Already pending from me, or already friends: nothing to do.
    }

    res.status(202).json(REQUEST_ACCEPTED);
  } catch (error) {
    console.error("Send friend request error:", error);
    res.status(500).json({ message: "Error sending friend request" });
  }
};

export const listFriends = async (req, res) => {
  try {
    const me = req.user.id;
    const rows = await prisma.friendship.findMany({
      where: {
        OR: [{ requesterId: me }, { addresseeId: me }],
        requester: visibleToUser(me),
        addressee: visibleToUser(me),
      },
      orderBy: { createdAt: "desc" },
      include: { requester: { select: userSelect }, addressee: { select: userSelect } },
    });

    const friends = [];
    const incoming = [];
    const outgoing = [];
    for (const row of rows) {
      const mine = row.requesterId === me;
      const entry = {
        id: row.id,
        user: mine ? row.addressee : row.requester,
        createdAt: row.createdAt,
      };
      if (row.status === "ACCEPTED") friends.push(entry);
      else (mine ? outgoing : incoming).push(entry);
    }

    res.json({ friends, incoming, outgoing });
  } catch (error) {
    console.error("List friends error:", error);
    res.status(500).json({ message: "Error fetching friends" });
  }
};

export const acceptFriendRequest = async (req, res) => {
  try {
    const row = await prisma.friendship.findUnique({ where: { id: req.params.id } });
    if (!row || row.addresseeId !== req.user.id || row.status !== "PENDING") {
      return res.status(404).json({ message: "Friend request not found" });
    }
    await prisma.friendship.update({
      where: { id: row.id },
      data: { status: "ACCEPTED", respondedAt: new Date() },
    });
    res.json({ message: "Friend request accepted" });
  } catch (error) {
    console.error("Accept friend request error:", error);
    res.status(500).json({ message: "Error accepting friend request" });
  }
};

// Deletes a friendship row. `allowed` says who may do it and in which status:
// decline (addressee, pending), cancel (requester, pending), unfriend (either, accepted).
const removeRow = (allowed, notFound, done) => async (req, res) => {
  try {
    const row = await prisma.friendship.findUnique({ where: { id: req.params.id } });
    if (!row || !allowed(row, req.user.id)) {
      return res.status(404).json({ message: notFound });
    }
    await prisma.friendship.delete({ where: { id: row.id } });
    res.json({ message: done });
  } catch (error) {
    console.error("Remove friendship error:", error);
    res.status(500).json({ message: "Error updating friendship" });
  }
};

export const declineFriendRequest = removeRow(
  (r, me) => r.status === "PENDING" && r.addresseeId === me,
  "Friend request not found",
  "Friend request declined"
);

export const cancelFriendRequest = removeRow(
  (r, me) => r.status === "PENDING" && r.requesterId === me,
  "Friend request not found",
  "Friend request cancelled"
);

export const unfriend = removeRow(
  (r, me) => r.status === "ACCEPTED" && (r.requesterId === me || r.addresseeId === me),
  "Friend not found",
  "Friend removed"
);
