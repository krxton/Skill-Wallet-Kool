-- migration.sql

/*
  Warnings:

  - Added the required column `roundNumber` to the `ActivityRecord` table without a default value. This is not possible if the table is not empty.
*/
-- 1. เพิ่มคอลัมน์ roundNumber เป็น OPTIONAL ชั่วคราว
ALTER TABLE "ActivityRecord" ADD COLUMN "roundNumber" INTEGER;

-- 2. กำหนดค่าเริ่มต้น 1 ให้กับแถวที่มีอยู่เดิม (ในคอลัมน์ที่เพิ่งสร้าง)
-- เนื่องจากตอนนี้คอลัมน์ถูกสร้างแล้ว คำสั่งนี้จึงทำงานได้
UPDATE "ActivityRecord" SET "roundNumber" = 1;

-- 3. กำหนดให้คอลัมน์ roundNumber เป็น NOT NULL 
-- (ต้องรันแยกคำสั่งเพื่อให้ PostgreSQL ยอมรับ)
ALTER TABLE "ActivityRecord" ALTER COLUMN "roundNumber" SET NOT NULL;


-- CreateTable (โค้ดสร้าง ActivityRound ยังคงเหมือนเดิม)
CREATE TABLE "ActivityRound" (
    "id" TEXT NOT NULL,
    "childId" TEXT NOT NULL,
    "activityId" TEXT NOT NULL,
    "currentRound" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "ActivityRound_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "ActivityRound_childId_activityId_key" ON "ActivityRound"("childId", "activityId");

-- AddForeignKey
ALTER TABLE "ActivityRound" ADD CONSTRAINT "ActivityRound_childId_fkey" FOREIGN KEY ("childId") REFERENCES "Child"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ActivityRound" ADD CONSTRAINT "ActivityRound_activityId_fkey" FOREIGN KEY ("activityId") REFERENCES "Activity"("id") ON DELETE RESTRICT ON UPDATE CASCADE;