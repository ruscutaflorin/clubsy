import express from "express";
import { body } from "express-validator";
import {
  acceptFriendRequest,
  cancelFriendRequest,
  declineFriendRequest,
  listFriends,
  sendFriendRequest,
  unfriend,
} from "../controllers/friendController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { friendRequestLimiter } from "../middlewares/rateLimiters.js";

const router = express.Router();

// Exact username only (stored lowercase); never partial matches or email lookups.
const requestValidation = [
  body("username")
    .isString()
    .trim()
    .toLowerCase()
    .matches(/^[a-z0-9_]{3,20}$/)
    .withMessage("Username must be 3-20 characters: letters, digits or _"),
];

router.get("/", authMiddleware, listFriends);
router.post("/requests", authMiddleware, friendRequestLimiter, requestValidation, sendFriendRequest);
router.post("/requests/:id/accept", authMiddleware, acceptFriendRequest);
router.post("/requests/:id/decline", authMiddleware, declineFriendRequest);
router.delete("/requests/:id", authMiddleware, cancelFriendRequest);
router.delete("/:id", authMiddleware, unfriend);

export default router;
