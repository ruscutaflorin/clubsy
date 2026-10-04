import express from "express";
import { body } from "express-validator";
import { blockUser, listBlocks, unblockUser } from "../controllers/blockController.js";
import { createReport, REPORT_REASONS } from "../controllers/reportController.js";
import { authMiddleware } from "../middlewares/authMiddleware.js";

export const blockRouter = express.Router();
blockRouter.get("/", authMiddleware, listBlocks);
blockRouter.post("/", authMiddleware, body("userId").isString().notEmpty(), blockUser);
blockRouter.delete("/:userId", authMiddleware, unblockUser);

export const reportRouter = express.Router();
reportRouter.post(
  "/",
  authMiddleware,
  [
    body("userId").isString().notEmpty(),
    body("reason").isIn(REPORT_REASONS).withMessage("Invalid reason"),
    body("details").optional({ nullable: true }).isString().trim().isLength({ max: 500 }),
  ],
  createReport
);
