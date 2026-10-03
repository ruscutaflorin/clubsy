import express from "express";
import { body } from "express-validator";
import {
  checkIn,
  deleteCheckIn,
  getMyAchievements,
  getMyCheckIns,
  getMyCheckInStats,
  getMyCityProgress,
} from "../controllers/checkInController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";
import { checkInLimiter } from "../middlewares/rateLimiters.js";

const router = express.Router();

const checkInValidation = [
  body("clubId").notEmpty().withMessage("clubId is required"),
  body("qrPayload").notEmpty().withMessage("qrPayload is required"),
  body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Valid latitude is required"),
  body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Valid longitude is required"),
  body("isMocked").optional().isBoolean({ strict: true }).withMessage("isMocked must be a boolean"),
  body("accuracyMeters")
    .optional()
    .isFloat({ min: 0 })
    .withMessage("accuracyMeters must be a number >= 0"),
];

router.post("/", authMiddleware, checkInLimiter, checkInValidation, checkIn);
router.get("/me/achievements", authMiddleware, getMyAchievements);
router.get("/me/cities", authMiddleware, getMyCityProgress);
router.get("/me/stats", authMiddleware, getMyCheckInStats);
router.get("/me", authMiddleware, getMyCheckIns);
router.delete("/:id", authMiddleware, deleteCheckIn);

export default router;
