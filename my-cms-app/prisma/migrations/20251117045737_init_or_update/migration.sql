/*
  Warnings:

  - You are about to drop the column `provider` on the `Parent` table. All the data in the column will be lost.
  - You are about to drop the column `providerId` on the `Parent` table. All the data in the column will be lost.

*/
-- AlterTable
ALTER TABLE "Parent" DROP COLUMN "provider",
DROP COLUMN "providerId";
