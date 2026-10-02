import "dotenv/config";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import bcrypt from "bcryptjs";
import QRCode from "qrcode";
import prisma from "../src/prisma/client.js";
import { generateQrSecret } from "../src/services/venueQrService.js";
import { buildSeedClubs, slugify } from "./seedData.js";

const outputDir = path.join(path.dirname(fileURLToPath(import.meta.url)), "..", "seed-output");

const seedAdmin = async () => {
  const email = process.env.SEED_ADMIN_EMAIL?.trim().toLowerCase();
  const password = process.env.SEED_ADMIN_PASSWORD;
  if (!email || !password) {
    console.warn("SEED_ADMIN_EMAIL / SEED_ADMIN_PASSWORD not set: skipping admin user.");
    return;
  }
  const hashed = await bcrypt.hash(password, 10);
  await prisma.user.upsert({
    where: { email },
    update: { role: "ADMIN" },
    create: { email, password: hashed, name: "Admin", role: "ADMIN" },
  });
  console.log(`Admin ready: ${email}`);
};

const seedClubs = async () => {
  fs.mkdirSync(outputDir, { recursive: true });
  for (const data of buildSeedClubs({})) {
    // name is not unique in the schema, so upsert by hand.
    const existing = await prisma.club.findFirst({ where: { name: data.name } });
    const club = existing
      ? await prisma.club.update({ where: { id: existing.id }, data })
      : await prisma.club.create({ data: { ...data, qrSecret: generateQrSecret() } });

    const payload = JSON.stringify({ clubId: club.id, secret: club.qrSecret });
    await QRCode.toFile(path.join(outputDir, `${slugify(club.name)}.png`), payload);
    console.log(`Club ready: ${club.name} (${club.city})`);
  }
};

try {
  await seedAdmin();
  await seedClubs();
} finally {
  await prisma.$disconnect();
}
