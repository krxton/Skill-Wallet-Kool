// ต้อง import Child model ที่เราสร้างไว้ในไฟล์ child.dart
import 'child.dart';

class ChildLink {
  final String relationship;
  final Child child;

  ChildLink({
    required this.relationship,
    required this.child,
  });

  // สร้าง Object จาก JSON ที่ได้จาก Parent API
  // รูปแบบ JSON: { "relationship": "Mother", "child": { ... Child Data ... } }
  factory ChildLink.fromJson(Map<String, dynamic> json) {
    return ChildLink(
      relationship: json['relationship'],
      // ใช้ Child.fromJson เพื่อแปลง Child Data ที่อยู่ข้างใน
      child: Child.fromJson(json['child']),
    );
  }
}
