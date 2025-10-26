import 'package:flutter/foundation.dart';

/// ไปหน้า List
@immutable
class LangListArgs {
  final String topic; // เช่น "LANGUAGE TRAINING"
  final String level; // EASY | MEDIUM | DIFFICULT
  const LangListArgs(this.topic, this.level);
}

/// ไปหน้า Item intro / record
@immutable
class LangItemArgs {
  final int index;   // 1..N
  final String topic;
  final String level;
  const LangItemArgs(this.index, this.topic, this.level);
}

/// ส่งเวลาไปหน้า Result
@immutable
class LangResultArgs {
  final int index;
  final Duration time;
  const LangResultArgs(this.index, this.time);
}

/// ส่งผลกลับ (เช่น ทำสำเร็จ/เวลา)
@immutable
class LangResultPayload {
  final bool ok;
  final Duration time;
  const LangResultPayload(this.ok, this.time);
}
