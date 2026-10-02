import express from "express";
import { getMetrics } from "../controllers/adminController.js";
import { authMiddleware, adminMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

router.get("/metrics", authMiddleware, adminMiddleware, getMetrics);

export default router;
