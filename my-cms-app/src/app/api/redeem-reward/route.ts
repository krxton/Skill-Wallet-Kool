// my-cms-app/src/app/api/redeem-reward/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import cuid from 'cuid';

const ALLOWED_ORIGIN = 'http://localhost:3001';

interface RedeemPayload {
    parentId: string;
    childId: string;
    rewardId: string;
}

// ----------------------------------------------------
// 1. OPTIONS Handler (CORS)
// ----------------------------------------------------
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, {
        status: 200,
        headers: {
            'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
            'Access-Control-Allow-Methods': 'POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization',
            'Access-Control-Max-Age': '86400', // Cache Preflight for 24h
        }
    });
}


// ----------------------------------------------------
// 2. POST Handler (Redeem Logic)
// ----------------------------------------------------
export async function POST(request: Request) {
    // ใช้อาเรย์สำหรับ Headers ที่จะใช้ซ้ำ
    const corsHeaders = {
        'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
    };

    try {
        const { parentId, childId, rewardId }: RedeemPayload = await request.json();

        // 1. ตรวจสอบของรางวัลและราคา
        const reward = await prisma.reward.findUnique({
            where: { id: rewardId },
            select: { name: true, cost: true }
        });
        if (!reward) {
            return NextResponse.json({ error: 'Reward not found.' }, { status: 404, headers: corsHeaders });
        }
        const rewardCost = reward.cost;

        // 2. ตรวจสอบคะแนนของเด็ก
        const child = await prisma.child.findUnique({
            where: { id: childId },
            select: { score: true, fullName: true }
        });
        if (!child) {
            return NextResponse.json({ error: `Child ID ${childId} not found.` }, { status: 404, headers: corsHeaders });
        }
        const currentScore = child.score;

        // 3. ตรวจสอบคะแนนไม่พอ
        if (currentScore < rewardCost) {
            return NextResponse.json({ error: `Insufficient score. Need ${rewardCost}, but ${child.fullName} only has ${currentScore} points.` }, { status: 400, headers: corsHeaders });
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
            headers: corsHeaders, // เพิ่ม CORS Header
        });

    } catch (error) {
        console.error('Redemption error:', error);
        return NextResponse.json({ error: 'Internal server error during redemption.' }, { status: 500, headers: corsHeaders });
    }
}