-- AlterTable
ALTER TABLE "CheckIn" ADD COLUMN     "hiddenFromFriends" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "shareNightsWithFriends" BOOLEAN NOT NULL DEFAULT false;
