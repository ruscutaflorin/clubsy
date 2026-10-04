import { jest } from "@jest/globals";
import request from "supertest";

const clubFindUnique = jest.fn();

jest.unstable_mockModule("../prisma/client.js", () => ({
  default: { club: { findUnique: clubFindUnique } },
}));

const { default: app } = await import("../app.js");
const { displayKey } = await import("../services/venueQrService.js");

const club = { id: "c1", name: "Club <b>One</b>", qrSecret: "s3cret" };
const key = displayKey(club);

beforeEach(() => {
  jest.spyOn(console, "error").mockImplementation(() => {});
  clubFindUnique.mockReset().mockResolvedValue(club);
});
afterEach(() => jest.restoreAllMocks());

describe("GET /venue-display/:clubId/qr", () => {
  it("returns a QR data URL and expiry for a valid key", async () => {
    const before = Date.now();
    const res = await request(app).get(`/venue-display/c1/qr?key=${key}`);
    expect(res.status).toBe(200);
    expect(res.body.qrCode).toMatch(/^data:image\/png;base64,/);
    expect(new Date(res.body.expiresAt).getTime()).toBeGreaterThan(before);
    expect(res.headers["cache-control"]).toBe("no-store");
  });

  it("404s on a wrong or missing key", async () => {
    expect((await request(app).get("/venue-display/c1/qr?key=nope")).status).toBe(404);
    expect((await request(app).get("/venue-display/c1/qr")).status).toBe(404);
  });

  it("404s on an unknown club", async () => {
    clubFindUnique.mockResolvedValue(null);
    expect((await request(app).get(`/venue-display/zzz/qr?key=${key}`)).status).toBe(404);
  });

  it("500s when the lookup fails", async () => {
    clubFindUnique.mockRejectedValue(new Error("db"));
    expect((await request(app).get(`/venue-display/c1/qr?key=${key}`)).status).toBe(500);
  });
});

describe("GET /venue-display/:clubId", () => {
  it("renders an escaped html page with an inline QR and a nonce-based CSP", async () => {
    const res = await request(app).get(`/venue-display/c1?key=${key}`);
    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toMatch(/text\/html/);
    expect(res.text).toContain('src="data:image/png');
    expect(res.text).toContain("Club &lt;b&gt;One&lt;/b&gt;");
    expect(res.text).not.toContain("<b>One</b>");
    const nonce = /script-src 'nonce-([^']+)'/.exec(res.headers["content-security-policy"])[1];
    expect(res.text).toContain(`<script nonce="${nonce}">`);
  });

  it("404s on a wrong key, a missing key and an unknown club", async () => {
    expect((await request(app).get("/venue-display/c1?key=bad")).status).toBe(404);
    expect((await request(app).get("/venue-display/c1")).status).toBe(404);
    clubFindUnique.mockResolvedValue(null);
    expect((await request(app).get(`/venue-display/zzz?key=${key}`)).status).toBe(404);
  });

  it("stops accepting the old key once the QR secret is rotated", async () => {
    clubFindUnique.mockResolvedValue({ ...club, qrSecret: "rotated" });
    expect((await request(app).get(`/venue-display/c1?key=${key}`)).status).toBe(404);
  });
});
