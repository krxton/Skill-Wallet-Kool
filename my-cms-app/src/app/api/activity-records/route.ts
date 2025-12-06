// src/app/api/activity-records/route.ts

import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

/**
 * @swagger
 * /api/activity-records:
 *   get:
 *     tags:
 *       - Activity Records
 *     summary: ดึงบันทึกการทำกิจกรรม
 *     description: ดึงรายการบันทึกการทำกิจกรรมทั้งหมด หรือกรองตาม Child ID
 *     parameters:
 *       - in: query
 *         name: childId
 *         schema:
 *           type: string
 *         required: false
 *         description: Child ID สำหรับกรองบันทึก (ถ้าไม่ระบุจะดึงทั้งหมด)
 *         example: clchild12345
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: string
 *                     description: Activity Record ID
 *                     example: clrecord12345
 *                   activityId:
 *                     type: string
 *                     description: Activity ID ที่ทำ
 *                     example: clactivity12345
 *                   childId:
 *                     type: string
 *                     description: Child ID ที่ทำกิจกรรม
 *                     example: clchild12345
 *                   roundNumber:
 *                     type: integer
 *                     description: รอบที่ทำกิจกรรม
 *                     example: 1
 *                   scoreEarned:
 *                     type: integer
 *                     description: คะแนนที่ได้รับ
 *                     example: 85
 *                   dateCompleted:
 *                     type: string
 *                     format: date-time
 *                     description: วันที่ทำกิจกรรมเสร็จ
 *                     example: "2024-12-06T10:30:00.000Z"
 *             examples:
 *               allRecords:
 *                 summary: บันทึกทั้งหมด
 *                 value:
 *                   - id: "clrecord001"
 *                     activityId: "clactivity001"
 *                     childId: "clchild001"
 *                     roundNumber: 1
 *                     scoreEarned: 85
 *                     dateCompleted: "2024-12-06T10:30:00.000Z"
 *                   - id: "clrecord002"
 *                     activityId: "clactivity002"
 *                     childId: "clchild002"
 *                     roundNumber: 2
 *                     scoreEarned: 92
 *                     dateCompleted: "2024-12-06T11:00:00.000Z"
 *               filteredByChild:
 *                 summary: กรองตาม Child ID
 *                 value:
 *                   - id: "clrecord001"
 *                     activityId: "clactivity001"
 *                     childId: "clchild001"
 *                     roundNumber: 1
 *                     scoreEarned: 85
 *                     dateCompleted: "2024-12-06T10:30:00.000Z"
 *                   - id: "clrecord003"
 *                     activityId: "clactivity003"
 *                     childId: "clchild001"
 *                     roundNumber: 1
 *                     scoreEarned: 78
 *                     dateCompleted: "2024-12-06T14:20:00.000Z"
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Failed to fetch activity records"
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const childId = searchParams.get('childId');

    const records = await prisma.activityRecord.findMany({
      where: childId ? { childId } : {},
      select: {
        id: true,
        activityId: true,
        childId: true,
        roundNumber: true,
        scoreEarned: true,
        dateCompleted: true,
      },
    });

    return NextResponse.json(records, {
      headers: corsHeaders,
    });
  } catch (error) {
    console.error('Error fetching activity records:', error);
    return NextResponse.json(
      { error: 'Failed to fetch activity records' },
      { status: 500, headers: corsHeaders }
    );
  }
}

/**
 * @swagger
 * /api/activity-records:
 *   options:
 *     tags:
 *       - Activity Records
 *     summary: CORS Preflight Request
 *     description: จัดการ CORS preflight request
 *     responses:
 *       200:
 *         description: CORS headers returned successfully
 */
export async function OPTIONS() {
  return NextResponse.json({}, { status: 200, headers: corsHeaders });
}