# การแก้ไข Authentication Issue สำหรับ Complete Quest

## ปัญหาที่พบเพิ่มเติม

หลังจากสร้าง API endpoint และ database schema แล้ว พบปัญหา:
1. ❌ Flutter app ไม่ส่ง authentication token
2. ❌ `childId` เป็นค่า hardcoded (`CHILD_001`)
3. ❌ API endpoint รองรับเฉพาะ cookie-based auth (สำหรับ web browser)

## การแก้ไขที่ทำไปแล้ว ✅

### 1. **อัปเดต ApiService เพื่อส่ง Supabase Token**

แก้ไขไฟล์: `flutter_app/lib/services/api_service.dart`

**ก่อนแก้:**
```dart
Map<String, String> get _headers => {
  'Content-Type': 'application/json',
};
```

**หลังแก้:**
```dart
Future<Map<String, String>> _getHeaders() async {
  final headers = <String, String>{
    'Content-Type': 'application/json',
  };

  // Get Supabase access token if user is logged in
  final session = _supabase.auth.currentSession;
  if (session != null) {
    headers['Authorization'] = 'Bearer ${session.accessToken}';
  }

  return headers;
}
```

ตอนนี้ทุก API request จะส่ง Supabase access token ไปด้วยอัตโนมัติ!

### 2. **อัปเดต API Endpoint รองรับทั้ง Bearer Token และ Cookie Auth**

แก้ไขไฟล์: `my-cms-app/src/app/api/complete-quest/route.ts`

API ตอนนี้รองรับ 2 วิธี authentication:
- **Bearer Token** (สำหรับ Flutter app)
- **Cookie-based** (สำหรับ web browser/admin panel)

```typescript
// Get Authorization header (for Flutter app)
const authHeader = request.headers.get('authorization');
let supabase;

if (authHeader?.startsWith('Bearer ')) {
  // Flutter app authentication
  const token = authHeader.substring(7);
  supabase = createServerClient(..., {
    global: {
      headers: {
        Authorization: `Bearer ${token}`
      }
    },
    cookies: {
      getAll: () => [],
      setAll: () => {},
    },
  });
} else {
  // Web browser authentication with cookies
  const cookieStore = await cookies();
  supabase = createServerClient(..., {
    cookies: { ... }
  });
}
```

## ปัญหาที่ยังค้างอยู่ ⚠️

### 1. **Hardcoded Child ID**

ใน `flutter_app/lib/providers/user_provider.dart` line 11:
```dart
String? _currentChildId = 'CHILD_001'; // ❌ ค่าแบบ test
```

**วิธีแก้:**
คุณต้องเปลี่ยนให้ app ดึง child ID จริงจาก database หลังจาก login สำเร็จ

**ตัวอย่างวิธีแก้:**
```dart
// ใน user_provider.dart
Future<void> fetchChildrenData() async {
  try {
    final userId = _supabase.auth.currentUser?.id;

    if (userId != null) {
      // ดึง parent_id ก่อน
      final parentData = await _supabase
          .from('parent')
          .select('parent_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (parentData != null) {
        final parentId = parentData['parent_id'];

        // ดึง children ของ parent นี้
        final childrenData = await _supabase
            .from('parent_and_child')
            .select('child_id, child(child_id, name_surname)')
            .eq('parent_id', parentId)
            .limit(1); // เอาแค่คนแรก หรือจะให้เลือกก็ได้

        if (childrenData.isNotEmpty) {
          _currentChildId = childrenData[0]['child_id'];
          notifyListeners();
        }
      }
    }
  } catch (e) {
    debugPrint('fetchChildrenData error: $e');
  }
}
```

แล้วเรียกใน login screen หลัง login สำเร็จ:
```dart
// หลังจาก Supabase auth.signIn สำเร็จ
final userProvider = Provider.of<UserProvider>(context, listen: false);
await userProvider.fetchParentData();
await userProvider.fetchChildrenData(); // 🆕 เพิ่มบรรทัดนี้
```

### 2. **ตรวจสอบว่า Supabase Auth ทำงานใน Flutter**

ใน Flutter app ตรวจสอบว่า:
- มีการ login ผ่าน Supabase auth
- `Supabase.instance.client.auth.currentSession` ไม่เป็น null
- `Supabase.instance.client.auth.currentUser` มีข้อมูล

**เช็คได้ด้วย:**
```dart
final session = Supabase.instance.client.auth.currentSession;
print('📱 Current Session: ${session?.accessToken}');
print('📱 Current User: ${Supabase.instance.client.auth.currentUser?.id}');
```

## ขั้นตอนที่ต้องทำต่อ 🔧

### ขั้นตอนที่ 1: Run Database Migrations (ถ้ายังไม่ได้ทำ)

ใน Supabase Dashboard → SQL Editor:

**Query 1: เพิ่ม activity_id column**
```sql
ALTER TABLE "public"."activity_record" ADD COLUMN "activity_id" UUID;

ALTER TABLE "public"."activity_record"
ADD CONSTRAINT "activity_record_activity_id_fkey"
FOREIGN KEY ("activity_id") REFERENCES "public"."activity"("activity_id")
ON DELETE CASCADE;

CREATE INDEX "activity_record_activity_id_idx"
ON "public"."activity_record"("activity_id");
```

**Query 2: สร้าง RLS Policies**
```sql
ALTER TABLE "public"."activity_record" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can view their children's activity records"
ON "public"."activity_record" FOR SELECT
USING (
  parent_id IN (
    SELECT parent_id FROM "public"."parent" WHERE user_id = auth.uid()
  )
);

CREATE POLICY "Parents can create activity records for their children"
ON "public"."activity_record" FOR INSERT
WITH CHECK (
  parent_id IN (SELECT parent_id FROM "public"."parent" WHERE user_id = auth.uid())
  AND child_id IN (
    SELECT pc.child_id FROM "public"."parent_and_child" pc
    INNER JOIN "public"."parent" p ON pc.parent_id = p.parent_id
    WHERE p.user_id = auth.uid()
  )
);

CREATE POLICY "Parents can update their children's activity records"
ON "public"."activity_record" FOR UPDATE
USING (parent_id IN (SELECT parent_id FROM "public"."parent" WHERE user_id = auth.uid()))
WITH CHECK (parent_id IN (SELECT parent_id FROM "public"."parent" WHERE user_id = auth.uid()));

CREATE POLICY "Parents can delete their children's activity records"
ON "public"."activity_record" FOR DELETE
USING (parent_id IN (SELECT parent_id FROM "public"."parent" WHERE user_id = auth.uid()));
```

### ขั้นตอนที่ 2: แก้ไข Hardcoded Child ID

เปิดไฟล์ `flutter_app/lib/providers/user_provider.dart` และแก้ไขดังนี้:

1. เพิ่ม method `fetchChildrenData()` ตามตัวอย่างข้างบน
2. เรียกใช้หลังจาก login สำเร็จ
3. ตรวจสอบว่า `_currentChildId` มีค่าจริงจาก database

### ขั้นตอนที่ 3: Rebuild และ Restart

```bash
# Backend
cd my-cms-app
npm run dev

# Flutter
cd flutter_app
flutter clean
flutter pub get
flutter run
```

### ขั้นตอนที่ 4: ทดสอบ

1. เปิด Flutter app
2. Login ด้วย Supabase auth
3. ตรวจสอบ console logs:
   ```
   📱 Current Session: eyJhbG...
   📱 Current User: abc123...
   📦 Payload to Backend: {childId: real-uuid-here, ...}
   ```
4. เล่นกิจกรรมภาษาจนจบ
5. กด "Finish"
6. ตรวจสอบว่า:
   - ไม่มี 401 Unauthorized error
   - ได้รับ response success
   - คะแนนถูกบันทึกใน database
   - wallet ของเด็กเพิ่มขึ้น

## Debug Tips 🔍

### ถ้ายังได้ 401 Unauthorized:

1. **ตรวจสอบ Token ที่ส่งไป:**
   ```dart
   // ใน activity_service.dart ก่อน post
   final session = Supabase.instance.client.auth.currentSession;
   print('🔐 Sending token: ${session?.accessToken?.substring(0, 20)}...');
   ```

2. **ตรวจสอบ API logs:**
   ```bash
   # ใน my-cms-app terminal
   # จะเห็น Authorization header ถูกส่งมาหรือไม่
   ```

3. **ตรวจสอบ Supabase User:**
   ```dart
   final user = await Supabase.instance.client.auth.getUser();
   print('👤 User ID: ${user.user?.id}');
   ```

### ถ้า childId ยังเป็น CHILD_001:

1. ตรวจสอบว่าเรียก `fetchChildrenData()` หรือยัง
2. ดูใน database ว่ามี child records หรือไม่
3. ตรวจสอบ parent_and_child table มี relationship หรือไม่

### ถ้า score เป็น 0:

นั่นเป็นปัญหาต่างหาก - เกี่ยวกับการคำนวณคะแนนจาก AI evaluation
ดูที่ `segmentResults` แต่ละตัวว่า `maxScore` เป็น 0 ทั้งหมด

## สรุป

หลังจากแก้ไขทั้งหมด:
- ✅ API endpoint รองรับ Flutter authentication แล้ว
- ✅ ApiService ส่ง Bearer token แล้ว
- ✅ Database schema และ RLS policies พร้อมแล้ว
- ⚠️ ต้องแก้ hardcoded childId ให้เป็นข้อมูลจริง
- ⚠️ ต้องตรวจสอบว่า Flutter app มี Supabase session

**Next Step**: แก้ไข hardcoded childId แล้วทดสอบอีกครั้ง!
