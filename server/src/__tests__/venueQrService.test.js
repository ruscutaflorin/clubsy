import { generateQrSecret, verifyClubQrPayload } from "../services/venueQrService.js";

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

  it("rejects malformed or null payloads", () => {
    expect(verifyClubQrPayload("not json", club)).toBe(false);
    expect(verifyClubQrPayload("null", club)).toBe(false);
    expect(verifyClubQrPayload(undefined, club)).toBe(false);
  });
});
