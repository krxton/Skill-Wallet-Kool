// src\app\api\activities\[id]\route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';

// Interface สำหรับ Activity (เพื่อให้ TypeScript ทำงานได้อย่างถูกต้อง)
interface ActivityData {
    name: string;
    category: string;
    content: string;
    difficulty: string;
    maxScore: number;
    description: string;
    videoUrl?: string;
    segments?: any;
}

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
    'Access-Control-Max-Age': '86400',
};

// ----------------------------------------------------
// GET /api/activities/[id] : ดึงข้อมูลกิจกรรมเดียว
// ----------------------------------------------------
export async function GET(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    // *** การแก้ไข Workaround: Unpack params โดยใช้ Promise.resolve() ***
    const unwrappedParams = await Promise.resolve(params);
    const activityId = unwrappedParams.id;
    // ----------------------------------------------------

    // 1. ตรวจสอบ ID
    if (!activityId) {
        console.error("Missing activity ID in API route params.");
        return NextResponse.json({ error: 'Activity ID is required' }, { status: 400, headers: corsHeaders });
    }

    try {
        const activity = await prisma.activity.findUnique({
            where: { id: activityId },
        });

        if (!activity) {
            return NextResponse.json({ error: 'Activity not found' }, { status: 404 });
        }

        // 2. การจัดการ Segments: แปลง JSON String ใน DB กลับเป็น Object 
        let segments = [];
        try {
            if (activity.segments) {
                segments = JSON.parse(activity.segments as string);
            }
        } catch (e) {
            console.error(`Error parsing segments JSON for ID ${activityId}:`, e);
            segments = [];
        }

        const responseData = {
            ...activity,
            segments: segments,
        }

        return NextResponse.json(responseData);

    } catch (error) {
        console.error('Error fetching activity:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}

// ----------------------------------------------------
// PUT /api/activities/[id] : อัปเดตข้อมูลกิจกรรม
// ----------------------------------------------------
export async function PUT(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    // *** การแก้ไข Workaround: Unpack params โดยใช้ Promise.resolve() ***
    const unwrappedParams = await Promise.resolve(params);
    const activityId = unwrappedParams.id;
    // ----------------------------------------------------

    const body: ActivityData = await request.json();

    if (!activityId) {
        return NextResponse.json({ error: 'Activity ID is required' }, { status: 400 });
    }

    // เตรียมข้อมูลที่จะอัปเดต (Segments ต้องถูกแปลงเป็น JSON String ก่อนบันทึก)
    const updateData: any = {
        name: body.name,
        category: body.category,
        content: body.content,
        difficulty: body.difficulty,
        maxScore: body.maxScore,
        description: body.description,
        videoUrl: body.videoUrl,
        segments: body.segments ? JSON.stringify(body.segments) : null,
    };

    try {
        const existingActivity = await prisma.activity.findUnique({ where: { id: activityId } });
        if (!existingActivity) {
            return NextResponse.json({ error: 'Activity not found for update' }, { status: 404 });
        }

        const updatedActivity = await prisma.activity.update({
            where: { id: activityId },
            data: updateData,
        });

        return NextResponse.json(updatedActivity);
    } catch (error) {
        console.error('Error updating activity:', error);
        return NextResponse.json({ error: 'Failed to update activity' }, { status: 500 });
    }
}

// ----------------------------------------------------
// DELETE /api/activities/[id] : ลบข้อมูลกิจกรรม
// ----------------------------------------------------
export async function DELETE(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    // *** การแก้ไข Workaround: Unpack params โดยใช้ Promise.resolve() ***
    const unwrappedParams = await Promise.resolve(params);
    const activityId = unwrappedParams.id;
    // ----------------------------------------------------

    if (!activityId) {
        return NextResponse.json({ error: 'Activity ID is required' }, { status: 400 });
    }

    try {
        const existingActivity = await prisma.activity.findUnique({ where: { id: activityId } });
        if (!existingActivity) {
            return NextResponse.json({ error: 'Activity not found for deletion' }, { status: 404 });
        }

        await prisma.activity.delete({
            where: { id: activityId },
        });

        return new NextResponse(null, { status: 204 });
    } catch (error) {
        console.error('Error deleting activity:', error);
        return NextResponse.json({ error: 'Failed to delete activity' }, { status: 500 });
    }
}

export async function OPTIONS() {
    return NextResponse.json({}, { status: 200, headers: corsHeaders });
}