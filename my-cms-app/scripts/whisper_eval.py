# scripts/whisper_eval.py

import sys
import json
import whisper
import os
import re

# การตั้งค่า Encoding สำหรับ stdout (สำคัญมากสำหรับ Windows/UTF-8)
try:
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except AttributeError:
    pass

if len(sys.argv) < 3:
    print(json.dumps({"error": "Usage: python whisper_eval.py <audio_path> <expected_text>"}))
    sys.exit(1)

audio_path = sys.argv[1]
expected_text = sys.argv[2]

# ----------------------------------------------------------------
# Utility: Clean Text (ลบเครื่องหมายวรรคตอน)
# ----------------------------------------------------------------
def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text)  # ลบเครื่องหมายวรรคตอน
    return text.strip()

try:
    # โหลดโมเดล Whisper 
    model = whisper.load_model("base")

    # ถอดเสียง
    # 🆕 เพิ่ม initial_prompt เพื่อช่วยให้ AI รู้ว่าต้องพูดภาษาอังกฤษ
    result = model.transcribe(
        audio_path,
        language="en",
        initial_prompt="This is an English sentence."
    )
    recognized_text_raw = result["text"]

    # ทำความสะอาดข้อความ
    recognized_text = clean_text(recognized_text_raw)
    cleaned_expected = clean_text(expected_text)

    # ----------------------------------------------------------------
    # คำนวณความถูกต้อง (Fixed Matching Logic)
    # ----------------------------------------------------------------
    expected_words = cleaned_expected.split()
    recognized_words = recognized_text.split()

    # 🆕 1. สร้าง Frequency Map ของคำที่คาดหวัง
    expected_word_counts = {}
    for word in expected_words:
        expected_word_counts[word] = expected_word_counts.get(word, 0) + 1

    match_count = 0

    # 🆕 2. นับคำที่ตรงกันอย่างแม่นยำและป้องกันการนับซ้ำซ้อน
    for rec_word in recognized_words:
        if rec_word in expected_word_counts and expected_word_counts[rec_word] > 0:
            match_count += 1
            expected_word_counts[rec_word] -= 1  # ลดจำนวนนับเมื่อจับคู่แล้ว

    # 3. คำนวณ Accuracy
    if len(expected_words) == 0:
        accuracy = 100
    else:
        # คำนวณ: (จำนวนคำที่ตรงกัน) / (จำนวนคำที่คาดหวัง) * 100
        accuracy = int(match_count / len(expected_words) * 100)
        accuracy = min(accuracy, 100)

    # 🆕 Debug Log
    print(f"DEBUG: Expected Text: {expected_text}", file=sys.stderr)
    print(f"DEBUG: Clean Rec Text: {recognized_text}", file=sys.stderr)
    print(f"DEBUG: Match Count: {match_count} / {len(expected_words)}", file=sys.stderr)

    # ส่งออก JSON
    output_json = {
        "text": recognized_text_raw,
        "score": accuracy
    }

    print(json.dumps(output_json, ensure_ascii=False))

except Exception as e:
    print(json.dumps({"error": f"Python AI Runtime Error: {str(e)}", "path": audio_path}), file=sys.stderr)
    sys.exit(1)
