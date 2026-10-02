import express from "express";
import cors from "cors";
import helmet from "helmet";
import config from "./config.js";
import prisma from "./prisma/client.js";
import authRoutes from "./routes/authRoutes.js";
import clubRoutes from "./routes/clubRoutes.js";
import checkInRoutes from "./routes/checkInRoutes.js";
import adminRoutes from "./routes/adminRoutes.js";
import venueDisplayRoutes from "./routes/venueDisplayRoutes.js";

const app = express();

// Behind the host's proxy the client IP comes from X-Forwarded-For (rate limits key on it).
if (config.IS_PRODUCTION) app.set("trust proxy", 1);

// Middleware
app.use(helmet());
app.use(
  cors({
    // Requests without an Origin (mobile app, curl) aren't browser cross-origin calls.
    origin: (origin, callback) =>
      callback(
        null,
        !origin || config.CORS_ORIGINS === null || config.CORS_ORIGINS.includes(origin)
      ),
  })
);
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
app.use("/api/admin", adminRoutes);
app.use("/venue-display", venueDisplayRoutes);

// Health check
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// Readiness check: verifies the database answers within 2 s
app.get("/health/ready", async (req, res) => {
  let timer;
  try {
    await Promise.race([
      prisma.$queryRaw`SELECT 1`,
      new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error("timeout")), 2000);
      }),
    ]);
    res.json({ status: "ok" });
  } catch (err) {
    console.error("Readiness check failed:", err.message);
    res.status(503).json({ status: "unavailable" });
  } finally {
    clearTimeout(timer);
  }
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
