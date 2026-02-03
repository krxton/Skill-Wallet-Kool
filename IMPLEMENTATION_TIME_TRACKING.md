# Implementation Guide: Time Tracking & Privacy-First Evidence

## 1. เพิ่ม Stopwatch ในกิจกรรมภาษา

### ใน Language Activity Screen

```dart
import 'package:flutter/material.dart';

class LanguageActivityScreen extends StatefulWidget {
  final Activity activity;

  const LanguageActivityScreen({required this.activity});

  @override
  State<LanguageActivityScreen> createState() => _LanguageActivityScreenState();
}

class _LanguageActivityScreenState extends State<LanguageActivityScreen> {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    // เริ่มจับเวลาเมื่อเปิดหน้า
    _stopwatch.start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  // เมื่อกด Finish
  Future<void> _handleFinish() async {
    _stopwatch.stop();
    final timeSpentInSeconds = _stopwatch.elapsed.inSeconds;

    print('⏱️ Time spent: $timeSpentInSeconds seconds');

    // ส่งไป API
    await activityService.finalizeQuest(
      childId: childId,
      activityId: widget.activity.id,
      segmentResults: segmentResults,
      activityMaxScore: widget.activity.maxScore,
      timeSpent: timeSpentInSeconds, // 🆕 ส่งเวลา
      evidence: {
        'type': 'language',
        'totalSegments': segmentResults.length,
        'averageAccuracy': calculateAverageAccuracy(),
        'completedSegments': segmentResults.where((s) => s.maxScore > 0).length,
      },
    );

    // ❌ ลบไฟล์เสียงทั้งหมด
    await _deleteAllAudioFiles();
  }

  // ลบไฟล์เสียงหลังเสร็จกิจกรรม
  Future<void> _deleteAllAudioFiles() async {
    try {
      for (var segment in segmentResults) {
        if (segment.audioUrl != null && segment.audioUrl!.startsWith('/')) {
          // เป็น local path
          final file = File(segment.audioUrl!);
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Deleted audio: ${segment.audioUrl}');
          }
        }
      }
    } catch (e) {
      print('⚠️ Error deleting audio files: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity.name),
        actions: [
          // แสดงเวลา (optional)
          StreamBuilder(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, snapshot) {
              final elapsed = _stopwatch.elapsed;
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ... activity content
          ElevatedButton(
            onPressed: _handleFinish,
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}
```

---

## 2. อัปเดต ActivityService - เพิ่ม timeSpent

```dart
// lib/services/activity_service.dart

Future<Map<String, dynamic>> finalizeQuest({
  required String childId,
  required String activityId,
  required List<SegmentResult> segmentResults,
  required int activityMaxScore,
  Map<String, dynamic>? evidence,
  int? parentScore,
  int? timeSpent, // 🆕 เพิ่ม parameter
}) async {
  final numSections = segmentResults.length;

  // คำนวณคะแนน
  double totalAccuracy = 0.0;
  for (var res in segmentResults) {
    totalAccuracy += res.maxScore;
  }
  final averageAccuracy = numSections > 0 ? (totalAccuracy / numSections) : 0.0;
  final scoreEarned = (activityMaxScore * (averageAccuracy / 100)).floor();
  final int finalScore = parentScore ?? scoreEarned;

  // สร้าง Payload
  final payload = {
    'childId': childId,
    'activityId': activityId,
    'totalScoreEarned': finalScore,
    'timeSpent': timeSpent, // 🆕 ส่งเวลา
    'segmentResults': segmentResults.map((r) => {
      'id': r.id,
      'text': r.text,
      'score': r.maxScore,
      'recognizedText': r.recognizedText,
      // ❌ ไม่ส่ง audioUrl
    }).toList(),
    'evidence': evidence,
  };

  print('📦 Payload: $payload');

  try {
    final res = await _apiService.post('/complete-quest', payload);
    res['scoreEarned'] = finalScore;
    res['calculatedScore'] = parentScore ?? averageAccuracy.round();
    return res;
  } catch (e) {
    debugPrint('Finalize Quest Error: $e');
    throw Exception('Failed to finalize quest and save record.');
  }
}
```

---

