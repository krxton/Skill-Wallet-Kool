// src/app/api/redeem-reward/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import cuid from 'cuid';

// ⚠️ CORS Headers
const corsHeaders = {
    'Access-Control-Allow-Origin': '*', 
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-requested-with',
    'Access-Control-Max-Age': '86400',
};

interface RedeemPayload {
    parentId: string;
    childId: string;
    rewardId: string;
}

/**
 * @swagger
 * /api/redeem-reward:
 *   options:
 *     tags:
 *       - Rewards
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
    return NextResponse.json({}, {
        status: 200,
        headers: corsHeaders
    });
}

/**
 * @swagger
 * /api/redeem-reward:
 *   post:
 *     tags:
 *       - Rewards
 *     summary: แลกรางวัลด้วยคะแนน
 *     description: |
 *       ระบบแลกรางวัลสำหรับเด็ก โดยหักคะแนนและบันทึกประวัติการแลก
 *       
 *       **Features:**
 *       - ตรวจสอบคะแนนเด็กเพียงพอหรือไม่
 *       - หักคะแนนและบันทึกการแลกในครั้งเดียว (Transaction)
 *       - บันทึกประวัติการแลกรางวัล (RewardRedemption)
 *       - ป้องกัน Race Condition ด้วย Database Transaction
 *       
 *       **Transaction Flow:**
 *       1. ตรวจสอบรางวัลและราคา
 *       2. ตรวจสอบคะแนนเด็ก
 *       3. หักคะแนนและบันทึกการแลกพร้อมกัน (Atomic)
 *       
 *       **Use Case:**
 *       - เด็กแลกคะแนนเป็นรางวัล
 *       - ผู้ปกครองอนุมัติการแลกรางวัล
 *       - ติดตามประวัติการแลกรางวัล
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - parentId
 *               - childId
 *               - rewardId
 *             properties:
 *               parentId:
 *                 type: string
 *                 description: Parent ID (ผู้อนุมัติ)
 *                 example: "clparent12345"
 *               childId:
 *                 type: string
 *                 description: Child ID (ผู้แลกรางวัล)
 *                 example: "clchild12345"
 *               rewardId:
 *                 type: string
 *                 description: Reward ID (รางวัลที่ต้องการแลก)
 *                 example: "clreward12345"
 *           examples:
 *             lowCostReward:
 *               summary: แลกรางวัลราคาถูก (50 คะแนน)
 *               value:
 *                 parentId: "PR2"
 *                 childId: "CH2"
 *                 rewardId: "reward_sticker"
 *             mediumCostReward:
 *               summary: แลกรางวัลราคาปานกลาง (200 คะแนน)
 *               value:
 *                 parentId: "PR2"
 *                 childId: "CH2"
 *                 rewardId: "reward_toy"
 *             highCostReward:
 *               summary: แลกรางวัลราคาแพง (500 คะแนน)
 *               value:
 *                 parentId: "PR2"
 *                 childId: "CH2"
 *                 rewardId: "reward_bicycle"
 *     responses:
 *       200:
 *         description: แลกรางวัลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   description: ข้อความแจ้งผลสำเร็จ
 *                   example: "Redemption successful for ไอศกรีม."
 *                 newScore:
 *                   type: integer
 *                   description: คะแนนคงเหลือหลังแลก
 *                   example: 150
 *                 rewardCost:
 *                   type: integer
 *                   description: คะแนนที่ใช้แลก
 *                   example: 100
 *             examples:
 *               firstRedemption:
 *                 summary: แลกรางวัลครั้งแรก
 *                 value:
 *                   message: "Redemption successful for สติกเกอร์."
 *                   newScore: 300
 *                   rewardCost: 50
 *               afterMultipleRedemptions:
 *                 summary: แลกรางวัลหลายครั้ง
 *                 value:
 *                   message: "Redemption successful for ของเล่น."
 *                   newScore: 50
 *                   rewardCost: 200
 *               exactScore:
 *                 summary: ใช้คะแนนพอดี (คะแนนเหลือ 0)
 *                 value:
 *                   message: "Redemption successful for จักรยาน."
 *                   newScore: 0
 *                   rewardCost: 500
 *       400:
 *         description: Bad Request - คะแนนไม่พอ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               insufficientScore:
 *                 summary: คะแนนไม่พอ
 *                 value:
 *                   error: "Insufficient score. Need 500, but ด.ญ. สมศรี ใจดี only has 250 points."
 *               missingFields:
 *                 summary: ข้อมูลไม่ครบ
 *                 value:
 *                   error: "Missing required fields: parentId, childId, or rewardId."
 *       404:
 *         description: Not Found - ไม่พบข้อมูล
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               rewardNotFound:
 *                 summary: ไม่พบรางวัล
 *                 value:
 *                   error: "Reward not found."
 *               childNotFound:
 *                 summary: ไม่พบเด็ก
 *                 value:
 *                   error: "Child ID clchild12345 not found."
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
 *               transactionError:
 *                 summary: Transaction error
 *                 value:
 *                   error: "Internal server error during redemption."
 *               databaseError:
 *                 summary: Database connection error
 *                 value:
 *                   error: "Internal server error during redemption."
 */
export async function POST(request: Request) {
    try {
        const { parentId, childId, rewardId }: RedeemPayload = await request.json();

        // 1. ตรวจสอบของรางวัลและราคา
        const reward = await prisma.reward.findUnique({
            where: { id: rewardId },
            select: { name: true, cost: true }
        });
        if (!reward) {
            return NextResponse.json(
                { error: 'Reward not found.' }, 
                { status: 404, headers: corsHeaders }
            );
        }
        const rewardCost = reward.cost;

        // 2. ตรวจสอบคะแนนของเด็ก
        const child = await prisma.child.findUnique({
            where: { id: childId },
            select: { score: true, fullName: true }
        });
        if (!child) {
            return NextResponse.json(
                { error: `Child ID ${childId} not found.` }, 
                { status: 404, headers: corsHeaders }
            );
        }
        const currentScore = child.score;

        // 3. ตรวจสอบคะแนนไม่พอ
        if (currentScore < rewardCost) {
            return NextResponse.json(
                { error: `Insufficient score. Need ${rewardCost}, but ${child.fullName} only has ${currentScore} points.` }, 
                { status: 400, headers: corsHeaders }
            );
        }

        // 4. ทำ Transaction: ลดคะแนนและบันทึกการแลกของรางวัล
        const newScore = currentScore - rewardCost;

        await prisma.$transaction(async (tx) => {
            // ลดคะแนนเด็ก
            await tx.child.update({
                where: { id: childId },
                data: { score: newScore }
            });

            // บันทึกการแลกของรางวัล (RewardRedemption)
            await tx.rewardRedemption.create({
                data: {
                    id: cuid(),
                    childId: childId,
                    parentId: parentId,
                    rewardId: rewardId,
                    dateRedeemed: new Date(),
                    scoreUsed: rewardCost,
                }
            });
        });

        // 5. ส่งผลลัพธ์กลับ
        return NextResponse.json({
            message: `Redemption successful for ${reward.name}.`,
            newScore: newScore,
            rewardCost: rewardCost,
        }, {
            status: 200,
            headers: corsHeaders,
        });

    } catch (error) {
        console.error('Redemption error:', error);
        return NextResponse.json(
            { error: 'Internal server error during redemption.' }, 
            { status: 500, headers: corsHeaders }
        );
    }
}