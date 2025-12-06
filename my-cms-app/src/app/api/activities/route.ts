// src/app/api/activities/route.ts

import { NextResponse } from 'next/server'
import prisma from '@/lib/prisma'

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
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

/**
 * @swagger
 * /api/activities:
 *   post:
 *     tags:
 *       - Activities
 *     summary: สร้างกิจกรรมใหม่
 *     description: สร้างกิจกรรมใหม่พร้อมข้อมูลรายละเอียด
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             $ref: '#/components/schemas/ActivityInput'
 *           examples:
 *             example1:
 *               summary: ตัวอย่างกิจกรรมด้านคิดวิเคราะห์
 *               value:
 *                 name: "กิจกรรมเรียนรู้ตัวเลข"
 *                 category: "ด้านคิดวิเคราะห์"
 *                 content: "กิจกรรมสำหรับเด็กอายุ 3-5 ปี"
 *                 difficulty: "ง่าย"
 *                 maxScore: 100
 *                 description: "เรียนรู้การนับเลข 1-10"
 *                 videoUrl: null
 *                 segments: 
 *                   - id: "cmiu3xomg0000356vj5aw19zo"
 *                     question: "1+1"
 *                     answer: "2"
 *                     solution: ""
 *                     score: 100
 *     responses:
 *       201:
 *         description: สร้างกิจกรรมสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Activity'
 *       400:
 *         $ref: '#/components/responses/BadRequest'
 *       500:
 *         $ref: '#/components/responses/InternalServerError'
 */
export async function POST(request: Request) {
  try {
    const body: ActivityData = await request.json()
    const {
      name,
      category,
      content,
      difficulty,
      maxScore,
      description,
      videoUrl,
      segments
    } = body

    if (!name || !category || !content || !difficulty || maxScore === undefined) {
      return NextResponse.json({ error: 'Missing required fields' }, { status: 400, headers: corsHeaders })
    }

    const segmentsString: string | undefined = segments
      ? JSON.stringify(segments)
      : undefined;

    const newActivity = await prisma.activity.create({
      data: {
        name,
        category,
        content,
        difficulty,
        maxScore: parseInt(maxScore as any),
        description,
        videoUrl: videoUrl || null,
        segments: segmentsString,
      },
    })

    return NextResponse.json(newActivity, { status: 201, headers: corsHeaders })
  } catch (error) {
    console.error('Error creating activity:', error)
    return NextResponse.json({ error: 'Failed to create activity' }, { status: 500, headers: corsHeaders })
  }
}

/**
 * @swagger
 * /api/activities:
 *   get:
 *     tags:
 *       - Activities
 *     summary: ดึงรายการกิจกรรมทั้งหมด
 *     description: ดึงรายการกิจกรรมทั้งหมดเรียงตาม ID จากน้อยไปมาก
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/Activity'
 *             examples:
 *               example1:
 *                 summary: ตัวอย่างรายการกิจกรรม
 *                 value:
 *                   - id: "clxxx12345"
 *                     name: "กิจกรรมเรียนรู้ตัวเลข"
 *                     category: "คณิตศาสตร์"
 *                     content: "เรียนรู้การนับเลข 1-10"
 *                     difficulty: "Easy"
 *                     maxScore: 100
 *                     description: "กิจกรรมสำหรับเด็กอายุ 3-5 ปี"
 *                     videoUrl: "https://www.youtube.com/watch?v=xxx"
 *                     segments: null
 *                     createdAt: "2024-01-01T00:00:00.000Z"
 *                     updatedAt: "2024-01-01T00:00:00.000Z"
 *       500:
 *         $ref: '#/components/responses/InternalServerError'
 */
export async function GET() {
  try {
    const activities = await prisma.activity.findMany({
      orderBy: {
        id: 'asc',
      },
    })

    const formattedJson = JSON.stringify(activities, null, 2);

    return new Response(formattedJson, {
      status: 200,
      headers: {
        'Content-Type': 'application/json',
        ...corsHeaders,
      },
    });

  } catch (error) {
    console.error('Error fetching activities:', error)
    return NextResponse.json({ error: 'Failed to fetch activities' }, { status: 500, headers: corsHeaders })
  }
}

/**
 * @swagger
 * /api/activities:
 *   options:
 *     tags:
 *       - Activities
 *     summary: CORS Preflight Request
 *     description: จัดการ CORS preflight request
 *     responses:
 *       200:
 *         description: CORS headers returned successfully
 */
export async function OPTIONS() {
  return NextResponse.json({}, { status: 200, headers: corsHeaders });
}