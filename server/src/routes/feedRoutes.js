import express from "express";
import {
  getClubFriendCount,
  getFeed,
  getFriendNights,
} from "../controllers/feedController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.get("/", authMiddleware, getFeed);
router.get("/friends/:userId", authMiddleware, getFriendNights);
router.get("/clubs/:clubId/friends-count", authMiddleware, getClubFriendCount);

export default router;
