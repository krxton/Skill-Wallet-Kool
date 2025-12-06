// src/app/api/evaluate/route.ts (Proxy Route สำหรับ AI Evaluation)

import { NextRequest, NextResponse } from 'next/server';

const CMS_API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL;
const CMS_EVALUATION_PATH = '/ai-evaluation'; 
const CMS_EVAL_URL = `${CMS_API_BASE || 'http://localhost:8080/api'}${CMS_EVALUATION_PATH}`;

const corsHeaders = {
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-requested-with',
    'Access-Control-Max-Age': '86400',
};

/**
 * @swagger
 * /api/evaluate:
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
 *               example: "POST, OPTIONS"
 *           Access-Control-Allow-Headers:
 *             schema:
 *               type: string
 *               example: "Content-Type, Authorization, x-requested-with"
 */
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, { headers: corsHeaders });
}

/**
 * @swagger
 * /api/evaluate:
 *   post:
 *     tags:
 *       - AI Evaluation
 *     summary: Proxy สำหรับส่งต่อ AI Evaluation Request
 *     description: |
 *       **Proxy Endpoint** สำหรับส่งต่อไฟล์เสียงไปยัง Backend CMS ที่รัน AI Evaluation จริง
 *       
 *       **Architecture:**
 *       ```
 *       Flutter App → Next.js Proxy (/api/evaluate) → Backend CMS (/ai-evaluation) → Python Whisper
 *       ```
 *       
 *       **Features:**
 *       - รับ multipart/form-data จาก Flutter App
 *       - ส่งต่อ request ไปยัง Backend CMS อัตโนมัติ
 *       - จัดการ CORS ให้กับ Flutter App
 *       - ส่งต่อผลลัพธ์จาก AI กลับมา
 *       
 *       **Configuration:**
 *       - Backend CMS URL: `${process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080/api'}/ai-evaluation`
 *       - Fallback URL: `http://localhost:8080/api/ai-evaluation`
 *       
 *       **Note**: Endpoint นี้ไม่ได้ประมวลผล AI เอง แต่เป็นตัวกลางส่งต่อเท่านั้น
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
 *         description: ประเมินสำเร็จ (Response จาก Backend CMS)
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
 *                   description: ถูกต้องหรือไม่
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
 *                 summary: การออกเสียงที่ถูกต้อง 100%
 *                 value:
 *                   transcribed_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 100
 *                   is_correct: true
 *                   word_error_rate: 0
 *                   processing_time: 2.3
 *               goodMatch:
 *                 summary: การออกเสียงที่ดี (มีข้อผิดพลาดเล็กน้อย)
 *                 value:
 *                   transcribed_text: "สวัสดีครับ วันนี้อากาศดี"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 87.5
 *                   is_correct: true
 *                   word_error_rate: 0.125
 *                   processing_time: 2.1
 *       400:
 *         description: Bad Request - Backend CMS ตอบกลับด้วย 400
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "CMS Evaluation Failed (400)"
 *                 details:
 *                   type: string
 *                   description: รายละเอียด error จาก Backend CMS
 *                   example: "Missing audio file or original text."
 *       404:
 *         description: Not Found - Backend CMS ไม่พบทรัพยากร
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "CMS Evaluation Failed (404)"
 *                 details:
 *                   type: string
 *                   example: "Endpoint not found"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               proxyError:
 *                 summary: Proxy ไม่สามารถเชื่อมต่อ Backend CMS
 *                 value:
 *                   error: "Failed to connect to CMS AI backend or server error."
 *               cmsError:
 *                 summary: Backend CMS ตอบกลับด้วย 500
 *                 value:
 *                   error: "CMS Evaluation Failed (500)"
 *                   details: "Python script error: ..."
 *       503:
 *         description: Service Unavailable - Backend CMS ไม่ตอบสนอง
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "CMS Evaluation Failed (503)"
 *                 details:
 *                   type: string
 *                   example: "Service temporarily unavailable"
 */
export async function POST(request: NextRequest) {
    const errorCorsHeaders = {
        'Access-Control-Allow-Origin': corsHeaders['Access-Control-Allow-Origin'],
    };

    try {
        // 1. รับ FormData จาก Flutter App
        const formData = await request.formData();
        
        // 2. ส่งต่อ Request Payload ไปยัง Backend CMS
        const cmsResponse = await fetch(CMS_EVAL_URL, {
            method: 'POST',
            // 🛑 สำคัญ: ส่งต่อ FormData Object โดยตรง
            body: formData, 
            // ⚠️ Next.js จะจัดการ Header 'Content-Type: multipart/form-data' ให้อัตโนมัติ
        });

        // 3. จัดการ Response จาก CMS
        if (!cmsResponse.ok) {
            const errorText = await cmsResponse.text();
            console.error('CMS AI Evaluation Failed (Status:', cmsResponse.status, 'Body:', errorText);

            // ส่งต่อ Error กลับไปยัง Flutter
            return NextResponse.json(
                { error: `CMS Evaluation Failed (${cmsResponse.status})`, details: errorText.substring(0, 500) }, 
                { status: cmsResponse.status, headers: errorCorsHeaders }
            );
        }

        const result = await cmsResponse.json();
        
        // 4. ส่งผลลัพธ์ JSON 200 OK กลับไปยัง Flutter
        return NextResponse.json(result, { headers: corsHeaders });

    } catch (error) {
        console.error('Error proxying AI evaluation request:', error);
        return NextResponse.json(
            { error: 'Failed to connect to CMS AI backend or server error.' }, 
            { status: 500, headers: errorCorsHeaders }
        );
    }
}