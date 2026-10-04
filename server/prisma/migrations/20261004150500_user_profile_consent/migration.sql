-- AlterTable
ALTER TABLE "User" ADD COLUMN     "acceptedTermsAt" TIMESTAMP(3),
ADD COLUMN     "ageConfirmedAt" TIMESTAMP(3),
ADD COLUMN     "homeCity" TEXT,
ADD COLUMN     "termsVersion" TEXT,
ADD COLUMN     "username" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");
