// src/app/api/quest-completion/route.ts

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
    parentScore?: number;
    evidence?: { 
        videoUrl?: string | null;
        imageUrl?: string | null;
        videoPathLocal?: string | null;
        imagePathLocal?: string | null;
        status?: string;
        description?: string;
    };
}

// =======================================================
// 2. UTILITIES
// =======================================================
// ⚠️ CORS Headers
const corsHeaders = {
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-requested-with',
    'Access-Control-Max-Age': '86400',
};

const TEST_PARENT_ID = "PR2"; 
const TEST_CHILD_ID = "CH2";   

const getRandomTimeSpentSeconds = (): number => {
    return Math.floor(Math.random() * 571) + 30; 
};

/**
 * @swagger
 * /api/quest-completion:
 *   options:
 *     tags:
 *       - Activity Records
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
 */
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, {
        status: 200,
        headers: corsHeaders
    });
}

/**
 * @swagger
 * /api/quest-completion:
 *   post:
 *     tags:
 *       - Activity Records
 *     summary: บันทึกการทำกิจกรรมเสร็จสมบูรณ์
 *     description: |
 *       บันทึกผลการทำกิจกรรม (Quest) พร้อมอัปเดตคะแนนเด็ก
 *       
 *       **Features:**
 *       - บันทึกผลการทำแต่ละ segment (คำถาม-คำตอบ)
 *       - รองรับหลักฐาน (วิดีโอ/รูปภาพ)
 *       - อัปเดตคะแนนเด็กอัตโนมัติ
 *       - ติดตามรอบที่ทำกิจกรรม (roundNumber)
 *       - รองรับคะแนนที่ผู้ปกครองให้ (parentScore)
 *       - คำนวณเวลาที่ใช้สำหรับกิจกรรมบางประเภท
 *       
 *       **Activity Types:**
 *       - **ด้านภาษา** / **ด้านร่างกาย**: มีการคำนวณเวลาที่ใช้ (timeSpentSeconds)
 *       - กิจกรรมอื่นๆ: ไม่บันทึกเวลา
 *       
 *       **Test IDs:**
 *       - Parent ID: `PR2`
 *       - Child ID: `CH2`
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - activityId
 *               - totalScoreEarned
 *               - segmentResults
 *             properties:
 *               activityId:
 *                 type: string
 *                 description: Activity ID ที่ทำ
 *                 example: "cmiu3ysuu0001ulc42rg7kksb"
 *               totalScoreEarned:
 *                 type: number
 *                 description: คะแนนรวมที่คำนวณได้จากระบบ
 *                 example: 85.5
 *                 minimum: 0
 *               parentScore:
 *                 type: number
 *                 description: คะแนนที่ผู้ปกครองให้ (ถ้ามีจะใช้แทน totalScoreEarned)
 *                 example: 90
 *                 minimum: 0
 *               segmentResults:
 *                 type: array
 *                 description: ผลลัพธ์ของแต่ละคำถาม/segment
 *                 items:
 *                   type: object
 *                   required:
 *                     - id
 *                     - text
 *                     - maxScore
 *                   properties:
 *                     id:
 *                       type: string
 *                       description: Segment ID
 *                       example: "seg_001"
 *                     text:
 *                       type: string
 *                       description: ข้อความคำถาม
 *                       example: "1+1"
 *                     maxScore:
 *                       type: number
 *                       description: คะแนนเต็มของคำถามนี้
 *                       example: 10
 *                     recognizedText:
 *                       type: string
 *                       description: ข้อความที่ระบบรู้จักได้ (สำหรับกิจกรรมเสียง)
 *                       example: "2"
 *                     audioUrl:
 *                       type: string
 *                       description: URL ไฟล์เสียง (ถ้ามี)
 *                       example: "https://example.com/audio/recording1.m4a"
 *               evidence:
 *                 type: object
 *                 description: หลักฐานการทำกิจกรรม (วิดีโอ/รูปภาพ)
 *                 properties:
 *                   videoUrl:
 *                     type: string
 *                     nullable: true
 *                     description: URL วิดีโอ
 *                     example: "https://example.com/videos/activity123.mp4"
 *                   imageUrl:
 *                     type: string
 *                     nullable: true
 *                     description: URL รูปภาพ
 *                     example: "https://example.com/images/drawing.jpg"
 *                   videoPathLocal:
 *                     type: string
 *                     nullable: true
 *                     description: Path ของวิดีโอในเครื่อง
 *                     example: "/storage/videos/20251206_123456.mp4"
 *                   imagePathLocal:
 *                     type: string
 *                     nullable: true
 *                     description: Path ของรูปภาพในเครื่อง
 *                     example: "/storage/images/drawing_001.jpg"
 *                   status:
 *                     type: string
 *                     description: สถานะหลักฐาน
 *                     example: "uploaded"
 *                   description:
 *                     type: string
 *                     description: คำอธิบายเพิ่มเติมจากผู้ปกครอง
 *                     example: "ลูกทำได้ดีมาก พัฒนาขึ้นเยอะเลย"
 *           examples:
 *             languageActivity:
 *               summary: กิจกรรมด้านภาษา (มีการบันทึกเสียง)
 *               value:
 *                 activityId: "act_lang_001"
 *                 totalScoreEarned: 85.5
 *                 segmentResults:
 *                   - id: "seg_001"
 *                     text: "สวัสดีครับ"
 *                     maxScore: 50
 *                     recognizedText: "สวัสดีครับ"
 *                     audioUrl: "https://example.com/audio/rec1.m4a"
 *                   - id: "seg_002"
 *                     text: "ขอบคุณครับ"
 *                     maxScore: 50
 *                     recognizedText: "ขอบคุณคะ"
 *                     audioUrl: "https://example.com/audio/rec2.m4a"
 *             physicalActivity:
 *               summary: กิจกรรมด้านร่างกาย (มีวิดีโอหลักฐาน)
 *               value:
 *                 activityId: "act_phy_001"
 *                 totalScoreEarned: 90
 *                 parentScore: 95
 *                 segmentResults:
 *                   - id: "seg_001"
 *                     text: "ยืนขาเดียว 10 วินาที"
 *                     maxScore: 100
 *                 evidence:
 *                   videoUrl: "https://example.com/videos/balance.mp4"
 *                   videoPathLocal: "/storage/videos/balance_20251206.mp4"
 *                   description: "ลูกทำได้ดีมาก ยืนได้นานกว่า 10 วินาที"
 *             cognitiveActivity:
 *               summary: กิจกรรมด้านคิดวิเคราะห์ (ไม่มีเวลา)
 *               value:
 *                 activityId: "act_cog_001"
 *                 totalScoreEarned: 75
 *                 segmentResults:
 *                   - id: "seg_001"
 *                     text: "1+1"
 *                     maxScore: 25
 *                   - id: "seg_002"
 *                     text: "2+3"
 *                     maxScore: 25
 *                   - id: "seg_003"
 *                     text: "5-2"
 *                     maxScore: 25
 *                   - id: "seg_004"
 *                     text: "10/2"
 *                     maxScore: 25
 *     responses:
 *       200:
 *         description: บันทึกสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: ข้อความแจ้งผล
 *                   example: "ด.ญ. สมศรี ใจดี ทำภารกิจเสร็จสมบูรณ์แล้ว! (รอบที่ 3)"
 *                 recordId:
 *                   type: string
 *                   description: Activity Record ID ที่สร้าง
 *                   example: "clrecord12345"
 *                 roundNumber:
 *                   type: integer
 *                   description: รอบที่ทำกิจกรรม
 *                   example: 3
 *                 totalScore:
 *                   type: number
 *                   description: คะแนนที่บันทึกจริง
 *                   example: 95
 *                 scoreType:
 *                   type: string
 *                   description: ประเภทคะแนน (parent = ผู้ปกครองให้, calculated = คำนวณจากระบบ)
 *                   enum: ['parent', 'calculated']
 *                   example: "parent"
 *             examples:
 *               firstCompletion:
 *                 summary: ทำครั้งแรก (รอบที่ 1)
 *                 value:
 *                   message: "ด.ญ. สมศรี ใจดี ทำภารกิจเสร็จสมบูรณ์แล้ว! (รอบที่ 1)"
 *                   recordId: "clrecord12345"
 *                   roundNumber: 1
 *                   totalScore: 85
 *                   scoreType: "calculated"
 *               withParentScore:
 *                 summary: มีคะแนนจากผู้ปกครอง
 *                 value:
 *                   message: "ด.ช. สมหมาย รักเรียน ทำภารกิจเสร็จสมบูรณ์แล้ว! (รอบที่ 5)"
 *                   recordId: "clrecord67890"
 *                   roundNumber: 5
 *                   totalScore: 95
 *                   scoreType: "parent"
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
 *               missingFields:
 *                 summary: ข้อมูลไม่ครบ
 *                 value:
 *                   error: "Missing required quest completion fields."
 *       404:
 *         description: Not Found - ไม่พบข้อมูลที่เกี่ยวข้อง
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               activityNotFound:
 *                 summary: ไม่พบกิจกรรม
 *                 value:
 *                   error: "Activity not found in CMS."
 *               childNotFound:
 *                 summary: ไม่พบเด็กหรือความสัมพันธ์
 *                 value:
 *                   error: "Child ID CH2 not found or not linked to Parent ID PR2. Check test IDs and seed data."
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
 *               generalError:
 *                 summary: ข้อผิดพลาดทั่วไป
 *                 value:
 *                   error: "Failed to record quest completion in CMS."
 *               foreignKeyError:
 *                 summary: ข้อผิดพลาด Foreign Key
 *                 value:
 *                   error: "Foreign Key Error: Parent/Child ID does not exist. Check your seed data."
 */
