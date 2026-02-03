// src/app/api/ai-evaluation/route.ts

import { NextRequest, NextResponse } from 'next/server';
import fs from "fs";
import path from "path";
import os from "os";
import { spawnSync } from "child_process";

// ⚠️ CORS Headers: ตรวจสอบ Origin ของ Flutter App
const corsHeaders = {
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-requested-with',
    'Access-Control-Max-Age': '86400',
};

/**
 * @swagger
 * /api/ai-evaluation:
 *   get:
 *     tags:
 *       - AI Evaluation
 *     summary: ตรวจสอบสถานะ AI Evaluation Endpoint
 *     description: |
 *       ใช้สำหรับตรวจสอบว่า API พร้อมใช้งานหรือไม่
 *       - แสดงเวอร์ชัน API
 *       - แสดงคำแนะนำการใช้งาน
 *     responses:
 *       200:
 *         description: API พร้อมใช้งาน
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   description: สถานะของ API
 *                   example: "AI Evaluation Endpoint Ready"
 *                 version:
 *                   type: string
 *                   description: เวอร์ชันของ API
 *                   example: "1.0"
 *                 instructions:
 *                   type: string
 *                   description: คำแนะนำการใช้งาน
 *                   example: "Use POST method with audio file (multipart/form-data) and text field to trigger AI evaluation."
 *             example:
 *               status: "AI Evaluation Endpoint Ready"
 *               version: "1.0"
 *               instructions: "Use POST method with audio file (multipart/form-data) and text field to trigger AI evaluation."
 */
export async function GET(request: NextRequest) {
    return NextResponse.json(
        { 
            status: 'AI Evaluation Endpoint Ready',
            version: '1.0',
            instructions: 'Use POST method with audio file (multipart/form-data) and text field to trigger AI evaluation.',
        }, 
        { status: 200, headers: corsHeaders }
    );
}

/**
 * @swagger
 * /api/ai-evaluation:
 *   post:
 *     tags:
 *       - AI Evaluation
 *     summary: ประเมินไฟล์เสียงด้วย AI (Whisper)
 *     description: |
 *       รับไฟล์เสียงและข้อความต้นฉบับ จากนั้นประมวลผลด้วย Python Whisper Script
 *       - รองรับไฟล์เสียงหลายรูปแบบ (m4a, mp3, wav, etc.)
 *       - ใช้ OpenAI Whisper สำหรับแปลงเสียงเป็นข้อความ
 *       - เปรียบเทียบข้อความที่แปลงได้กับข้อความต้นฉบับ
 *       - คำนวณคะแนนความแม่นยำ
 *       
 *       **หมายเหตุ**: API นี้ต้องการ Python และ Whisper ติดตั้งในเซิร์ฟเวอร์
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *               - text
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: |
 *                   ไฟล์เสียงที่ต้องการประเมิน
 *                   - รองรับ: m4a, mp3, wav, ogg, flac
 *                   - ขนาดไฟล์แนะนำ: ไม่เกิน 10MB
 *               text:
 *                 type: string
 *                 description: ข้อความต้นฉบับที่ถูกต้อง (สำหรับเปรียบเทียบ)
 *                 example: "สวัสดีครับ วันนี้อากาศดีมาก"
 *           encoding:
 *             file:
 *               contentType: audio/m4a, audio/mpeg, audio/wav, audio/ogg, audio/flac
 *     responses:
 *       200:
 *         description: ประเมินสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 transcribed_text:
 *                   type: string
 *                   description: ข้อความที่แปลงได้จาก Whisper
 *                   example: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                 original_text:
 *                   type: string
 *                   description: ข้อความต้นฉบับ
 *                   example: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                 similarity_score:
 *                   type: number
 *                   format: float
 *                   description: คะแนนความแม่นยำ (0-100)
 *                   example: 95.5
 *                 is_correct:
 *                   type: boolean
 *                   description: ถูกต้องหรือไม่ (ตาม threshold)
 *                   example: true
 *                 word_error_rate:
 *                   type: number
 *                   format: float
 *                   description: อัตราข้อผิดพลาดของคำ (WER)
 *                   example: 0.05
 *                 processing_time:
 *                   type: number
 *                   format: float
 *                   description: เวลาที่ใช้ในการประมวลผล (วินาที)
 *                   example: 2.45
 *             examples:
 *               perfectMatch:
 *                 summary: ตัวอย่างการออกเสียงที่ถูกต้อง 100%
 *                 value:
 *                   transcribed_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 100
 *                   is_correct: true
 *                   word_error_rate: 0
 *                   processing_time: 2.3
 *               goodMatch:
 *                 summary: ตัวอย่างการออกเสียงที่ดี (มีข้อผิดพลาดเล็กน้อย)
 *                 value:
 *                   transcribed_text: "สวัสดีครับ วันนี้อากาศดี"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 87.5
 *                   is_correct: true
 *                   word_error_rate: 0.125
 *                   processing_time: 2.1
 *               poorMatch:
 *                 summary: ตัวอย่างการออกเสียงที่ไม่ถูกต้อง
 *                 value:
 *                   transcribed_text: "สวัสดี วันนี้อากาศร้อน"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 45.2
 *                   is_correct: false
 *                   word_error_rate: 0.548
 *                   processing_time: 1.9
 *       400:
 *         description: Bad Request - ข้อมูลไม่ครบหรือไม่ถูกต้อง
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               missingFile:
 *                 summary: ไม่มีไฟล์เสียง
 *                 value:
 *                   error: "Missing audio file or original text."
 *               invalidFormat:
 *                 summary: รูปแบบไฟล์ไม่ถูกต้อง
 *                 value:
 *                   error: "Unsupported audio format. Please use m4a, mp3, wav, ogg, or flac."
 *       500:
 *         description: Internal Server Error - ข้อผิดพลาดในการประมวลผล
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                 raw:
 *                   type: string
 *                   description: ข้อมูล output ดิบจาก Python (ถ้ามี)
 *             examples:
 *               pythonError:
 *                 summary: Python script error
 *                 value:
 *                   error: "Python exited with code 1"
 *               jsonParseError:
 *                 summary: ไม่สามารถ parse JSON ได้
 *                 value:
 *                   error: "Invalid JSON from whisper_eval.py"
 *                   raw: "Traceback (most recent call last)..."
 *               fileError:
 *                 summary: ข้อผิดพลาดในการจัดการไฟล์
 *                 value:
 *                   error: "Internal Server Error during AI process."
 */
