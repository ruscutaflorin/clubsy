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

  return {
    PORT: toInt(env.PORT, 3000),
    NODE_ENV,
    IS_PRODUCTION: NODE_ENV === "production",
    JWT_SECRET: env.JWT_SECRET,
    JWT_EXPIRES_IN: env.JWT_EXPIRES_IN || "30d",
    // null means "allow all"; an empty array means "allow none".
    CORS_ORIGINS: corsList.length > 0 ? corsList : NODE_ENV === "production" ? [] : null,
    RATE_LIMIT_AUTH_PER_MIN: toInt(env.RATE_LIMIT_AUTH_PER_MIN, 10),
    RATE_LIMIT_CHECKIN_PER_MIN: toInt(env.RATE_LIMIT_CHECKIN_PER_MIN, 6),
    PRISMA_LOG_QUERIES: env.PRISMA_LOG_QUERIES === "1",
  };
}

const config = loadConfig();

export default config;
