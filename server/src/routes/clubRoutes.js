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
  getDisplayLink,
} from "../controllers/clubController.js";
import { GENRES } from "../utils/genres.js";
import { openingHoursError } from "../utils/openingHours.js";
import { authMiddleware, adminMiddleware } from "../middlewares/authMiddleware.js";

const router = express.Router();

const validTimezone = (value) => {
  try {
    new Intl.DateTimeFormat("en-US", { timeZone: value });
    return typeof value === "string" && value.length > 0;
  } catch {
    return false;
  }
};

// Optional profile fields shared by create and PATCH. null (or "" for URLs)
// clears a field.
const profileValidation = [
  body("description")
    .optional({ values: "null" })
    .isString()
    .withMessage("description must be a string")
    .bail()
    .isLength({ max: 500 })
    .withMessage("description must be at most 500 characters"),
  body("genres")
    .optional()
    .isArray()
    .withMessage("genres must be a list")
    .bail()
    .custom((genres) => genres.every((g) => GENRES.includes(g)))
    .withMessage(`genres must be from: ${GENRES.join(", ")}`),
  body("openingHours")
    .optional({ values: "undefined" })
    .custom((value) => {
      const error = openingHoursError(value);
      if (error) throw new Error(error);
      return true;
    }),
  ...["instagramUrl", "websiteUrl"].map((field) =>
    body(field)
      .optional({ values: "falsy" })
      .isURL({ protocols: ["https"], require_protocol: true })
      .withMessage(`${field} must be an https URL`),
  ),
  body("timezone")
    .optional()
    .custom(validTimezone)
    .withMessage("timezone must be a valid IANA timezone"),
];

const clubValidation = [
  ...profileValidation,
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
  ...profileValidation,
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
router.get("/:id/display-link", authMiddleware, adminMiddleware, getDisplayLink);
router.post("/:id/qr/rotate", authMiddleware, adminMiddleware, rotateClubQr);

export default router;
