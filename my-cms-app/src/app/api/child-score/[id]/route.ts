// src/app/api/child-score/[id]/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';

// ⚠️ CORS Headers: ตรวจสอบ Origin ของ Flutter App
const corsHeaders = {
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-requested-with',
    'Access-Control-Max-Age': '86400',
};

interface RouteContext {
    params: { id: string };
}

/**
 * @swagger
 * /api/child-score/{id}:
 *   get:
 *     tags:
 *       - Children
 *     summary: ดึงคะแนนปัจจุบันของเด็ก
 *     description: |
 *       ดึงข้อมูลคะแนนสะสมของเด็ก 1 คน
 *       - แสดงคะแนนปัจจุบัน
 *       - แสดงชื่อเด็ก
 *       - รองรับ CORS สำหรับทุก Origin
 *       
 *       **Use Case**: ใช้สำหรับแสดงคะแนนในหน้าโปรไฟล์เด็ก หรือก่อนแลกรางวัล
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Child ID
 *         example: "CH2"
 *     responses:
 *       200:
 *         description: ดึงข้อมูลคะแนนสำเร็จ
 *         headers:
 *           Access-Control-Allow-Origin:
 *             schema:
 *               type: string
 *               example: "*"
 *             description: CORS header (Allow all origins)
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               required:
 *                 - childName
 *                 - currentScore
 *               properties:
 *                 childName:
 *                   type: string
 *                   description: ชื่อเต็มของเด็ก
 *                   example: "ด.ญ. สมศรี ใจดี"
 *                 currentScore:
 *                   type: integer
 *                   description: คะแนนสะสมปัจจุบัน
 *                   example: 350
 *                   minimum: 0
 *             examples:
 *               highScore:
 *                 summary: เด็กที่มีคะแนนสูง
 *                 value:
 *                   childName: "ด.ญ. สมศรี ใจดี"
 *                   currentScore: 850
 *               mediumScore:
 *                 summary: เด็กที่มีคะแนนปานกลาง
 *                 value:
 *                   childName: "ด.ช. สมหมาย รักเรียน"
 *                   currentScore: 350
 *               newChild:
 *                 summary: เด็กใหม่ยังไม่มีคะแนน
 *                 value:
 *                   childName: "ด.ช. น้องใหม่ เพิ่งมา"
 *                   currentScore: 0
 *       400:
 *         description: Bad Request - ไม่มี Child ID
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             example:
 *               error: "Child ID is required"
 *       404:
 *         description: Not Found - ไม่พบข้อมูลเด็ก
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             example:
 *               error: "Child not found"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             example:
 *               error: "Internal Server Error"
 */
export async function GET(
    request: NextRequest,
    { params }: RouteContext
) {
    // *** การแก้ไข Workaround: Unpack params อย่างชัดเจนใน async context ***
    const unwrappedParams = await Promise.resolve(params);
    const childId = unwrappedParams.id;
    // ----------------------------------------------------

    if (!childId) {
        console.error('Missing child ID in API route params.'); 
        return NextResponse.json(
            { error: 'Child ID is required' }, 
            { status: 400, headers: corsHeaders }
        );
    }

    try {
        const child = await prisma.child.findUnique({
            where: { id: childId },
            select: { score: true, fullName: true }
        });

        if (!child) {
            return NextResponse.json(
                { error: 'Child not found' }, 
                { status: 404, headers: corsHeaders }
            );
        }

        // ส่งคะแนนปัจจุบันกลับไป
        return NextResponse.json({
            childName: child.fullName,
            currentScore: child.score,
        }, {
            status: 200,
            headers: corsHeaders
        });

    } catch (error) {
        console.error('Error fetching child score:', error);
        return NextResponse.json(
            { error: 'Internal Server Error' }, 
            { status: 500, headers: corsHeaders }
        );
    }
}

/**
 * @swagger
 * /api/child-score/{id}:
 *   options:
 *     tags:
 *       - Children
 *     summary: CORS Preflight Request
 *     description: จัดการ CORS preflight request สำหรับ cross-origin requests
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Child ID (CUID format)
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