export async function POST(request: Request) {
    try {
        const body: CompletionPayload = await request.json(); 
        const { activityId, totalScoreEarned, segmentResults, evidence, parentScore } = body; 

        if (!activityId || totalScoreEarned === undefined || !segmentResults) {
            return NextResponse.json({ error: 'Missing required quest completion fields.' }, { status: 400, headers: corsHeaders });
        }
        
        // ใช้ parentScore ถ้ามี, ไม่งั้นใช้ totalScoreEarned
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

        // 3. ทำ TRANSACTION: อัปเดตคะแนนและสร้าง Record
        const description = evidence?.description || null;
        const evidenceClean = evidence ? { ...evidence } : null;
        
        // ลบ description และ parentScore ออกจาก evidence object
        if (evidenceClean) {
            delete evidenceClean.description;
            delete (evidenceClean as any).parentScore;
        }
        
        const detailResultsObject: any = {
            questType: questCategory,
            results: segmentResults, 
            evidence: evidenceClean,
            description: description,
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
            
            // b. อัปเดตคะแนนเด็ก
            await tx.child.update({
                where: { id: childId },
                data: {
                    score: { increment: scoreToIncrement }
                }
            });

            // c. สร้าง Record
            return tx.activityRecord.create({
                data: {
                    id: cuid(), 
                    activityId: activityId,
                    parentId: parentId,
                    childId: childId,
                    dateCompleted: new Date(),
                    timeSpentSeconds: timeSpentToSave,
                    scoreEarned: finalScoreToSave,
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
            totalScore: finalScoreToSave,
            scoreType: parentScore !== undefined ? 'parent' : 'calculated',
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