export async function POST(request: NextRequest) {
    const errorCorsHeaders = {
        'Access-Control-Allow-Origin': corsHeaders['Access-Control-Allow-Origin'],
    };

    let tmpFilePath: string | null = null;
    
    try {
        const formData = await request.formData();
        const file = formData.get("file") as File;
        const originalText = formData.get("text")?.toString() || "";
        const mimeType = file.type || "audio/m4a"; 

        if (!file || !originalText) {
            return NextResponse.json({ error: "Missing audio file or original text." }, { status: 400, headers: errorCorsHeaders });
        }
        
        // 1. 🟢 เขียนไฟล์เสียงชั่วคราว
        const buffer = Buffer.from(await file.arrayBuffer());
        const fileExtension = mimeType.split('/')[1] || 'm4a'; 
        const fileId = Math.random().toString(36).substring(2, 9);
        
        tmpFilePath = path.join(os.tmpdir(), `tmp_audio_${fileId}.${fileExtension}`); 
        
        fs.writeFileSync(tmpFilePath, buffer);

        // 2. 🟢 รัน Python script (WHISPER EVAL)
        const pythonScriptPath = path.join(process.cwd(), "scripts", "whisper_eval.py");
        const pythonCmd = process.platform === "win32" ? "python" : "python3";

        // 2.1 🟢 เขียน expected text ลงไฟล์ชั่วคราว (แก้ปัญหา argv แตก)
        const textPath = path.join(os.tmpdir(), `expected_${fileId}.txt`);
        fs.writeFileSync(textPath, originalText, "utf-8");

        // 2.2 🟢 รัน Python script
        const result = spawnSync(
        pythonCmd,
        [pythonScriptPath, tmpFilePath, textPath],
        {
            encoding: "utf-8",
            env: { ...process.env, PYTHONIOENCODING: "utf-8" },
        }
        );

        // 2.3 🟢 ลบไฟล์ข้อความชั่วคราว
        fs.unlinkSync(textPath);

        // 3. ลบไฟล์ชั่วคราวทันทีหลังการใช้งาน
        fs.unlinkSync(tmpFilePath);
        tmpFilePath = null; 

        // 4. ตรวจสอบ Error จาก Python
        if (result.status !== 0) {
            console.error("Python stderr:", result.stderr);
            return NextResponse.json({ error: result.stderr || `Python exited with code ${result.status}` }, { status: 500, headers: errorCorsHeaders });
        }

        // 5. Parse JSON Output
        try {
            const output = JSON.parse(result.stdout.trim()); 
            
            // 6. ส่งผลลัพธ์ JSON 200 OK กลับไปยัง Flutter
            return NextResponse.json(output, { headers: corsHeaders });

        } catch (err) {
            console.error('JSON Parsing Error:', err);
            return NextResponse.json(
                { error: "Invalid JSON from whisper_eval.py", raw: result.stdout.substring(0, 500) },
                { status: 500, headers: errorCorsHeaders }
            );
        }
    } catch (error: any) {
        // ⚠️ จัดการ Error ในการจัดการไฟล์
        if (tmpFilePath && fs.existsSync(tmpFilePath)) {
             fs.unlinkSync(tmpFilePath);
        }
        console.error('AI Evaluation Process Error:', error);
        return NextResponse.json({ error: error.message || "Internal Server Error during AI process." }, { status: 500, headers: errorCorsHeaders });
    }
}

/**
 * @swagger
 * /api/ai-evaluation:
 *   options:
 *     tags:
 *       - AI Evaluation
 *     summary: CORS Preflight Request
 *     description: จัดการ CORS preflight request สำหรับ cross-origin requests
 *     responses:
 *       200:
 *         description: CORS headers returned
 *         headers:
 *           Access-Control-Allow-Origin:
 *             schema:
 *               type: string
 *               example: "*"
 *           Access-Control-Allow-Methods:
 *             schema:
 *               type: string
 *               example: "POST, GET, OPTIONS"
 *           Access-Control-Allow-Headers:
 *             schema:
 *               type: string
 *               example: "Content-Type, Authorization, x-requested-with"
 *           Access-Control-Max-Age:
 *             schema:
 *               type: string
 *               example: "86400"
 */
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, { headers: corsHeaders });
}