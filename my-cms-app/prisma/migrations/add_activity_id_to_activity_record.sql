-- Migration: Add activity_id column to activity_record table
-- This connects activity_record to the activity table

-- Add the activity_id column
ALTER TABLE "public"."activity_record"
ADD COLUMN "activity_id" UUID;

-- Add foreign key constraint
ALTER TABLE "public"."activity_record"
ADD CONSTRAINT "activity_record_activity_id_fkey"
FOREIGN KEY ("activity_id")
REFERENCES "public"."activity"("activity_id")
ON DELETE CASCADE;

-- Create index for better query performance
CREATE INDEX "activity_record_activity_id_idx"
ON "public"."activity_record"("activity_id");

-- Optional: Add comment
COMMENT ON COLUMN "public"."activity_record"."activity_id"
IS 'Reference to the activity that was completed';
