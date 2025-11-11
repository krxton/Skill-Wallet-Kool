// src/app/api/activities/route.ts

import { NextResponse } from 'next/server'
// *** แก้ไข: ใช้ prisma Singleton ที่เราสร้างไว้ใน lib/prisma ***
import prisma from '@/lib/prisma'

// Interface สำหรับข้อมูลที่ส่งมาจาก Frontend
interface ActivityData {
  name: string;
  category: string;
  content: string;
  difficulty: string;
  maxScore: number;
  description: string;
  videoUrl?: string; // เพิ่ม: Video URL
  segments?: any;  // เพิ่ม: Segments (JSON)
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-Requested-With',
  'Access-Control-Max-Age': '86400',
};

// POST /api/activities - สำหรับสร้างกิจกรรมใหม่
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

    // *** 1. การแก้ไข Type Conflict: ใช้ JSON.stringify() และกำหนดให้เป็น string (บังคับ) ***
    // ถ้า segments มีค่า ให้แปลงเป็น JSON string
    const segmentsString: string | undefined = segments
      ? JSON.stringify(segments)
      : undefined; // *** ใช้ undefined แทน null เพื่อบอก Prisma ว่าไม่ต้องส่งค่านี้ถ้าไม่มี ***

    // 2. ใช้ Prisma เพื่อสร้างกิจกรรมใหม่ในฐานข้อมูล
    const newActivity = await prisma.activity.create({
      data: {
        name,
        category,
        content,
        difficulty,
        maxScore: parseInt(maxScore as any),
        description,
        videoUrl: videoUrl || null, // videoUrl เป็น string | null ซึ่งถูกต้องสำหรับ String? field
        segments: segmentsString, // ส่งค่า segmentsString ที่เป็น string | undefined
      },
    })

    return NextResponse.json(newActivity, { status: 201, headers: corsHeaders })
  } catch (error) {
    console.error('Error creating activity:', error)
    return NextResponse.json({ error: 'Failed to create activity' }, { status: 500, headers: corsHeaders })
  }
}

// GET /api/activities - สำหรับดึงรายการกิจกรรมทั้งหมด (Activity List)
export async function GET() {
  try {
    // 1. ใช้ Prisma เพื่อดึงกิจกรรมทั้งหมดจากฐานข้อมูล
    const activities = await prisma.activity.findMany({
      orderBy: {
        id: 'asc',
      },
    })

    // 2. ส่งรายการกิจกรรมกลับไป โดยใช้การจัดรูปแบบ JSON
    // Note: NextResponse.json() บางครั้งไม่รองรับตัวเลือกนี้โดยตรง
    // ทางเลือก: เราจะส่ง Response แบบดิบด้วย JSON.stringify

    // --- ทางเลือกที่ 1: ใช้ NextResponse.json (ถ้า Next.js รองรับ) ---
    // return NextResponse.json(activities, { 
    //     status: 200, 
    //     //headers: { 'Content-Type': 'application/json' }
    // }); 

    // --- ทางเลือกที่ 2: ใช้ Response ธรรมดาพร้อมจัดรูปแบบ JSON ---
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

export async function OPTIONS() {
  return NextResponse.json({}, { status: 200, headers: corsHeaders });
}