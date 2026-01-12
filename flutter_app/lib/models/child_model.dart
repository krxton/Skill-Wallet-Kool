// lib/models/child_model.dart

class Child {
  final String? id; // ✅ nullable สำหรับตอนสร้างใหม่ (ยังไม่มี id จาก backend)
  final String fullName;
  final DateTime? dob;
  final int score;
  final int scoreUpdate; // ✅ เพิ่ม scoreUpdate จากไฟล์เดิม

  Child({
    this.id,
    required this.fullName,
    this.dob,
    this.score = 0,
    this.scoreUpdate = 0, // ✅ เพิ่ม default value
  });

  // ✅ Create Child from JSON (จาก Backend)
  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] as String?,
      fullName: json['fullName'] as String,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      score: json['score'] as int? ?? 0,
      scoreUpdate: json['scoreUpdate'] as int? ?? 0, // ✅ เพิ่ม scoreUpdate
    );
  }

  // ✅ Convert Child to JSON (ส่งไป Backend)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id, // ส่ง id ถ้ามี
      'fullName': fullName,
      if (dob != null) 'dob': dob!.toIso8601String(),
      'score': score,
      'scoreUpdate': scoreUpdate, // ✅ เพิ่ม scoreUpdate
    };
  }

  // ✅ Copy with method (สำหรับ update ค่าบางอย่าง)
  Child copyWith({
    String? id,
    String? fullName,
    DateTime? dob,
    int? score,
    int? scoreUpdate,
  }) {
    return Child(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dob: dob ?? this.dob,
      score: score ?? this.score,
      scoreUpdate: scoreUpdate ?? this.scoreUpdate,
    );
  }
}
