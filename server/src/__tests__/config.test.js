import { loadConfig } from "../config.js";

describe("loadConfig", () => {
  it("applies defaults", () => {
    const c = loadConfig({});
    expect(c).toMatchObject({
      PORT: 3000,
      NODE_ENV: "development",
      JWT_EXPIRES_IN: "30d",
      CORS_ORIGINS: null,
      RATE_LIMIT_AUTH_PER_MIN: 10,
      RATE_LIMIT_CHECKIN_PER_MIN: 6,
      PRISMA_LOG_QUERIES: false,
    });
  });

  it("allows no origins in production when CORS_ORIGINS is unset", () => {
    const env = { NODE_ENV: "production", RESEND_API_KEY: "re_x", EMAIL_FROM: "a@b.c" };
    expect(loadConfig(env).CORS_ORIGINS).toEqual([]);
  });

  it("requires the email settings in production only", () => {
    expect(() => loadConfig({ NODE_ENV: "production" })).toThrow(/RESEND_API_KEY, EMAIL_FROM/);
    expect(() => loadConfig({ NODE_ENV: "production", RESEND_API_KEY: "re_x" })).toThrow(
      /EMAIL_FROM/
    );
    expect(() => loadConfig({})).not.toThrow();
  });

  it("parses a comma-separated CORS_ORIGINS list", () => {
    const c = loadConfig({ CORS_ORIGINS: "https://a.com, https://b.com," });
    expect(c.CORS_ORIGINS).toEqual(["https://a.com", "https://b.com"]);
  });

  it("parses numbers and falls back on garbage", () => {
    const c = loadConfig({ PORT: "8080", RATE_LIMIT_AUTH_PER_MIN: "abc" });
    expect(c.PORT).toBe(8080);
    expect(c.RATE_LIMIT_AUTH_PER_MIN).toBe(10);
  });
});
