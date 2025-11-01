// src/app/api/ai-evaluation/route.ts (Backend CMS/AI Logic - Final Fix)

import { NextRequest, NextResponse } from 'next/server';
import fs from "fs"; // 🆕 สำหรับจัดการไฟล์
import path from "path"; // 🆕 สำหรับจัดการพาธ
import os from "os"; // 🆕 แก้ไข Error: สำหรับ os.tmpdir()
import { spawnSync } from "child_process"; // 🆕 สำหรับรัน Python

// ⚠️ CORS Headers: ตรวจสอบ Origin ของ Flutter App
const corsHeaders = {
    'Access-Control-Allow-Origin': 'http://192.168.1.58:3000', 
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
};


// ----------------------------------------------------
// 1. GET Handler (สำหรับดูข้อมูล/ทดสอบสถานะ)
// ----------------------------------------------------
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


// ----------------------------------------------------
// 2. POST Handler (รับไฟล์เสียงจริงและรัน AI)
// ----------------------------------------------------
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
        
        // 🆕 แก้ไข: ใช้ os.tmpdir() เพื่อให้ไฟล์ถูกเขียนในโฟลเดอร์ Temp ที่ถูกต้อง
        tmpFilePath = path.join(os.tmpdir(), `tmp_audio_${fileId}.${fileExtension}`); 
        
        fs.writeFileSync(tmpFilePath, buffer);

        // 2. 🟢 รัน Python script (WHISPER EVAL)
        const pythonScriptPath = path.join(process.cwd(), "scripts", "whisper_eval.py"); 
        const pythonCmd = process.platform === "win32" ? "python" : "python3";
        
        const result = spawnSync(pythonCmd, [pythonScriptPath, tmpFilePath, originalText], {
            encoding: "utf-8",
            // 💡 เพิ่ม env: { PYTHONIOENCODING: 'utf-8' } เพื่อช่วยแก้ปัญหา encoding ใน Python
            env: { ...process.env, PYTHONIOENCODING: 'utf-8' } 
        });

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


// ----------------------------------------------------
// 3. OPTIONS Handler (CORS)
// ----------------------------------------------------
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, { headers: corsHeaders });
}