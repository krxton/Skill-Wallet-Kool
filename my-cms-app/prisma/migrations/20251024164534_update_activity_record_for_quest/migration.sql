/*
  Warnings:

  - You are about to drop the column `timeSpent` on the `ActivityRecord` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "ActivityRecord" DROP COLUMN "timeSpent",
ADD COLUMN     "detailResults" JSONB,
ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'Pending',
ADD COLUMN     "timeSpentSeconds" INTEGER,
ALTER COLUMN "dateCompleted" SET DEFAULT CURRENT_TIMESTAMP;
