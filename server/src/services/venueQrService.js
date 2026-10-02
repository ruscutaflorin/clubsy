import QRCode from "qrcode";
import crypto from "crypto";

export const QR_STEP_SECONDS = 30;

export const generateQrSecret = () => crypto.randomBytes(16).toString("hex");

export const generateClubQr = async (club) => {
  const payload = JSON.stringify({ clubId: club.id, secret: club.qrSecret });
  return QRCode.toDataURL(payload, { errorCorrectionLevel: "H", width: 1024 });
};

const hmacHex = (secret, message) =>
  crypto.createHmac("sha256", String(secret)).update(message).digest("hex");

// Constant-time string comparison; unequal lengths are simply unequal.
const safeEqual = (a, b) => {
  if (typeof a !== "string" || typeof b !== "string") return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  return bufA.length === bufB.length && crypto.timingSafeEqual(bufA, bufB);
};

export const timeStepFor = (now = new Date()) =>
  Math.floor(now.getTime() / 1000 / QR_STEP_SECONDS);

export const rotatingCode = (secret, timeStep) =>
  hmacHex(secret, String(timeStep)).slice(0, 8);

export const buildRotatingPayload = (club, now = new Date()) => {
  const t = timeStepFor(now);
  return JSON.stringify({ clubId: club.id, t, code: rotatingCode(club.qrSecret, t) });
};

export const generateRotatingQr = async (club, now = new Date()) =>
  QRCode.toDataURL(buildRotatingPayload(club, now), {
    errorCorrectionLevel: "M",
    width: 512,
  });

// Rotating the QR secret also invalidates every display link.
export const displayKey = (club) => hmacHex(club.qrSecret, "display");

export const verifyDisplayKey = (club, key) => safeEqual(displayKey(club), key);

// Accepts the legacy static {clubId, secret} payload or a rotating {clubId, t, code}
// payload whose step is within ±1 of now.
export const verifyClubQrPayload = (rawPayload, club, now = new Date()) => {
  try {
    const payload = JSON.parse(rawPayload);
    if (!payload || payload.clubId !== club.id) return false;
    if (payload.secret !== undefined) return safeEqual(payload.secret, club.qrSecret);
    if (!Number.isInteger(payload.t)) return false;
    if (Math.abs(payload.t - timeStepFor(now)) > 1) return false;
    return safeEqual(payload.code, rotatingCode(club.qrSecret, payload.t));
  } catch {
    return false;
  }
};
