import {
  buildRotatingPayload,
  generateClubQr,
  generateQrSecret,
  rotatingCode,
  verifyClubQrPayload,
} from "../services/venueQrService.js";

describe("venueQrService", () => {
  const club = { id: "club-1", qrSecret: "s3cret" };
  const payloadFor = (clubId, secret) => JSON.stringify({ clubId, secret });

  it("generates distinct 32-char hex secrets", () => {
    const a = generateQrSecret();
    expect(a).toMatch(/^[0-9a-f]{32}$/);
    expect(generateQrSecret()).not.toBe(a);
  });

  it("accepts a matching payload", () => {
    expect(verifyClubQrPayload(payloadFor("club-1", "s3cret"), club)).toBe(true);
  });

  it("rejects a wrong secret or wrong club", () => {
    expect(verifyClubQrPayload(payloadFor("club-1", "x"), club)).toBe(false);
    expect(verifyClubQrPayload(payloadFor("club-2", "s3cret"), club)).toBe(false);
  });

  it("renders a 1024px PNG for printing", async () => {
    const url = await generateClubQr(club);
    expect(url.startsWith("data:image/png;base64,")).toBe(true);
    const png = Buffer.from(url.split(",")[1], "base64");
    expect(png.readUInt32BE(16)).toBe(1024);
  }, 30000);

  describe("rotating payloads", () => {
    const now = new Date("2026-10-02T12:00:10Z");
    const at = (offsetSteps) => new Date(now.getTime() + offsetSteps * 30000);
    const payloadAt = (c, offsetSteps) => buildRotatingPayload(c, at(offsetSteps));

    it("accepts the current, previous and next step", () => {
      for (const o of [-1, 0, 1]) {
        expect(verifyClubQrPayload(payloadAt(club, o), club, now)).toBe(true);
      }
    });

    it("rejects payloads two steps away", () => {
      expect(verifyClubQrPayload(payloadAt(club, -2), club, now)).toBe(false);
      expect(verifyClubQrPayload(payloadAt(club, 2), club, now)).toBe(false);
    });

    it("rejects a tampered code and a non-integer step", () => {
      const p = JSON.parse(payloadAt(club, 0));
      expect(verifyClubQrPayload(JSON.stringify({ ...p, code: "00000000" }), club, now)).toBe(false);
      expect(verifyClubQrPayload(JSON.stringify({ ...p, code: undefined }), club, now)).toBe(false);
      expect(verifyClubQrPayload(JSON.stringify({ ...p, t: "x" }), club, now)).toBe(false);
    });

    it("rejects a payload for another club", () => {
      const other = { id: "club-2", qrSecret: "s3cret" };
      expect(verifyClubQrPayload(payloadAt(other, 0), club, now)).toBe(false);
    });

    it("builds an 8-hex code and still accepts the static payload", () => {
      expect(rotatingCode("s3cret", 5)).toMatch(/^[0-9a-f]{8}$/);
      expect(verifyClubQrPayload(payloadFor("club-1", "s3cret"), club, now)).toBe(true);
    });
  });

  it("rejects malformed or null payloads", () => {
    expect(verifyClubQrPayload("not json", club)).toBe(false);
    expect(verifyClubQrPayload("null", club)).toBe(false);
    expect(verifyClubQrPayload(undefined, club)).toBe(false);
  });
});
