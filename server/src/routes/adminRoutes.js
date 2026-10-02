import express from "express";
import { getMetrics, getScorecard, getClubFootfall } from "../controllers/adminController.js";
import { authMiddleware, adminMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.get("/metrics", authMiddleware, adminMiddleware, getMetrics);
router.get("/metrics/scorecard", authMiddleware, adminMiddleware, getScorecard);
router.get("/clubs/:id/footfall", authMiddleware, adminMiddleware, getClubFootfall);

export default router;
