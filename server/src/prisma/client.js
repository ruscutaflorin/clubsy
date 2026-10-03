import pkg from "@prisma/client";
import config from "../config.js";
const { PrismaClient } = pkg;

const log = config.PRISMA_LOG_QUERIES
  ? ["query", "info", "warn", "error"]
  : ["warn", "error"];

const prisma = new PrismaClient({ log });

export default prisma;
