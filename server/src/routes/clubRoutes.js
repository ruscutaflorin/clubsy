import express from "express";
import { body } from "express-validator";
import {
  createClub,
  getClubs,
  getClubById,
  approveClub,
  unapproveClub,
  getClubQr,
  rotateClubQr,
} from "../controllers/clubController.js";
import { authMiddleware, adminMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

const clubValidation = [
  body("name").notEmpty().withMessage("Name is required"),
  body("address").notEmpty().withMessage("Address is required"),
  body("city").notEmpty().withMessage("City is required"),
  body("latitude").isFloat({ min: -90, max: 90 }).withMessage("Valid latitude is required"),
  body("longitude").isFloat({ min: -180, max: 180 }).withMessage("Valid longitude is required"),
];

router.get("/", authMiddleware, getClubs);
router.get("/:id", authMiddleware, getClubById);
router.post("/", authMiddleware, adminMiddleware, clubValidation, createClub);
router.patch("/:id/approve", authMiddleware, adminMiddleware, approveClub);
router.patch("/:id/unapprove", authMiddleware, adminMiddleware, unapproveClub);
router.get("/:id/qr", authMiddleware, adminMiddleware, getClubQr);
router.post("/:id/qr/rotate", authMiddleware, adminMiddleware, rotateClubQr);

export default router;
