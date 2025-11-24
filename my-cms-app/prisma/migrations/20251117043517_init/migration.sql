-- AlterTable
ALTER TABLE "Parent" ADD COLUMN     "provider" TEXT NOT NULL DEFAULT 'local',
ADD COLUMN     "providerId" TEXT;
