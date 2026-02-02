-- Migration: Add evidence and segment_results columns to activity_record
-- This stores detailed gameplay evidence for review and analysis

-- Add segment_results column (for storing detailed results per segment/question)
ALTER TABLE "public"."activity_record"
ADD COLUMN "segment_results" JSONB;

-- Add evidence column (for storing photos, videos, descriptions, etc.)
ALTER TABLE "public"."activity_record"
ADD COLUMN "evidence" JSONB;

-- Create indexes for better query performance on JSON fields
CREATE INDEX "activity_record_segment_results_idx"
ON "public"."activity_record" USING GIN ("segment_results");

CREATE INDEX "activity_record_evidence_idx"
ON "public"."activity_record" USING GIN ("evidence");

-- Add comments
COMMENT ON COLUMN "public"."activity_record"."segment_results"
IS 'Detailed results for each segment/question (scores, answers, audio URLs)';

COMMENT ON COLUMN "public"."activity_record"."evidence"
IS 'Additional evidence (photos, videos, descriptions, AI evaluation)';

-- Example queries you can use:

-- 1. Find records with high language scores
-- SELECT * FROM activity_record
-- WHERE segment_results @> '[{"maxScore": 90}]'::jsonb;

-- 2. Find records with photos
-- SELECT * FROM activity_record
-- WHERE evidence @> '{"photos": []}'::jsonb
-- AND jsonb_array_length(evidence->'photos') > 0;

-- 3. Get all answers for analytical activities
-- SELECT
--   ar.ActivityRecord_id,
--   sr->>'question' as question,
--   sr->>'userAnswer' as user_answer,
--   sr->>'correctAnswer' as correct_answer
-- FROM activity_record ar,
-- jsonb_array_elements(ar.segment_results) sr
-- WHERE ar.activity_id = 'some-activity-id';