## 3. การจัดการไฟล์เสียง - เก็บชั่วคระหน่ามีการใช้งาน

### บันทึกเสียงไปที่ Temporary Directory

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorder {
  final Record _recorder = Record();

  // บันทึกเสียงไปที่ temp directory
  Future<String?> startRecording(String segmentId) async {
    try {
      if (await _recorder.hasPermission()) {
        // ใช้ temporary directory - iOS/Android จะลบให้อัตโนมัติ
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/audio_$segmentId.m4a';

        await _recorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );

        print('🎤 Recording to temp: $filePath');
        return filePath;
      }
    } catch (e) {
      print('❌ Recording error: $e');
    }
    return null;
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    print('🎤 Recording saved: $path');
    return path;
  }

  // เล่นเสียงที่บันทึก (สำหรับ replay ก่อน finish)
  Future<void> playAudio(String path) async {
    // ใช้ AudioPlayer หรือ just_audio
  }
}
```

### ลบไฟล์เสียงหลัง Finish

```dart
Future<void> cleanupAudioFiles(List<SegmentResult> segments) async {
  for (var segment in segments) {
    if (segment.audioUrl != null) {
      try {
        final file = File(segment.audioUrl!);
        if (await file.exists()) {
          await file.delete();
          print('🗑️ Deleted: ${segment.audioUrl}');
        }
      } catch (e) {
        print('⚠️ Delete failed: $e');
      }
    }
  }

  // ลบ temp directory ทั้งหมด (optional - OS จะลบให้เอง)
  try {
    final tempDir = await getTemporaryDirectory();
    final audioFiles = tempDir.listSync().where((f) => f.path.contains('audio_'));
    for (var file in audioFiles) {
      await file.delete();
    }
  } catch (e) {
    print('⚠️ Cleanup error: $e');
  }
}
```

---

## 4. กิจกรรมร่างกาย - เก็บ Local Photo Path

### ถ่ายรูป/วิดีโอและเก็บ Path

```dart
import 'package:image_picker/image_picker.dart';

class PhysicalActivityScreen extends StatefulWidget {
  @override
  State<PhysicalActivityScreen> createState() => _PhysicalActivityScreenState();
}

