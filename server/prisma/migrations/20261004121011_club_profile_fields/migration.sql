-- AlterTable
ALTER TABLE "Club" ADD COLUMN     "description" TEXT,
ADD COLUMN     "genres" TEXT[],
ADD COLUMN     "instagramUrl" TEXT,
ADD COLUMN     "openingHours" JSONB,
ADD COLUMN     "timezone" TEXT NOT NULL DEFAULT 'Europe/Bucharest',
ADD COLUMN     "websiteUrl" TEXT;
