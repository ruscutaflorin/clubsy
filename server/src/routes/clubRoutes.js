import express from "express";
import { body } from "express-validator";
import {
  createClub,
  updateClub,
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
  body("imageUrl")
    .optional({ values: "falsy" })
    .isURL({ protocols: ["https"], require_protocol: true })
    .withMessage("imageUrl must be an https URL"),
];

const optionalString = (field) =>
  body(field)
    .optional()
    .isString()
    .withMessage(`${field} must be a string`)
    .bail()
    .trim()
    .notEmpty()
    .withMessage(`${field} cannot be empty`);

const clubUpdateValidation = [
  ...["qrSecret", "isApproved", "id"].map((field) =>
    body(field).not().exists().withMessage(`${field} cannot be set here`),
  ),
  optionalString("name"),
  optionalString("address"),
  optionalString("city"),
  body("latitude")
    .optional()
    .isFloat({ min: -90, max: 90 })
    .withMessage("Valid latitude is required")
    .bail()
    .toFloat(),
  body("longitude")
    .optional()
    .isFloat({ min: -180, max: 180 })
    .withMessage("Valid longitude is required")
    .bail()
    .toFloat(),
  body("imageUrl")
    .optional()
    .isURL({ protocols: ["https"], require_protocol: true })
    .withMessage("imageUrl must be an https URL"),
];

router.get("/", authMiddleware, getClubs);
router.get("/:id", authMiddleware, getClubById);
router.post("/", authMiddleware, adminMiddleware, clubValidation, createClub);
router.patch("/:id", authMiddleware, adminMiddleware, clubUpdateValidation, updateClub);
router.patch("/:id/approve", authMiddleware, adminMiddleware, approveClub);
router.patch("/:id/unapprove", authMiddleware, adminMiddleware, unapproveClub);
router.get("/:id/qr", authMiddleware, adminMiddleware, getClubQr);
router.post("/:id/qr/rotate", authMiddleware, adminMiddleware, rotateClubQr);

export default router;
