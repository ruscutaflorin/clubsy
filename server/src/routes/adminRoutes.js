import express from "express";
import {
  getMetrics,
  getScorecard,
  getClubFootfall,
  getClubRanking,
  getClubDataHealth,
} from "../controllers/adminController.js";
import { body } from "express-validator";
import { listReports, resolveReport } from "../controllers/reportController.js";
import { authMiddleware, adminMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.get("/metrics", authMiddleware, adminMiddleware, getMetrics);
router.get("/metrics/scorecard", authMiddleware, adminMiddleware, getScorecard);
router.get("/clubs/ranking", authMiddleware, adminMiddleware, getClubRanking);
router.get("/clubs/data-health", authMiddleware, adminMiddleware, getClubDataHealth);
router.get("/clubs/:id/footfall", authMiddleware, adminMiddleware, getClubFootfall);

router.get("/reports", authMiddleware, adminMiddleware, listReports);
router.post(
  "/reports/:id/resolve",
  authMiddleware,
  adminMiddleware,
  body("status").isIn(["ACTIONED", "DISMISSED"]),
  resolveReport
);

export default router;
