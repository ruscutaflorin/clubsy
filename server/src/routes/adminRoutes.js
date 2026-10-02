import express from "express";
import {
  getMetrics,
  getScorecard,
  getClubFootfall,
  getClubRanking,
  getClubDataHealth,
} from "../controllers/adminController.js";
import { authMiddleware, adminMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.get("/metrics", authMiddleware, adminMiddleware, getMetrics);
router.get("/metrics/scorecard", authMiddleware, adminMiddleware, getScorecard);
router.get("/clubs/ranking", authMiddleware, adminMiddleware, getClubRanking);
router.get("/clubs/data-health", authMiddleware, adminMiddleware, getClubDataHealth);
router.get("/clubs/:id/footfall", authMiddleware, adminMiddleware, getClubFootfall);

export default router;
