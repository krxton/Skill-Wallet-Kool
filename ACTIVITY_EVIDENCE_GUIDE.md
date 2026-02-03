# คู่มือการเก็บหลักฐานการเล่นกิจกรรม (Activity Evidence Guide)

## ภาพรวม

ตาราง `activity_record` มี 2 columns สำหรับเก็บหลักฐานการเล่น:

1. **`segment_results`** (JSONB) - ผลลัพธ์แต่ละส่วน/คำถาม
2. **`evidence`** (JSONB) - หลักฐานเพิ่มเติม (รูป, วิดีโอ, คำอธิบาย)

---

## 1. กิจกรรมภาษา (ด้านภาษา)

### segment_results
เก็บคะแนนของแต่ละประโยคที่เด็กพูด:

```json
[
  {
    "id": "seg_cmk9ewagx0000356",
    "text": "What will you do for the New Year?",
    "maxScore": 95,
    "recognizedText": "What will you do for the new year",
    "audioUrl": "https://storage.supabase.co/.../audio_seg1.m4a",
    "timestamp": 1.5
  },
  {
    "id": "seg_cmk9ewagx0001356",
    "text": "I will go to a party with my family",
    "maxScore": 88,
    "recognizedText": "I will go to party with my family",
    "audioUrl": "https://storage.supabase.co/.../audio_seg2.m4a",
    "timestamp": 5.2
  }
]
```

### evidence
เก็บข้อมูลภาพรวมและการประเมินจาก AI:

```json
{
  "type": "language",
  "category": "listening_speaking",
  "videoUrl": "https://youtube.com/...",
  "totalSegments": 7,
  "averageAccuracy": 91.5,
  "completionTime": 180,
  "aiEvaluation": {
    "overallPronunciation": "good",
    "fluency": "excellent",
    "confidence": 0.92,
    "improvements": [
      "Practice 'th' sound in 'the'",
      "Work on sentence rhythm"
    ]
  },
  "metadata": {
    "deviceType": "mobile",
    "appVersion": "1.0.0",
    "recordingQuality": "high"
  }
}
```

### ตัวอย่างการ Query

```sql
-- หาประโยคที่ได้คะแนนต่ำกว่า 70
SELECT
  ar.ActivityRecord_id,
  c.name_surname,
  sr->>'text' as sentence,
  sr->>'maxScore' as score
FROM activity_record ar
JOIN child c ON ar.child_id = c.child_id,
jsonb_array_elements(ar.segment_results) sr
WHERE (sr->>'maxScore')::int < 70
ORDER BY (sr->>'maxScore')::int ASC;

-- หาเด็กที่มีคะแนนเฉลี่ยสูง
SELECT
  c.name_surname,
  AVG((ar.evidence->>'averageAccuracy')::float) as avg_accuracy
FROM activity_record ar
JOIN child c ON ar.child_id = c.child_id
WHERE ar.evidence->>'type' = 'language'
GROUP BY c.child_id, c.name_surname
ORDER BY avg_accuracy DESC;
```

---

## 2. กิจกรรมร่างกาย (ด้านร่างกาย)

### segment_results
สำหรับกิจกรรมร่างกาย อาจเก็บการทำท่าต่าง ๆ หรือขั้นตอน:

```json
[
  {
    "id": "step_1",
    "name": "ยืดเหยียดแขน",
    "completed": true,
    "duration": 30,
    "photoUrl": "https://storage.supabase.co/.../step1.jpg",
    "score": 10
  },
  {
    "id": "step_2",
    "name": "กระโดดแยกขา",
    "completed": true,
    "duration": 45,
    "photoUrl": "https://storage.supabase.co/.../step2.jpg",
    "score": 10
  },
  {
    "id": "step_3",
    "name": "วิ่งข้ามสิ่งกีดขวาง",
    "completed": false,
    "duration": 0,
    "reason": "เด็กเหนื่อย",
    "score": 0
  }
]
```

### evidence
เก็บรูปภาพ, วิดีโอ, และคำอธิบายจากผู้ปกครอง:

