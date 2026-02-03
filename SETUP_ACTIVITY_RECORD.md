# Setup Activity Record - คู่มือการแก้ไขปัญหา Complete Quest

## ปัญหาที่พบ
1. ตาราง `activity_record` ไม่มี column `activity_id` เพื่อเชื่อมกับตาราง `activity`
2. ไม่มี API endpoint `/api/complete-quest` สำหรับบันทึกผลการเล่นกิจกรรม
3. ไม่มี RLS policies สำหรับตาราง `activity_record` ใน Supabase
4. Flutter app ไม่ส่ง `childId` ใน payload

## สิ่งที่ได้แก้ไขแล้ว ✅

### 1. Flutter App
- ✅ แก้ไข `flutter_app/lib/services/activity_service.dart` เพื่อส่ง `childId` ใน payload

### 2. Backend API
- ✅ สร้าง API endpoint `/api/complete-quest` ใน `my-cms-app/src/app/api/complete-quest/route.ts`
  - รับข้อมูล: childId, activityId, totalScoreEarned, segmentResults, evidence, parentScore
  - ตรวจสอบ authentication ผ่าน Supabase
  - บันทึกลงตาราง activity_record
  - อัปเดต wallet ของเด็ก
  - อัปเดต play_count ของ activity

### 3. Database Schema
- ✅ สร้างไฟล์ migration: `prisma/migrations/add_activity_id_to_activity_record.sql`
- ✅ สร้างไฟล์ RLS policies: `prisma/migrations/activity_record_rls_policies.sql`
- ✅ อัปเดต `prisma/schema.prisma` เพื่อเพิ่ม activity_id และ relation

## ขั้นตอนที่คุณต้องทำต่อ 🔧

### ขั้นตอนที่ 1: Run Database Migrations

คุณต้อง run SQL migrations ใน Supabase:

#### วิธีที่ 1: ผ่าน Supabase Dashboard (แนะนำ)
1. เข้า Supabase Dashboard ของโปรเจกต์คุณ
2. ไปที่ **SQL Editor**
3. Run ไฟล์แรก - เพิ่ม activity_id column:
   ```sql
   -- คัดลอกทั้งหมดจากไฟล์ add_activity_id_to_activity_record.sql
   ALTER TABLE "public"."activity_record"
   ADD COLUMN "activity_id" UUID;

   ALTER TABLE "public"."activity_record"
   ADD CONSTRAINT "activity_record_activity_id_fkey"
   FOREIGN KEY ("activity_id")
   REFERENCES "public"."activity"("activity_id")
   ON DELETE CASCADE;

   CREATE INDEX "activity_record_activity_id_idx"
   ON "public"."activity_record"("activity_id");

   COMMENT ON COLUMN "public"."activity_record"."activity_id"
   IS 'Reference to the activity that was completed';
   ```

4. Run ไฟล์ที่สอง - สร้าง RLS policies:
   ```sql
   -- คัดลอกทั้งหมดจากไฟล์ activity_record_rls_policies.sql

   ALTER TABLE "public"."activity_record" ENABLE ROW LEVEL SECURITY;

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

   -- ... (คัดลอกทั้งหมดจากไฟล์)
   ```

#### วิธีที่ 2: ผ่าน Prisma (ถ้าต้องการ)
```bash
cd my-cms-app
npx prisma db push
```

### ขั้นตอนที่ 2: Rebuild Flutter App

```bash
cd flutter_app
flutter clean
flutter pub get
flutter run
```

### ขั้นตอนที่ 3: Restart Backend Server

```bash
cd my-cms-app
npm run dev
```

### ขั้นตอนที่ 4: ทดสอบ

1. เปิด Flutter app
2. เล่นกิจกรรมภาษาจนจบ
3. กด "Finish" หรือปุ่มเสร็จสิ้น
4. ตรวจสอบว่า:
   - ไม่มี error เกิดขึ้น
   - คะแนนถูกบันทึกใน database
   - wallet ของเด็กเพิ่มขึ้น
   - play_count ของ activity เพิ่มขึ้น

## โครงสร้างข้อมูลที่ส่งไป API

```json
{
  "childId": "uuid-of-child",
  "activityId": "uuid-of-activity",
  "totalScoreEarned": 85,
  "segmentResults": [
    {
      "id": "segment-id",
      "text": "What will you do?",
      "maxScore": 95,
      "recognizedText": "What will you do",
      "audioUrl": "storage-url"
    }
  ],
  "evidence": { /* optional */ },
  "parentScore": null,
  "timeSpent": 120
}
```

## Response ที่ได้จาก API

```json
{
  "success": true,
  "message": "Quest completed successfully!",
  "activityRecord": {
    "ActivityRecord_id": "uuid",
    "activity_id": "uuid",
    "child_id": "uuid",
    "point": 85,
    "date": "2026-02-02T..."
  },
  "scoreEarned": 85,
  "newWallet": 185,
  "segmentResults": [...],
  "evidence": {...}
}
```

## ตรวจสอบว่าทำสำเร็จหรือไม่

### ใน Supabase:
```sql
-- ตรวจสอบว่า column activity_id ถูกเพิ่มแล้ว
SELECT * FROM information_schema.columns
WHERE table_name = 'activity_record'
AND column_name = 'activity_id';

-- ตรวจสอบ RLS policies
SELECT * FROM pg_policies
WHERE tablename = 'activity_record';

-- ตรวจสอบข้อมูล activity_record ที่บันทึกแล้ว
SELECT * FROM activity_record
ORDER BY created_at DESC
LIMIT 5;
```

## หมายเหตุสำคัญ

1. **Connection Timeout Issue**: ปัญหาเดิมเกิดจาก API endpoint ไม่มี ดังนั้นจะแก้ไขหลังจาก run migrations และ restart server แล้ว

2. **Authentication**: API ใช้ Supabase auth token ดังนั้นต้องแน่ใจว่า Flutter app ส่ง token ที่ถูกต้อง

3. **RLS Policies**: Policies ถูกสร้างเพื่อให้ parent เข้าถึงได้เฉพาะข้อมูลของลูกตัวเองเท่านั้น

4. **Schema Changes**: ถ้ามี error เกี่ยวกับ Prisma schema หลังจาก push ให้ run:
   ```bash
   npx prisma generate
   ```

## ถ้ายังมีปัญหา

1. ตรวจสอบ logs ใน:
   - Flutter: `flutter logs` หรือ console output
   - Backend: terminal ที่รัน `npm run dev`
   - Supabase: Logs section ใน Dashboard

2. ตรวจสอบ network connection:
   - ใช้ IP address ที่ถูกต้อง (ไม่ใช่ 10.0.2.2 ถ้า test บน device จริง)
   - ตรวจสอบ firewall settings

3. ตรวจสอบ Environment Variables:
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - `DATABASE_URL` และ `DIRECT_URL`

## สรุป

หลังจากทำตามขั้นตอนข้างต้น ระบบ Complete Quest จะทำงานได้อย่างสมบูรณ์:
- ✅ บันทึกผลการเล่นกิจกรรม
- ✅ เพิ่มคะแนนให้เด็ก
- ✅ นับจำนวนรอบการเล่น
- ✅ รักษาความปลอดภัยด้วย RLS policies
