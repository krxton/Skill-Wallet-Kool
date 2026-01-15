// app/api/activities/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

// Helper function to safely serialize JSON fields
function safeJsonSerialize(value: any) {
  if (value === null || value === undefined) return null;
  
  // ถ้าเป็น string แล้ว ให้ parse ก่อน
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch {
      return value;
    }
  }
  
  // ถ้าเป็น object อยู่แล้ว return ตรงๆ
  return value;
}

// GET: ดึง activities ทั้งหมด
export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const category = searchParams.get('category');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const skip = (page - 1) * limit;

    // Build where clause
    const where: any = {};

    if (search) {
      where.name_activity = {
        contains: search,
        mode: 'insensitive'
      };
    }

    if (category && category !== 'all') {
      where.category = category;
    }

    // Get total count
    const totalCount = await prisma.activity.count({ where });
    const totalPages = Math.ceil(totalCount / limit);

    // Get activities
    const activities = await prisma.activity.findMany({
      where,
      skip,
      take: limit,
      select: {
        activity_id: true,
        name_activity: true,
        category: true,
        content: true,
        level_activity: true,
        maxscore: true,
        description_activity: true,
        segments: true,
        videourl: true,
        thumbnailurl: true,
        play_count: true,
        created_at: true,
        update_at: true,
        parent_id: true,
      },
      orderBy: {
        created_at: 'desc'
      }
    });

    // แปลงเป็น format ที่ frontend ต้องการ
    const activitiesResponse = activities.map(activity => {
      try {
        return {
          // Format สำหรับ admin UI
          activityId: activity.activity_id,
          nameActivity: activity.name_activity,
          category: activity.category,
          descriptionActivity: activity.description_activity || '',
          createdAt: activity.created_at.toISOString(),
          responses: 0,
          
          // Format สำหรับ EditForm
          id: activity.activity_id,
          name: activity.name_activity,
          difficulty: activity.level_activity,
          maxScore: Number(activity.maxscore),
          content: activity.content,
          description: activity.description_activity || '',
          videoUrl: activity.videourl || '',
          thumbnailUrl: activity.thumbnailurl || '',
          segments: safeJsonSerialize(activity.segments), // ✅ จัดการ JSON field
          playCount: activity.play_count ? Number(activity.play_count) : 0,
          parentId: activity.parent_id,
          updatedAt: activity.update_at.toISOString(),
        };
      } catch (err) {
        console.error('Error serializing activity:', activity.activity_id, err);
        // Return minimal data ถ้า serialize ไม่ได้
        return {
          activityId: activity.activity_id,
          nameActivity: activity.name_activity,
          category: activity.category,
          descriptionActivity: activity.description_activity || '',
          createdAt: activity.created_at.toISOString(),
          responses: 0,
          id: activity.activity_id,
          name: activity.name_activity,
          difficulty: activity.level_activity,
          maxScore: Number(activity.maxscore),
          content: activity.content,
          description: activity.description_activity || '',
          videoUrl: activity.videourl || '',
          thumbnailUrl: activity.thumbnailurl || '',
          segments: null,
          playCount: 0,
          parentId: activity.parent_id,
          updatedAt: activity.update_at.toISOString(),
        };
      }
    });

    // Return with proper structure (match frontend expectations)
    const response = {
      success: true,  // ✅ เพิ่ม success flag
      data: activitiesResponse,  // ✅ ใช้ data แทน activities
      pagination: {
        currentPage: page,
        totalPages,
        total: totalCount,  // ✅ ใช้ total แทน totalCount
        limit
      }
    };

    return NextResponse.json(response);
  } catch (error: any) {
    console.error('GET /api/activities error:', error);
    
    // Return proper error response
    return NextResponse.json(
      { 
        success: false,  // ✅ เพิ่ม success: false
        error: 'Failed to fetch activities', 
        details: error.message,
        data: [],  // ✅ ใช้ data แทน activities
        pagination: {
          currentPage: 1,
          totalPages: 0,
          total: 0,  // ✅ ใช้ total แทน totalCount
          limit: 10
        }
      },
      { status: 500 }
    );
  }
}

// POST: สร้าง activity ใหม่
export async function POST(request: Request) {
  try {
    const body = await request.json();

    // Validate required fields
    if (!body.name) {
      return NextResponse.json(
        { error: 'name is required' },
        { status: 400 }
      );
    }

    if (!body.category) {
      return NextResponse.json(
        { error: 'category is required' },
        { status: 400 }
      );
    }

    if (!body.content) {
      return NextResponse.json(
        { error: 'content is required' },
        { status: 400 }
      );
    }

    if (!body.difficulty) {
      return NextResponse.json(
        { error: 'difficulty is required' },
        { status: 400 }
      );
    }

    if (body.maxScore === undefined) {
      return NextResponse.json(
        { error: 'maxScore is required' },
        { status: 400 }
      );
    }

    if (!body.parentId) {
      return NextResponse.json(
        { error: 'parentId is required' },
        { status: 400 }
      );
    }

    // Prepare segments data
    let segmentsData = null;
    if (body.segments) {
      segmentsData = typeof body.segments === 'string' 
        ? JSON.parse(body.segments) 
        : body.segments;
    }

    // Create activity
    const activity = await prisma.activity.create({
      data: {
        name_activity: body.name,
        category: body.category,
        content: body.content,
        level_activity: body.difficulty,
        maxscore: body.maxScore,
        description_activity: body.description || '',
        segments: segmentsData,
        videourl: body.videoUrl || null,
        thumbnailurl: body.thumbnailUrl || null,
        parent_id: body.parentId,
        update_at: new Date(),
      }
    });

    // Return response
    const activityResponse = {
      activityId: activity.activity_id,
      nameActivity: activity.name_activity,
      category: activity.category,
      descriptionActivity: activity.description_activity || '',
      id: activity.activity_id,
      name: activity.name_activity,
      difficulty: activity.level_activity,
      maxScore: Number(activity.maxscore),
      videoUrl: activity.videourl || '',
      thumbnailUrl: activity.thumbnailurl || '',
      content: activity.content,
      description: activity.description_activity || '',
      segments: safeJsonSerialize(activity.segments),
      parentId: activity.parent_id,
      createdAt: activity.created_at.toISOString(),
      updatedAt: activity.update_at.toISOString(),
    };

    return NextResponse.json(activityResponse, { status: 201 });
  } catch (error: any) {
    console.error('POST /api/activities error:', error);
    return NextResponse.json(
      { error: 'Failed to create activity', details: error.message },
      { status: 400 }
    );
  }
}