```json
{
  "type": "physical",
  "category": "exercise",
  "photos": [
    "https://storage.supabase.co/.../photo1.jpg",
    "https://storage.supabase.co/.../photo2.jpg",
    "https://storage.supabase.co/.../photo3.jpg"
  ],
  "videos": [
    {
      "url": "https://storage.supabase.co/.../video.mp4",
      "duration": 120,
      "thumbnail": "https://storage.supabase.co/.../thumb.jpg"
    }
  ],
  "tiktokUrl": "https://tiktok.com/@user/video/123456",
  "parentNote": "เด็กทำได้ดีมาก มีความกระตือรือร้น",
  "parentRating": 5,
  "difficulty": "easy",
  "weather": "sunny",
  "location": "home",
  "equipment": ["jump rope", "ball"],
  "caloriesBurned": 85,
  "metadata": {
    "uploadDate": "2026-02-02T10:30:00Z",
    "deviceType": "mobile",
    "cameraQuality": "1080p"
  }
}
```

### การอัปโหลดรูปภาพ

```typescript
// ตัวอย่าง Flutter code สำหรับอัปโหลดรูป
async function uploadPhysicalEvidence(file: File, childId: string) {
  const fileName = `physical/${childId}/${Date.now()}_${file.name}`;

  // Upload to Supabase Storage
  const { data, error } = await supabase.storage
    .from('activity-evidence')
    .upload(fileName, file);

  if (error) throw error;

  // Get public URL
  const { data: { publicUrl } } = supabase.storage
    .from('activity-evidence')
    .getPublicUrl(fileName);

  return publicUrl;
}
```

### ตัวอย่างการ Query

```sql
-- หากิจกรรมที่มีรูปภาพมากกว่า 2 รูป
SELECT
  ar.ActivityRecord_id,
  a.name_activity,
  jsonb_array_length(ar.evidence->'photos') as photo_count
FROM activity_record ar
JOIN activity a ON ar.activity_id = a.activity_id
WHERE ar.evidence->>'type' = 'physical'
AND jsonb_array_length(ar.evidence->'photos') > 2;

-- หา parent notes ทั้งหมด
SELECT
  c.name_surname as child_name,
  a.name_activity,
  ar.evidence->>'parentNote' as note,
  ar.evidence->>'parentRating' as rating
FROM activity_record ar
JOIN child c ON ar.child_id = c.child_id
JOIN activity a ON ar.activity_id = a.activity_id
WHERE ar.evidence->>'type' = 'physical'
AND ar.evidence->>'parentNote' IS NOT NULL;
```

---

## 3. กิจกรรมวิเคราะห์ (ด้านวิเคราะห์)

### segment_results
เก็บคำตอบของแต่ละข้อคำถาม:

```json
[
  {
    "questionId": "q_cmk9fwb001",
    "question": "2 + 2 = ?",
    "questionType": "math",
    "correctAnswer": "4",
    "userAnswer": "4",
    "isCorrect": true,
    "score": 10,
    "maxScore": 10,
    "timeSpent": 5.2,
    "attempts": 1
  },
  {
    "questionId": "q_cmk9fwb002",
    "question": "หาคำที่ไม่เข้าพวก: แมว, หมา, รถ, นก",
    "questionType": "logic",
    "correctAnswer": "รถ",
    "userAnswer": "นก",
    "isCorrect": false,
    "score": 0,
    "maxScore": 10,
    "timeSpent": 8.5,
    "attempts": 2,
    "hint": "คิดถึงสิ่งมีชีวิตกับสิ่งของ"
  },
  {
    "questionId": "q_cmk9fwb003",
    "question": "เรียงลำดับตัวเลข: 5, 2, 8, 1",
    "questionType": "sequence",
    "correctAnswer": "1, 2, 5, 8",
    "userAnswer": "1, 2, 5, 8",
    "isCorrect": true,
    "score": 15,
    "maxScore": 15,
    "timeSpent": 12.3,
    "attempts": 1
  }
]
```

