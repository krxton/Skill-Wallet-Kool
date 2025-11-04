import { NextResponse, NextRequest } from 'next/server'; 
import prisma from '@/lib/prisma'; 
import cuid from 'cuid'; 

// =======================================================
// 1. INTERFACES & TYPES
// =======================================================
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
    parentScore?: number; // 🆕 เพิ่ม parentScore
    evidence?: { 
        videoUrl?: string | null;
        imageUrl?: string | null;
        videoPathLocal?: string | null; // 🆕 Local path
        imagePathLocal?: string | null; // 🆕 Local path
        status?: string;
        description?: string; // 🆕 เพิ่ม description
    };
}


// =======================================================
// 2. UTILITIES
// =======================================================
const ALLOWED_ORIGIN = 'http://localhost:3001'; 
const TEST_PARENT_ID = "PR2"; 
const TEST_CHILD_ID = "CH2";   

const getRandomTimeSpentSeconds = (): number => {
    return Math.floor(Math.random() * 571) + 30; 
};


// ----------------------------------------------------
// 3. OPTIONS Handler (CORS)
// ----------------------------------------------------
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, {
        status: 200,
        headers: {
            'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
            'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Access-Control-Max-Age': '86400',
        }
    });
}


// ----------------------------------------------------
// 4. POST Handler (บันทึก Quest Completion)
// ----------------------------------------------------
export async function POST(request: Request) {
    const corsHeaders = {
        'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    };

    try {
        const body: CompletionPayload = await request.json(); 
        const { activityId, totalScoreEarned, segmentResults, evidence, parentScore } = body; 

        if (!activityId || totalScoreEarned === undefined || !segmentResults) {
            return NextResponse.json({ error: 'Missing required quest completion fields.' }, { status: 400, headers: corsHeaders });
        }
        
        // 🆕 ใช้ parentScore ถ้ามี, ไม่งั้นใช้ totalScoreEarned
        const finalScoreToSave = parentScore ?? totalScoreEarned;
        const scoreToIncrement = Math.floor(finalScoreToSave);
        
        console.log('📊 Score Debug:', {
            totalScoreEarned,
            parentScore,
            finalScoreToSave,
            scoreToIncrement
        });
        
        // 1. ตรวจสอบประเภทกิจกรรมและดึงข้อมูลเพิ่มเติม
        const activity = await prisma.activity.findUnique({ where: { id: activityId }, select: { category: true } });
        if (!activity) { 
            return NextResponse.json({ error: 'Activity not found in CMS.' }, { status: 404, headers: corsHeaders });
        }
        const questCategory = activity.category;

        // 2. กำหนด ID และตรวจสอบความสัมพันธ์
        const finalStatus = "Approved"; 
        const parentId = TEST_PARENT_ID;
        const childId = TEST_CHILD_ID;
        
        // 2.1 ตรวจสอบความสัมพันธ์ Parent-Child
        const childData = await prisma.child.findUnique({ 
            where: { id: childId },
            select: { 
                fullName: true,
                parents: {
                    where: { parentId: parentId },
                    select: { parentId: true }
                }
            } 
        });

        if (!childData || childData.parents.length === 0) {
            return NextResponse.json(
                { error: `Child ID ${childId} not found or not linked to Parent ID ${parentId}. Check test IDs and seed data.` }, 
                { status: 404, headers: corsHeaders }
            );
        }
        
        const childFullName = childData.fullName;
        
        let timeSpentToSave: number | undefined = undefined; 
        
        if (questCategory === 'ด้านภาษา' || questCategory === 'ด้านร่างกาย') {
            timeSpentToSave = getRandomTimeSpentSeconds(); 
        }

        // ----------------------------------------------------
        // 3. ทำ TRANSACTION: อัปเดตคะแนนและสร้าง Record
        // ----------------------------------------------------
        
        // 🆕 แยก description และ parentScore ออกจาก evidence
        const description = evidence?.description || null;
        const evidenceClean = evidence ? { ...evidence } : null;
        
        // ลบ description และ parentScore ออกจาก evidence object
        if (evidenceClean) {
            delete evidenceClean.description;
            delete (evidenceClean as any).parentScore; // ลบ parentScore ออก
        }
        
        const detailResultsObject: any = {
            questType: questCategory,
            results: segmentResults, 
            evidence: evidenceClean, // เก็บ evidence สะอาด (ไม่มี description และ parentScore)
            description: description, // 🆕 เก็บ description แยกต่างหาก
        }; 

        const record = await prisma.$transaction(async (tx) => {
            
            // a. นับรอบ
            const latestRoundRecord = await tx.activityRecord.aggregate({
                _max: { roundNumber: true },
                where: {
                    childId: childId,
                    activityId: activityId,
                    status: 'Approved', 
                },
            });

            const maxRound = latestRoundRecord._max.roundNumber || 0;
            const newRoundNumber = maxRound + 1;
            
            // b. อัปเดตคะแนนเด็ก (ใช้ finalScoreToSave)
            await tx.child.update({
                where: { id: childId },
                data: {
                    score: { increment: scoreToIncrement }
                }
            });

            // c. สร้าง Record (บันทึก finalScoreToSave)
            return tx.activityRecord.create({
                data: {
                    id: cuid(), 
                    activityId: activityId,
                    parentId: parentId,
                    childId: childId,
                    dateCompleted: new Date(),
                    timeSpentSeconds: timeSpentToSave,
                    scoreEarned: finalScoreToSave, // 🆕 บันทึกคะแนนจริงที่ใช้
                    status: finalStatus,
                    detailResults: detailResultsObject, 
                    roundNumber: newRoundNumber, 
                },
            });
        });

        // 4. ส่งผลลัพธ์กลับ
        const responseMessage = `${childFullName} ทำภารกิจเสร็จสมบูรณ์แล้ว! (รอบที่ ${record.roundNumber})`;
        
        return NextResponse.json({
            message: responseMessage, 
            recordId: record.id,
            roundNumber: record.roundNumber, 
            totalScore: finalScoreToSave, // 🆕 ส่งคะแนนที่ใช้จริงกลับไป
            scoreType: parentScore !== undefined ? 'parent' : 'calculated', // 🆕 บอกประเภทคะแนน
        }, {
            status: 200,
            headers: corsHeaders,
        });

    } catch (error) {
        console.error('Error recording quest completion in CMS:', error);
        
        let errorMessage = 'Failed to record quest completion in CMS.';
        if (typeof error === 'object' && error !== null && 'code' in error && (error as any).code === 'P2003') {
            errorMessage = 'Foreign Key Error: Parent/Child ID does not exist. Check your seed data.';
        }
        
        return NextResponse.json({ error: errorMessage }, { status: 500, headers: corsHeaders });
    }
}