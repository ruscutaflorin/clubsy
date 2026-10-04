import express from "express";
import { getClubFriendCount, getFeed } from "../controllers/feedController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.get("/", authMiddleware, getFeed);
router.get("/clubs/:clubId/friends-count", authMiddleware, getClubFriendCount);

export default router;