### evidence
เก็บข้อมูลการวิเคราะห์และพัฒนาการ:

```json
{
  "type": "analytical",
  "category": "problem_solving",
  "totalQuestions": 10,
  "correctAnswers": 7,
  "incorrectAnswers": 3,
  "accuracy": 70,
  "totalTime": 180,
  "averageTimePerQuestion": 18,
  "performance": {
    "math": {
      "total": 4,
      "correct": 3,
      "accuracy": 75
    },
    "logic": {
      "total": 3,
      "correct": 2,
      "accuracy": 66.7
    },
    "sequence": {
      "total": 3,
      "correct": 2,
      "accuracy": 66.7
    }
  },
  "strengths": ["math", "pattern recognition"],
  "weaknesses": ["logical reasoning", "word problems"],
  "recommendations": [
    "ฝึกการหาความสัมพันธ์ระหว่างสิ่งของ",
    "เพิ่มการอ่านโจทย์ปัญหาคณิตศาสตร์"
  ],
  "difficulty": "medium",
  "parentNote": "เด็กตอบได้เร็ว แต่บางข้อรีบเกินไป",
  "metadata": {
    "completionDate": "2026-02-02T14:30:00Z",
    "deviceType": "tablet",
    "appVersion": "1.0.0"
  }
}
```

### ตัวอย่างการ Query

```sql
-- วิเคราะห์ประเภทคำถามที่เด็กทำผิดบ่อย
SELECT
  sr->>'questionType' as question_type,
  COUNT(*) as total_attempts,
  SUM(CASE WHEN (sr->>'isCorrect')::boolean THEN 1 ELSE 0 END) as correct_count,
  ROUND(
    SUM(CASE WHEN (sr->>'isCorrect')::boolean THEN 1 ELSE 0 END)::numeric / COUNT(*)::numeric * 100,
    2
  ) as accuracy_percentage
FROM activity_record ar,
jsonb_array_elements(ar.segment_results) sr
WHERE ar.evidence->>'type' = 'analytical'
GROUP BY sr->>'questionType'
ORDER BY accuracy_percentage ASC;

-- หาเด็กที่มีพัฒนาการดีในด้านวิเคราะห์
SELECT
  c.name_surname,
  COUNT(*) as activities_completed,
  AVG((ar.evidence->>'accuracy')::numeric) as avg_accuracy,
  MAX((ar.evidence->>'accuracy')::numeric) as best_accuracy
FROM activity_record ar
JOIN child c ON ar.child_id = c.child_id
WHERE ar.evidence->>'type' = 'analytical'
GROUP BY c.child_id, c.name_surname
HAVING AVG((ar.evidence->>'accuracy')::numeric) > 70
ORDER BY avg_accuracy DESC;

-- หา strengths และ weaknesses ที่พบบ่อย
SELECT
  strength,
  COUNT(*) as frequency
FROM activity_record ar,
jsonb_array_elements_text(ar.evidence->'strengths') as strength
WHERE ar.evidence->>'type' = 'analytical'
GROUP BY strength
ORDER BY frequency DESC
LIMIT 10;
```

---

## การอัปเดต API Payload (Flutter)

### ปัจจุบัน (กิจกรรมภาษา)
```dart
final payload = {
  'childId': childId,
  'activityId': activityId,
  'totalScoreEarned': finalScore,
  'segmentResults': segmentResults, // ✅ มีแล้ว
  'evidence': evidence, // ✅ มีแล้ว
  'parentScore': parentScore,
};
```

### สำหรับกิจกรรมร่างกาย (ต้องเพิ่ม)
```dart
// 1. อัปโหลดรูปก่อน
List<String> uploadedPhotoUrls = [];
for (var photo in selectedPhotos) {
  final url = await uploadToSupabase(photo);
  uploadedPhotoUrls.add(url);
}

// 2. สร้าง payload
final payload = {
  'childId': childId,
  'activityId': activityId,
  'totalScoreEarned': totalScore,
  'segmentResults': steps, // ขั้นตอนการทำกิจกรรม
  'evidence': {
    'type': 'physical',
    'photos': uploadedPhotoUrls,
    'videoUrl': videoUrl,
    'parentNote': parentNoteController.text,
    'parentRating': rating,
    'difficulty': selectedDifficulty,
  },
  'timeSpent': stopwatch.elapsedSeconds,
};
```

