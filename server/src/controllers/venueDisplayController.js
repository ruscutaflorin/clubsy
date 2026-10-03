import crypto from "crypto";
import prisma from "../prisma/client.js";
import {
  generateRotatingQr,
  verifyDisplayKey,
  QR_STEP_SECONDS,
} from "../services/venueQrService.js";

// A wrong key and an unknown club look identical.
const findClubForKey = async (id, key) => {
  const club = await prisma.club.findUnique({ where: { id } });
  return club && verifyDisplayKey(club, key) ? club : null;
};

const notFound = (res) => res.status(404).json({ message: "Not found" });

const HTML_ESCAPES = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
const escapeHtml = (s) => String(s).replace(/[&<>"']/g, (c) => HTML_ESCAPES[c]);

const qrResponse = async (club, now = new Date()) => {
  const stepMs = QR_STEP_SECONDS * 1000;
  return {
    qrCode: await generateRotatingQr(club, now),
    expiresAt: new Date((Math.floor(now.getTime() / stepMs) + 1) * stepMs).toISOString(),
  };
};

export const getDisplayQr = async (req, res) => {
  try {
    const key = String(req.query.key ?? "");
    const club = await findClubForKey(req.params.clubId, key);
    if (!club) return notFound(res);
    res.set("Cache-Control", "no-store");
    res.json(await qrResponse(club));
  } catch (error) {
    console.error("Venue display QR error:", error);
    res.status(500).json({ message: "Error generating QR" });
  }
};

export const getDisplayPage = async (req, res) => {
  try {
    const key = String(req.query.key ?? "");
    const club = await findClubForKey(req.params.clubId, key);
    if (!club) return notFound(res);
    const { qrCode, expiresAt } = await qrResponse(club);

    const nonce = crypto.randomBytes(16).toString("base64");
    const qrUrl = `/venue-display/${encodeURIComponent(club.id)}/qr?key=${encodeURIComponent(key)}`;
    const script = `
const url = ${JSON.stringify(qrUrl).replace(/</g, "\\u003c")};
async function refresh() {
  try {
    const r = await fetch(url, { cache: "no-store" });
    if (r.ok) document.getElementById("qr").src = (await r.json()).qrCode;
  } catch (e) {}
}
setInterval(refresh, ${QR_STEP_SECONDS * 1000});`;

    res.set("Cache-Control", "no-store");
    res.set(
      "Content-Security-Policy",
      `default-src 'none'; img-src data:; connect-src 'self'; style-src 'nonce-${nonce}'; script-src 'nonce-${nonce}'`,
    );
    res.type("html").send(`<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>${escapeHtml(club.name ?? "Clubsy")}</title>
<style nonce="${nonce}">html,body{margin:0;height:100%;background:#000;color:#fff;font-family:sans-serif;text-align:center}
body{display:flex;flex-direction:column;align-items:center;justify-content:center}
img{width:min(80vmin,640px);height:auto;background:#fff;padding:2vmin;image-rendering:pixelated}</style>
</head><body>
<h1>${escapeHtml(club.name ?? "")}</h1>
<img id="qr" alt="Check-in QR code" src="${qrCode}" data-expires="${expiresAt}">
<p>Scan with Clubsy to check in</p>
<script nonce="${nonce}">${script}</script>
</body></html>`);
  } catch (error) {
    console.error("Venue display page error:", error);
    res.status(500).send("Something went wrong");
  }
};
