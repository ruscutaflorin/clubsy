import express from "express";
import { getDisplayPage, getDisplayQr } from "../controllers/venueDisplayController.js";

const router = express.Router();

router.get("/:clubId/qr", getDisplayQr);
router.get("/:clubId", getDisplayPage);

export default router;
