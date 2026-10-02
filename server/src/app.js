import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes/authRoutes.js";
import clubRoutes from "./routes/clubRoutes.js";
import checkInRoutes from "./routes/checkInRoutes.js";

dotenv.config();

const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Request logging middleware
app.use((req, res, next) => {
  console.log(`${req.method} ${req.url}`);
  next();
});

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/clubs", clubRoutes);
app.use("/api/check-ins", checkInRoutes);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// Unknown routes
app.use((req, res) => {
  res.status(404).json({ message: "Not found" });
});

// Error handling middleware
app.use((err, req, res, next) => {
  if (err.type === "entity.parse.failed") {
    return res.status(400).json({ message: "Malformed JSON body" });
  }
  console.error("Error:", err.message, err.stack);
  res.status(500).json({ message: "Something went wrong!" });
});

export default app;