class _PhysicalActivityScreenState extends State<PhysicalActivityScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _localPhotoPaths = [];
  String? _localVideoPath;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  // ถ่ายรูป
  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85, // ลดขนาดไฟล์
    );

    if (photo != null) {
      setState(() {
        _localPhotoPaths.add(photo.path);
      });
      print('📸 Photo saved locally: ${photo.path}');
    }
  }

  // บันทึกวิดีโอ
  Future<void> _recordVideo() async {
    final XFile? video = await _picker.pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 2),
    );

    if (video != null) {
      setState(() {
        _localVideoPath = video.path;
      });
      print('🎥 Video saved locally: ${video.path}');
    }
  }

  // Finish Activity
  Future<void> _handleFinish() async {
    _stopwatch.stop();

    final payload = {
      'childId': childId,
      'activityId': activityId,
      'totalScoreEarned': 100,
      'timeSpent': _stopwatch.elapsed.inSeconds,
      'segmentResults': [
        // ขั้นตอนต่าง ๆ
      ],
      'evidence': {
        'type': 'physical',
        'localPhotoPaths': _localPhotoPaths, // 🔒 เก็บ path ไม่ใช่ไฟล์
        'localVideoPath': _localVideoPath,
        'parentNote': _noteController.text,
        'parentRating': _rating,
        'device': Platform.isIOS ? 'iOS' : 'Android',
      },
    };

    await activityService.finalizeQuest(...);

    // ✅ ไฟล์ยังอยู่บนเครื่อง ไม่ถูกลบ
    // แอปสามารถเข้าถึงได้ผ่าน path
  }

  // แสดงรูปที่ถ่าย
  Widget _buildPhotoGallery() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _localPhotoPaths.length,
      itemBuilder: (context, index) {
        return Image.file(
          File(_localPhotoPaths[index]),
          fit: BoxFit.cover,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Physical Activity')),
      body: Column(
        children: [
          // Timer
          Text(
            'Time: ${_stopwatch.elapsed.inMinutes}:${(_stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          // Photo Gallery
          Expanded(child: _buildPhotoGallery()),

          // Buttons
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
              ),
              ElevatedButton.icon(
                onPressed: _recordVideo,
                icon: const Icon(Icons.videocam),
                label: const Text('Record Video'),
              ),
            ],
          ),

          ElevatedButton(
            onPressed: _handleFinish,
            child: const Text('Finish Activity'),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Permission Setup

### iOS - Info.plist

```xml
<key>NSCameraUsageDescription</key>
<string>ต้องการเข้าถึงกล้องเพื่อถ่ายรูป/วิดีโอกิจกรรม</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>ต้องการเข้าถึงอัลบั้มรูปเพื่อเลือกรูปภาพกิจกรรม</string>

<key>NSMicrophoneUsageDescription</key>
<string>ต้องการเข้าถึงไมโครโฟนเพื่อบันทึกเสียงสำหรับกิจกรรมภาษา</string>
```

### Android - AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

---

## 6. ดูรูป/วิดีโอที่บันทึกไว้ (จาก Local Path)

### หน้าแสดง Activity Record

```dart
class ActivityRecordDetailScreen extends StatelessWidget {
  final ActivityRecord record;

  const ActivityRecordDetailScreen({required this.record});

  @override
  Widget build(BuildContext context) {
    final evidence = record.evidence as Map<String, dynamic>?;
    final localPhotoPaths = evidence?['localPhotoPaths'] as List<dynamic>? ?? [];
    final localVideoPath = evidence?['localVideoPath'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Record')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // แสดงรูปภาพ
            if (localPhotoPaths.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: localPhotoPaths.length,
                itemBuilder: (context, index) {
                  final path = localPhotoPaths[index] as String;
                  final file = File(path);

                  // ตรวจสอบว่าไฟล์ยังอยู่หรือไม่
                  return FutureBuilder<bool>(
                    future: file.exists(),
                    builder: (context, snapshot) {
                      if (snapshot.data == true) {
                        return Image.file(file, fit: BoxFit.cover);
                      } else {
                        // ไฟล์ถูกลบหรือย้าย
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      }
                    },
                  );
                },
              ),

            // แสดงวิดีโอ
            if (localVideoPath != null)
              FutureBuilder<bool>(
                future: File(localVideoPath).exists(),
                builder: (context, snapshot) {
                  if (snapshot.data == true) {
                    return VideoPlayer(File(localVideoPath));
                  } else {
                    return const Text('Video not found');
                  }
                },
              ),

            // แสดงคะแนน
            Text('Score: ${record.point}'),
            Text('Time: ${record.timeSpent} seconds'),
          ],
        ),
      ),
    );
  }
}
```

---

## 7. Summary

### ✅ ที่ทำแล้ว:
1. เพิ่ม `Stopwatch` ในกิจกรรมภาษา
2. ส่ง `timeSpent` ไปยัง API
3. เสียงบันทึก: เก็บใน temp directory → ลบหลัง finish
4. รูป/วิดีโอ: เก็บ local path ไม่อัปโหลด

### ⚠️ ข้อควรระวัง:
- ไฟล์อาจหายถ้าลบแอป/clear data
- แจ้งผู้ใช้ว่า "ข้อมูลอยู่บนเครื่องเท่านั้น"
- ถ้าต้องการ backup ให้ผู้ใช้เองจัดการ (เช่น Google Photos)

### 📱 Permissions:
- Camera, Microphone, Photo Library
- แจ้งวัตถุประสงค์ชัดเจนใน permission description

### 🔒 Privacy Benefits:
- **PDPA Compliant** - ไม่เก็บข้อมูลส่วนบุคคลบนเซิร์ฟเวอร์
- **Cost Effective** - ไม่ต้องจ่าย cloud storage
- **User Control** - ผู้ใช้ควบคุมไฟล์เอง

---

## Next Steps:
1. ทดสอบบน iOS/Android จริง
2. จัดการกรณีไฟล์หาย (แสดง placeholder)
3. เพิ่มการแจ้งเตือนผู้ใช้เกี่ยวกับ data storage
