// src/app/api/evaluate/route.ts (Proxy Route สำหรับ AI Evaluation)

import { NextRequest, NextResponse } from 'next/server';

const CMS_API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL;
// ⚠️ ต้องแก้ไข URL นี้: นี่คือ URL ของ Backend CMS หลักที่รัน Logic AI/Python จริง ๆ
const CMS_EVALUATION_PATH = '/ai-evaluation'; 
// 🆕 สร้าง URL ปลายทางอย่างปลอดภัย โดยใช้ Fallback
const CMS_EVAL_URL = `${CMS_API_BASE || 'http://localhost:8080/api'}${CMS_EVALUATION_PATH}`;

const corsHeaders = {
    // ⚠️ ต้องแก้ไข Origin ให้เป็น URL ที่ Flutter App รันอยู่ (เช่น Origin ของ Next.js Frontend ถ้าใช้เป็น Proxy)
    'Access-Control-Allow-Origin': 'http://192.168.1.58:3000', 
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
};

// ----------------------------------------------------
// 1. OPTIONS Handler (CORS Preflight)
// ----------------------------------------------------
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, { headers: corsHeaders });
}


// ----------------------------------------------------
// 2. POST Handler (Proxy File Upload)
// ----------------------------------------------------
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