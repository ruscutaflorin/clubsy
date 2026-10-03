import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { parse } from "yaml";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, "..", "..", "..");
const blueprint = parse(fs.readFileSync(path.join(root, "render.yaml"), "utf8"));
const service = blueprint.services.find((s) => s.type === "web");
const declared = new Set(service.envVars.map((v) => v.key));

// Read by config.js but safe to leave unset (defaults) or provided by Render itself.
const OPTIONAL = new Set([
  "PORT",
  "RATE_LIMIT_AUTH_PER_MIN",
  "RATE_LIMIT_CHECKIN_PER_MIN",
  "PRISMA_LOG_QUERIES",
]);

describe("render.yaml", () => {
  it("configures the web service", () => {
    expect(service.rootDir).toBe("server");
    expect(service.region).toBe("frankfurt");
    expect(service.healthCheckPath).toBe("/health/ready");
    expect(service.preDeployCommand).toBe("npx prisma migrate deploy");
    expect(service.startCommand).toBe("node src/index.js");
  });

  it("wires the database", () => {
    const db = blueprint.databases.find((d) => d.name === "clubsy-db");
    expect(db.region).toBe("frankfurt");
    const url = service.envVars.find((v) => v.key === "DATABASE_URL");
    expect(url.fromDatabase.name).toBe("clubsy-db");
  });

  it("declares every variable config.js reads in production", () => {
    const src = fs.readFileSync(path.join(here, "..", "config.js"), "utf8");
    const read = [...src.matchAll(/env\.([A-Z_]+)/g)].map((m) => m[1]);
    const missing = read.filter((k) => !declared.has(k) && !OPTIONAL.has(k));
    expect(missing).toEqual([]);
    expect(declared.has("DATABASE_URL")).toBe(true);
  });

  it("generates the JWT secret and leaves owner secrets unsynced", () => {
    const byKey = Object.fromEntries(service.envVars.map((v) => [v.key, v]));
    expect(byKey.JWT_SECRET.generateValue).toBe(true);
    expect(byKey.NODE_ENV.value).toBe("production");
    for (const k of ["CORS_ORIGINS", "RESEND_API_KEY", "EMAIL_FROM"]) {
      expect(byKey[k].sync).toBe(false);
    }
  });
});
