import dotenv from "dotenv";

dotenv.config();

const toInt = (value, fallback) => {
  const n = Number.parseInt(value, 10);
  return Number.isFinite(n) && n > 0 ? n : fallback;
};

export function loadConfig(env = process.env) {
  const NODE_ENV = env.NODE_ENV || "development";
  const corsList = (env.CORS_ORIGINS || "")
    .split(",")
    .map((o) => o.trim())
    .filter(Boolean);

  if (NODE_ENV === "production") {
    const missing = ["RESEND_API_KEY", "EMAIL_FROM"].filter((k) => !env[k]);
    if (missing.length > 0) {
      throw new Error(`Missing required environment variables: ${missing.join(", ")}`);
    }
  }

  return {
    RESEND_API_KEY: env.RESEND_API_KEY || null,
    EMAIL_FROM: env.EMAIL_FROM || "Clubsy <noreply@localhost>",
    RATE_LIMIT_PASSWORD_RESET_PER_HOUR: toInt(env.RATE_LIMIT_PASSWORD_RESET_PER_HOUR, 5),
    RATE_LIMIT_PASSWORD_RESET_IP_PER_HOUR: toInt(env.RATE_LIMIT_PASSWORD_RESET_IP_PER_HOUR, 20),
    PORT: toInt(env.PORT, 3000),
    NODE_ENV,
    IS_PRODUCTION: NODE_ENV === "production",
    // Read lazily so the secret can be set after this module loads (tests).
    get JWT_SECRET() {
      return env.JWT_SECRET;
    },
    JWT_EXPIRES_IN: env.JWT_EXPIRES_IN || "30d",
    // null means "allow all"; an empty array means "allow none".
    CORS_ORIGINS: corsList.length > 0 ? corsList : NODE_ENV === "production" ? [] : null,
    RATE_LIMIT_AUTH_PER_MIN: toInt(env.RATE_LIMIT_AUTH_PER_MIN, 10),
    RATE_LIMIT_CHECKIN_PER_MIN: toInt(env.RATE_LIMIT_CHECKIN_PER_MIN, 6),
    RATE_LIMIT_USERNAME_CHECK_PER_MIN: 30,
    RATE_LIMIT_FRIEND_REQUESTS_PER_DAY: 20,
    // Bump when the Terms or Privacy Policy change materially.
    TERMS_VERSION: "2026-10-draft",
    PRISMA_LOG_QUERIES: env.PRISMA_LOG_QUERIES === "1",
  };
}

const config = loadConfig();

export default config;
