import { NextResponse, NextRequest } from 'next/server'; 
import prisma from '@/lib/prisma'; 
import cuid from 'cuid'; 

// =======================================================
// 1. INTERFACES & TYPES (คงเดิม)
// =======================================================
// ... (SegmentResult และ CompletionPayload interfaces คงเดิม) ...
interface SegmentResult {
    id: string; 
    text: string;
    maxScore: number; 
    recognizedText?: string;
    audioUrl?: string;
}

interface CompletionPayload {
    activityId: string;
    totalScoreEarned: number;
    segmentResults: SegmentResult[]; 
    evidence?: { 
        videoUrl?: string | null;
        imageUrl?: string | null;
        status?: string; 
    };
}


// =======================================================
// 2. UTILITIES (แก้ไข: เปลี่ยนเป็น ID เดี่ยวสำหรับทดสอบ)
// =======================================================
const ALLOWED_ORIGIN = 'http://localhost:3001'; 
// ✅ เปลี่ยนจาก Array เป็น ID เดี่ยวตามที่ต้องการ
const TEST_PARENT_ID = "PR2"; 
const TEST_CHILD_ID = "CH2";   

const getRandomTimeSpentSeconds = (): number => {
    return Math.floor(Math.random() * 571) + 30; 
};


// ----------------------------------------------------
// 3. OPTIONS Handler (CORS) (เพิ่ม Max-Age)
// ----------------------------------------------------
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, {
        status: 200,
        headers: {
            'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
            'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Access-Control-Max-Age': '86400', // เพิ่ม Max-Age เพื่อช่วยเรื่อง CORS Preflight
        }
    });
}


// ----------------------------------------------------
// 4. POST Handler (บันทึก Quest Completion)
// ----------------------------------------------------
export async function POST(request: Request) {
    // 🚨 ตั้งค่า CORS Header สำหรับ Error Response (เพื่อแก้ปัญหา CORS)
    const corsHeaders = {
        'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    };

    try {
        const body: CompletionPayload = await request.json(); 
        const { activityId, totalScoreEarned, segmentResults, evidence } = body; 

        if (!activityId || totalScoreEarned === undefined || !segmentResults) {
            // ✅ เพิ่ม CORS Header
            return NextResponse.json({ error: 'Missing required quest completion fields.' }, { status: 400, headers: corsHeaders });
        }
        
        const scoreToIncrement = Math.floor(totalScoreEarned || 0);
        
        // 1. ตรวจสอบประเภทกิจกรรมและดึงข้อมูลเพิ่มเติม
        const activity = await prisma.activity.findUnique({ where: { id: activityId }, select: { category: true } });
        if (!activity) { 
            // ✅ เพิ่ม CORS Header
            return NextResponse.json({ error: 'Activity not found in CMS.' }, { status: 404, headers: corsHeaders });
        }
        const questCategory = activity.category;

        // 2. กำหนด ID และตรวจสอบความสัมพันธ์
        const finalStatus = "Approved"; 
        
        // ✅ ใช้ ID ที่กำหนดตายตัว
        const parentId = TEST_PARENT_ID;
        const childId = TEST_CHILD_ID;
        
        // 2.1 ตรวจสอบความสัมพันธ์ Parent-Child และดึงชื่อเด็กมาใช้ใน Response
        const childData = await prisma.child.findUnique({ 
            where: { id: childId },
            select: { 
                fullName: true, // ดึงชื่อมาใช้ใน Response
                parents: { // ตรวจสอบว่า Parent นี้ผูกกับ Child นี้จริง
                    where: { parentId: parentId },
                    select: { parentId: true }
                }
            } 
        });

        // 2.2 ตรวจสอบ: ถ้าไม่พบเด็ก, หรือเด็กคนนี้ไม่ได้มีผู้ปกครองคนนี้
        if (!childData || childData.parents.length === 0) {
            // ✅ เพิ่ม CORS Header
            return NextResponse.json(
                { error: `Child ID ${childId} not found or not linked to Parent ID ${parentId}. Check test IDs and seed data.` }, 
                { status: 404, headers: corsHeaders }
            );
        }
        
        const childFullName = childData.fullName; // ชื่อเด็กที่ใช้ใน Response
        
        let timeSpentToSave: number | undefined = undefined; 
        
        if (questCategory === 'ด้านภาษา' || questCategory === 'ด้านร่างกาย') {
            timeSpentToSave = getRandomTimeSpentSeconds(); 
        }

        // ----------------------------------------------------
        // 3. ทำ TRANSACTION: อัปเดตคะแนนและสร้าง Record
        // ----------------------------------------------------
        
        const detailResultsObject: any = {
            questType: questCategory,
            results: segmentResults, 
            evidence: evidence || null,
        }; 

        const record = await prisma.$transaction(async (tx) => {
            
            // a. นับรอบ (Count from ActivityRecord)
            const latestRoundRecord = await tx.activityRecord.aggregate({
                _max: { roundNumber: true },
                where: {
                    childId: childId, // ✅ ใช้ ID ที่กำหนดตายตัว
                    activityId: activityId,
                    status: 'Approved', 
                },
            });

            const maxRound = latestRoundRecord._max.roundNumber || 0;
            const newRoundNumber = maxRound + 1;
            
            // b. อัปเดตคะแนนเด็ก
            await tx.child.update({
                where: { id: childId }, // ✅ ใช้ ID ที่กำหนดตายตัว
                data: {
                    score: { increment: scoreToIncrement }
                }
            });

            // c. สร้าง Record (บันทึกภารกิจ)
            return tx.activityRecord.create({
                data: {
                    id: cuid(), 
                    activityId: activityId,
                    parentId: parentId, // ✅ ใช้ ID ที่กำหนดตายตัว
                    childId: childId,   // ✅ ใช้ ID ที่กำหนดตายตัว
                    dateCompleted: new Date(),
                    timeSpentSeconds: timeSpentToSave,
                    scoreEarned: totalScoreEarned,
                    status: finalStatus,
                    detailResults: detailResultsObject, 
                    roundNumber: newRoundNumber, 
                },
            });
        });

        // 4. ส่งผลลัพธ์กลับพร้อม Header CORS และข้อความที่ชัดเจน
        // ✅ ปรับข้อความ Response
        const responseMessage = `${childFullName} ทำภารกิจเสร็จสมบูรณ์แล้ว! (รอบที่ ${record.roundNumber})`;
        
        return NextResponse.json({
            message: responseMessage, 
            recordId: record.id,
            roundNumber: record.roundNumber, 
            totalScore: totalScoreEarned,
        }, {
            status: 200,
            headers: corsHeaders, // ✅ ใช้ CORS Header
        });

    } catch (error) {
        console.error('Error recording quest completion in CMS:', error);
        
        let errorMessage = 'Failed to record quest completion in CMS.';
        if (typeof error === 'object' && error !== null && 'code' in error && (error as any).code === 'P2003') {
            errorMessage = 'Foreign Key Error: Parent/Child ID does not exist. Check your seed data.';
        }
        
        // ✅ เพิ่ม CORS Header ใน 500 Response
        return NextResponse.json({ error: errorMessage }, { status: 500, headers: corsHeaders });
    }
}