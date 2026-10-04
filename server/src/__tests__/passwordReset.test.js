import { jest } from "@jest/globals";
import bcrypt from "bcryptjs";
import request from "supertest";

// Minimal in-memory stand-in for the two tables the reset flow touches.
let users;
let tokens;

const matches = (row, where) =>
  Object.entries(where).every(([k, v]) => {
    if (v && typeof v === "object" && "gt" in v) return row[k] > v.gt;
    return row[k] === v;
  });

const prismaMock = {
  user: {
    findUnique: jest.fn(async ({ where }) => users.find((u) => matches(u, where)) ?? null),
    update: jest.fn(async ({ where, data }) => {
      const u = users.find((x) => x.id === where.id);
      Object.assign(u, data);
      return u;
    }),
  },
  passwordResetToken: {
    create: jest.fn(async ({ data }) => {
      const row = { id: `t${tokens.length + 1}`, usedAt: null, ...data };
      tokens.push(row);
      return row;
    }),
    findFirst: jest.fn(async ({ where }) => tokens.find((t) => matches(t, where)) ?? null),
    updateMany: jest.fn(async ({ where, data }) => {
      const rows = tokens.filter((t) => matches(t, where));
      rows.forEach((t) => Object.assign(t, data));
      return { count: rows.length };
    }),
  },
};

jest.unstable_mockModule("../prisma/client.js", () => ({ default: prismaMock }));

process.env.JWT_SECRET = "test-secret";
// All requests come from one IP; only the per-email limit is under test.
process.env.RATE_LIMIT_PASSWORD_RESET_IP_PER_HOUR = "1000";
const { default: app } = await import("../app.js");
const { setEmailSender } = await import("../services/emailService.js");

const sent = [];
const fakeSender = { send: jest.fn(async (mail) => void sent.push(mail)) };
const codeFromLastMail = () => sent.at(-1).text.match(/\b(\d{6})\b/)[1];

const forgot = (email) => request(app).post("/api/auth/password/forgot").send({ email });
const reset = (body) => request(app).post("/api/auth/password/reset").send(body);

// The rate limiters key on IP/email; a distinct email per test keeps them independent.
let n = 0;
let email;

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  n += 1;
  email = `ana${n}@example.com`;
  users = [{ id: "u1", email, password: bcrypt.hashSync("old-password", 4) }];
  tokens = [];
  sent.length = 0;
  setEmailSender(fakeSender);
});

afterAll(() => setEmailSender(null));

describe("POST /api/auth/password/forgot", () => {
  it("202 and no email for an unknown address", async () => {
    const res = await forgot(`nobody${n}@example.com`);
    expect(res.status).toBe(202);
    expect(sent).toHaveLength(0);
    expect(tokens).toHaveLength(0);
  });

  it("202, emails a 6-digit code and stores only its hash", async () => {
    const res = await forgot(email);
    expect(res.status).toBe(202);
    expect(sent).toHaveLength(1);
    expect(sent[0].to).toBe(email);
    expect(tokens).toHaveLength(1);
    expect(tokens[0].tokenHash).not.toContain(codeFromLastMail());
    expect(tokens[0].expiresAt.getTime() - Date.now()).toBeLessThanOrEqual(15 * 60 * 1000);
  });

  it("answers 202 even when sending fails", async () => {
    fakeSender.send.mockRejectedValueOnce(new Error("resend down"));
    expect((await forgot(email)).status).toBe(202);
  });

  it("429s after too many requests for the same email", async () => {
    const statuses = [];
    for (let i = 0; i < 6; i++) statuses.push((await forgot(`spam${n}@example.com`)).status);
    expect(statuses.at(-1)).toBe(429);
  });
});

describe("POST /api/auth/password/reset", () => {
  it("resets the password: the new one works and the old one doesn't", async () => {
    await forgot(email);
    const res = await reset({ email, code: codeFromLastMail(), newPassword: "brand-new-pass" });
    expect(res.status).toBe(200);
    expect(await bcrypt.compare("brand-new-pass", users[0].password)).toBe(true);
    expect(await bcrypt.compare("old-password", users[0].password)).toBe(false);
  });

  it("400 for a reused code and leaves the second password unset", async () => {
    await forgot(email);
    const code = codeFromLastMail();
    await reset({ email, code, newPassword: "brand-new-pass" });
    const again = await reset({ email, code, newPassword: "another-new-pass" });
    expect(again.status).toBe(400);
    expect(await bcrypt.compare("brand-new-pass", users[0].password)).toBe(true);
  });

  it("400 for an expired code", async () => {
    await forgot(email);
    tokens[0].expiresAt = new Date(Date.now() - 1000);
    const res = await reset({ email, code: codeFromLastMail(), newPassword: "brand-new-pass" });
    expect(res.status).toBe(400);
    expect(await bcrypt.compare("old-password", users[0].password)).toBe(true);
  });

  it("400 for a wrong code", async () => {
    await forgot(email);
    const wrong = codeFromLastMail() === "000000" ? "000001" : "000000";
    const res = await reset({ email, code: wrong, newPassword: "brand-new-pass" });
    expect(res.status).toBe(400);
  });

  it("only the newest code works after a second request", async () => {
    await forgot(email);
    const first = codeFromLastMail();
    await forgot(email);
    const second = codeFromLastMail();
    if (first !== second) {
      expect((await reset({ email, code: first, newPassword: "brand-new-pass" })).status).toBe(400);
    }
    expect((await reset({ email, code: second, newPassword: "brand-new-pass" })).status).toBe(200);
  });

  it("400 for a 7-character new password, keeping the code usable", async () => {
    await forgot(email);
    const code = codeFromLastMail();
    expect((await reset({ email, code, newPassword: "1234567" })).status).toBe(400);
    expect((await reset({ email, code, newPassword: "long-enough-pass" })).status).toBe(200);
  });
});
