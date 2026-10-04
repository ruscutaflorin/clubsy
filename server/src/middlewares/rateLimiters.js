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
export const usernameCheckLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: config.RATE_LIMIT_USERNAME_CHECK_PER_MIN,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.user.id,
  message: tooMany("Too many username checks, try again in a minute"),
});

const passwordResetOptions = {
  windowMs: 60 * 60 * 1000,
  standardHeaders: true,
  legacyHeaders: false,
  message: tooMany("Too many password reset attempts, try again later"),
};

// Password reset endpoints are limited per IP and, separately, per target email.
export const passwordResetIpLimiter = rateLimit({
  ...passwordResetOptions,
  limit: config.RATE_LIMIT_PASSWORD_RESET_IP_PER_HOUR,
});
export const passwordResetEmailLimiter = rateLimit({
  ...passwordResetOptions,
  limit: config.RATE_LIMIT_PASSWORD_RESET_PER_HOUR,
  keyGenerator: (req) => `email:${String(req.body?.email ?? "").trim().toLowerCase()}`,
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
