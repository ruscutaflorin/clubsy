import express from "express";
import { body } from "express-validator";
import { checkIn, getMyCheckIns } from "../controllers/checkInController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

const checkInValidation = [
  body("clubId").notEmpty().withMessage("clubId is required"),
  body("qrPayload").notEmpty().withMessage("qrPayload is required"),
  body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Valid latitude is required"),
  body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Valid longitude is required"),
];

router.post("/", authMiddleware, checkInValidation, checkIn);
router.get("/me", authMiddleware, getMyCheckIns);

export default router;
