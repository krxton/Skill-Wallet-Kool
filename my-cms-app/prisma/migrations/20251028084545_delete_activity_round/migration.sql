/*
  Warnings:

  - You are about to drop the `ActivityRound` table. If the table is not empty, all the data it contains will be lost.

*/
-- DropForeignKey
ALTER TABLE "public"."ActivityRound" DROP CONSTRAINT "ActivityRound_activityId_fkey";

-- DropForeignKey
ALTER TABLE "public"."ActivityRound" DROP CONSTRAINT "ActivityRound_childId_fkey";

-- DropTable
DROP TABLE "public"."ActivityRound";
