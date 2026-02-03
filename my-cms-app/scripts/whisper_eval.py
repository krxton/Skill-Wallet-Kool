# scripts/whisper_eval.py
import sys
import json
import whisper
import subprocess
import tempfile
import os
import re

# Fix UTF-8
try:
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')
except:
    pass

if len(sys.argv) < 3:
    print(json.dumps({"error": "Usage: python whisper_eval.py <audio_path> <expected_text_path>"}))
    sys.exit(1)

audio_path = sys.argv[1]
expected_text_path = sys.argv[2]

# ---------------------------
# Utils
# ---------------------------
def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text)
    return text.strip()

# ---------------------------
# Load expected text safely
# ---------------------------
with open(expected_text_path, "r", encoding="utf-8") as f:
    expected_text = f.read()

# ---------------------------
# Normalize audio (🔥 สำคัญ)
# ---------------------------
normalized_audio = tempfile.NamedTemporaryFile(
    suffix=".wav",
    delete=False
)

try:
    subprocess.run(
        [
            "ffmpeg",
            "-y",
            "-i", audio_path,
            "-ac", "1",
            "-ar", "16000",
            normalized_audio.name
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=True
    )
except Exception as e:
    print(json.dumps({"error": f"FFmpeg error: {str(e)}"}))
    sys.exit(1)

# ---------------------------
# Whisper
# ---------------------------
try:
    model = whisper.load_model("base")

    result = model.transcribe(
        normalized_audio.name,
        language="en",
        fp16=False
    )

    recognized_text_raw = result["text"]
    recognized_text = clean_text(recognized_text_raw)
    cleaned_expected = clean_text(expected_text)

    expected_words = cleaned_expected.split()
    recognized_words = recognized_text.split()

    expected_counts = {}
    for w in expected_words:
        expected_counts[w] = expected_counts.get(w, 0) + 1

    match_count = 0
    for w in recognized_words:
        if w in expected_counts and expected_counts[w] > 0:
            match_count += 1
            expected_counts[w] -= 1

    accuracy = 100 if not expected_words else min(
        int(match_count / len(expected_words) * 100),
        100
    )

    print(json.dumps({
        "text": recognized_text_raw,
        "score": accuracy
    }, ensure_ascii=False))

except Exception as e:
    print(json.dumps({"error": f"Whisper error: {str(e)}"}))
    sys.exit(1)

finally:
    if os.path.exists(normalized_audio.name):
        normalized_audio.close()
        os.unlink(normalized_audio.name)
