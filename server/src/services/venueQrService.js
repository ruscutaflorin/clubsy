import QRCode from "qrcode";
import crypto from "crypto";

export const generateQrSecret = () => crypto.randomBytes(16).toString("hex");

export const generateClubQr = async (club) => {
  const payload = JSON.stringify({ clubId: club.id, secret: club.qrSecret });
  return QRCode.toDataURL(payload, { errorCorrectionLevel: "H", width: 1024 });
};

export const verifyClubQrPayload = (rawPayload, club) => {
  try {
    const { clubId, secret } = JSON.parse(rawPayload);
    return clubId === club.id && secret === club.qrSecret;
  } catch {
    return false;
  }
};
