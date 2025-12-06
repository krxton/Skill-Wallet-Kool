// src/app/api/activities/[id]/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';

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

/**
 * @swagger
 * /api/activities/{id}:
 *   get:
 *     tags:
 *       - Activities
 *     summary: ดึงข้อมูลกิจกรรมตาม ID
 *     description: ดึงข้อมูลกิจกรรมเดียวตาม ID ที่ระบุ
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Activity ID (CUID)
 *         example: cmiu3ysuu0001ulc42rg7kksb
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Activity'
 *             example:
 *               id: "cmiu3ysuu0001ulc42rg7kksb"
 *               name: "กิจกรรมเรียนรู้ตัวเลข"
 *               category: "ด้านคิดวิเคราะห์"
 *               content: "กิจกรรมสำหรับเด็กอายุ 3-5 ปี"
 *               difficulty: "ง่าย"
 *               maxScore: 100
 *               description: "เรียนรู้การนับเลข 1-10"
 *               videoUrl: null
 *               segments: [{"id":"cmiu3xomg0000356vj5aw19zo","question":"1+1","answer":"2","solution":"","score":100}]
 *               createdAt: "2025-12-06T09:45:39.949Z"
 *               updatedAt: "2025-12-06T09:45:39.949Z"
 *       400:
 *         description: Bad Request - ไม่มี Activity ID
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Activity ID is required"
 *       404:
 *         description: Not Found - ไม่พบกิจกรรม
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Activity not found"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Internal Server Error"
 */
export async function GET(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    const unwrappedParams = await Promise.resolve(params);
    const activityId = unwrappedParams.id;

    if (!activityId) {
        console.error("Missing activity ID in API route params.");
        return NextResponse.json({ error: 'Activity ID is required' }, { status: 400, headers: corsHeaders });
    }

    try {
        const activity = await prisma.activity.findUnique({
            where: { id: activityId },
        });

        if (!activity) {
            return NextResponse.json({ error: 'Activity not found' }, { status: 404, headers: corsHeaders });
        }

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

        return NextResponse.json(responseData, { headers: corsHeaders });

    } catch (error) {
        console.error('Error fetching activity:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500, headers: corsHeaders });
    }
}

/**
 * @swagger
 * /api/activities/{id}:
 *   put:
 *     tags:
 *       - Activities
 *     summary: อัปเดตข้อมูลกิจกรรม
 *     description: แก้ไขข้อมูลกิจกรรมที่มีอยู่แล้วตาม ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Activity ID (CUID)
 *         example: cmiu3ysuu0001ulc42rg7kksb
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ActivityInput'
 *           example:
 *             name: "กิจกรรมเรียนรู้ตัวเลข (แก้ไข)"
 *             category: "ด้านคิดวิเคราะห์"
 *             content: "กิจกรรมสำหรับเด็กอายุ 5-7 ปี"
 *             difficulty: "ปานกลาง"
 *             maxScore: 150
 *             description: "เรียนรู้การนับเลข 1-20"
 *             videoUrl: null
 *             segments: 
 *               - id: "cmiu3xomg0000356vj5aw19zo"
 *                 question: "2+2"
 *                 answer: "4"
 *                 solution: ""
 *                 score: 150
 *     responses:
 *       200:
 *         description: อัปเดตสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Activity'
 *       400:
 *         description: Bad Request - ข้อมูลไม่ถูกต้อง
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *       404:
 *         description: Not Found - ไม่พบกิจกรรมที่จะอัปเดต
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Activity not found for update"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Failed to update activity"
 */
export async function PUT(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    const unwrappedParams = await Promise.resolve(params);
    const activityId = unwrappedParams.id;

    const body: ActivityData = await request.json();

    if (!activityId) {
        return NextResponse.json({ error: 'Activity ID is required' }, { status: 400, headers: corsHeaders });
    }

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
            return NextResponse.json({ error: 'Activity not found for update' }, { status: 404, headers: corsHeaders });
        }

        const updatedActivity = await prisma.activity.update({
            where: { id: activityId },
            data: updateData,
        });

        return NextResponse.json(updatedActivity, { headers: corsHeaders });
    } catch (error) {
        console.error('Error updating activity:', error);
        return NextResponse.json({ error: 'Failed to update activity' }, { status: 500, headers: corsHeaders });
    }
}

/**
 * @swagger
 * /api/activities/{id}:
 *   delete:
 *     tags:
 *       - Activities
 *     summary: ลบกิจกรรม
 *     description: ลบกิจกรรมออกจากระบบตาม ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Activity ID (CUID)
 *         example: cmiu3ysuu0001ulc42rg7kksb
 *     responses:
 *       204:
 *         description: ลบสำเร็จ (No Content)
 *       400:
 *         description: Bad Request - ไม่มี Activity ID
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Activity ID is required"
 *       404:
 *         description: Not Found - ไม่พบกิจกรรมที่จะลบ
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Activity not found for deletion"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 *             example:
 *               error: "Failed to delete activity"
 */
export async function DELETE(
    request: NextRequest,
    { params }: { params: { id: string } }
) {
    const unwrappedParams = await Promise.resolve(params);
    const activityId = unwrappedParams.id;

    if (!activityId) {
        return NextResponse.json({ error: 'Activity ID is required' }, { status: 400, headers: corsHeaders });
    }

    try {
        const existingActivity = await prisma.activity.findUnique({ where: { id: activityId } });
        if (!existingActivity) {
            return NextResponse.json({ error: 'Activity not found for deletion' }, { status: 404, headers: corsHeaders });
        }

        await prisma.activity.delete({
            where: { id: activityId },
        });

        return new NextResponse(null, { status: 204, headers: corsHeaders });
    } catch (error) {
        console.error('Error deleting activity:', error);
        return NextResponse.json({ error: 'Failed to delete activity' }, { status: 500, headers: corsHeaders });
    }
}

/**
 * @swagger
 * /api/activities/{id}:
 *   options:
 *     tags:
 *       - Activities
 *     summary: CORS Preflight Request
 *     description: จัดการ CORS preflight request สำหรับ activity by ID
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         example: cmiu3ysuu0001ulc42rg7kksb
 *     responses:
 *       200:
 *         description: CORS headers returned successfully
 */
export async function OPTIONS() {
    return NextResponse.json({}, { status: 200, headers: corsHeaders });
}