### สำหรับกิจกรรมวิเคราะห์ (ต้องเพิ่ม)
```dart
final payload = {
  'childId': childId,
  'activityId': activityId,
  'totalScoreEarned': correctAnswers * pointsPerQuestion,
  'segmentResults': questionResults.map((q) => {
    'questionId': q.id,
    'question': q.question,
    'questionType': q.type,
    'correctAnswer': q.correctAnswer,
    'userAnswer': q.userAnswer,
    'isCorrect': q.isCorrect,
    'score': q.score,
    'maxScore': q.maxScore,
    'timeSpent': q.timeSpent,
    'attempts': q.attempts,
  }).toList(),
  'evidence': {
    'type': 'analytical',
    'totalQuestions': questions.length,
    'correctAnswers': correctAnswers,
    'incorrectAnswers': incorrectAnswers,
    'accuracy': (correctAnswers / questions.length * 100),
    'totalTime': totalTime,
    'performance': performanceByType,
    'strengths': identifiedStrengths,
    'weaknesses': identifiedWeaknesses,
  },
  'timeSpent': totalTime,
};
```

---

## การสร้าง Report/Dashboard

### ตัวอย่าง Query สำหรับ Dashboard

```sql
-- สรุปพัฒนาการรายเดือน
SELECT
  c.name_surname,
  DATE_TRUNC('month', ar.date) as month,
  COUNT(*) as activities_completed,
  SUM(ar.point) as total_points,
  AVG((ar.evidence->>'accuracy')::numeric) as avg_accuracy,
  jsonb_agg(DISTINCT ar.evidence->'strengths') as all_strengths
FROM activity_record ar
JOIN child c ON ar.child_id = c.child_id
WHERE ar.date >= NOW() - INTERVAL '6 months'
GROUP BY c.child_id, c.name_surname, DATE_TRUNC('month', ar.date)
ORDER BY month DESC;

-- หากิจกรรมที่ต้องปรับปรุง
SELECT
  a.name_activity,
  AVG(ar.point) as avg_score,
  COUNT(*) as attempts,
  jsonb_agg(DISTINCT ar.evidence->'weaknesses') as common_weaknesses
FROM activity_record ar
JOIN activity a ON ar.activity_id = a.activity_id
WHERE ar.child_id = 'some-child-id'
GROUP BY a.activity_id, a.name_activity
HAVING AVG(ar.point) < (a.maxscore * 0.7)
ORDER BY avg_score ASC;
```

---

## สรุป

### ข้อดีของการเก็บหลักฐาน:
1. ✅ **ติดตามพัฒนาการ** - เห็นความก้าวหน้าของเด็ก
2. ✅ **วิเคราะห์จุดแข็ง-จุดอ่อน** - ช่วยปรับกิจกรรมให้เหมาะสม
3. ✅ **รายงานให้ผู้ปกครอง** - แสดงหลักฐานการเล่นจริง
4. ✅ **ปรับปรุงกิจกรรม** - ดูว่าข้อไหนเด็กทำผิดบ่อย
5. ✅ **สร้าง Portfolio** - เก็บผลงานของเด็ก

### ขั้นตอนถัดไป:
1. Run migration: `add_evidence_to_activity_record.sql`
2. อัปเดต Flutter app ให้ส่ง evidence สำหรับทุกประเภทกิจกรรม
3. สร้าง UI สำหรับดูหลักฐาน/รายงาน
4. เพิ่มการอัปโหลดรูป/วิดีโอไป Supabase Storage
5. สร้าง dashboard วิเคราะห์พัฒนาการ
