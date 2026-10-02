import rateLimit from "express-rate-limit";
import config from "../config.js";

const tooMany = (message) => ({ message });

// Keyed by IP (the default key generator).
export const authLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: config.RATE_LIMIT_AUTH_PER_MIN,
  standardHeaders: true,
  legacyHeaders: false,
  message: tooMany("Too many attempts, try again in a minute"),
});

// Mount after authMiddleware: keyed by the signed-in user.
export const checkInLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: config.RATE_LIMIT_CHECKIN_PER_MIN,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user.id,
  message: tooMany("Too many check-in attempts, try again in a minute"),
});
