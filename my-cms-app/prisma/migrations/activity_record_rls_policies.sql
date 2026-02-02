-- RLS Policies for activity_record table
-- This allows parents to read and write their children's activity records

-- Enable RLS on activity_record table
ALTER TABLE "public"."activity_record" ENABLE ROW LEVEL SECURITY;

-- Policy: Parents can view their own children's activity records
CREATE POLICY "Parents can view their children's activity records"
ON "public"."activity_record"
FOR SELECT
USING (
  parent_id IN (
    SELECT parent_id
    FROM "public"."parent"
    WHERE user_id = auth.uid()
  )
);

-- Policy: Parents can insert activity records for their children
CREATE POLICY "Parents can create activity records for their children"
ON "public"."activity_record"
FOR INSERT
WITH CHECK (
  parent_id IN (
    SELECT parent_id
    FROM "public"."parent"
    WHERE user_id = auth.uid()
  )
  AND
  child_id IN (
    SELECT pc.child_id
    FROM "public"."parent_and_child" pc
    INNER JOIN "public"."parent" p ON pc.parent_id = p.parent_id
    WHERE p.user_id = auth.uid()
  )
);

-- Policy: Parents can update their children's activity records
CREATE POLICY "Parents can update their children's activity records"
ON "public"."activity_record"
FOR UPDATE
USING (
  parent_id IN (
    SELECT parent_id
    FROM "public"."parent"
    WHERE user_id = auth.uid()
  )
)
WITH CHECK (
  parent_id IN (
    SELECT parent_id
    FROM "public"."parent"
    WHERE user_id = auth.uid()
  )
);

-- Policy: Parents can delete their children's activity records
CREATE POLICY "Parents can delete their children's activity records"
ON "public"."activity_record"
FOR DELETE
USING (
  parent_id IN (
    SELECT parent_id
    FROM "public"."parent"
    WHERE user_id = auth.uid()
  )
);

-- Optional: Admin policy (if you have admins)
-- CREATE POLICY "Admins can manage all activity records"
-- ON "public"."activity_record"
-- FOR ALL
-- USING (
--   EXISTS (
--     SELECT 1 FROM "auth"."users"
--     WHERE id = auth.uid()
--     AND raw_user_meta_data->>'role' = 'admin'
--   )
-- );
