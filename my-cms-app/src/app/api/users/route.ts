// app/api/users/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const status = searchParams.get('status');
    const verification = searchParams.get('verification');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const skip = (page - 1) * limit;

    // Build where clause
    const where: any = {};

    if (search) {
      where.OR = [
        {
          name_surname: {
            contains: search,
            mode: 'insensitive'
          }
        },
        {
          email: {
            contains: search,
            mode: 'insensitive'
          }
        }
      ];
    }

    // Note: status และ verification ไม่มีใน parent table
    // คุณอาจต้องเพิ่มฟิลด์เหล่านี้ใน schema หรือใช้ users table

    // Get total count
    const totalCount = await prisma.parent.count({ where });
    const totalPages = Math.ceil(totalCount / limit);

    // Get parents with relations
    const parents = await prisma.parent.findMany({
      where,
      skip,
      take: limit,
      include: {
        parent_and_child: {
          include: {
            child: true
          }
        },
        activity_record: {
          select: {
            ActivityRecord_id: true
          }
        },
        users: {
          select: {
            id: true,
            raw_user_meta_data: true
          }
        }
      },
      orderBy: {
        created_date: 'desc'
      }
    });

    // Transform to match frontend interface
    const users = parents.map((parent) => {
      const meta = (parent.users?.raw_user_meta_data as Record<string, any>) || {};
      return {
        id: parent.parent_id,
        fullName: parent.name_surname || 'N/A',
        email: parent.email,
        role: meta.role || 'user',
        status: 'Active',
        verification: 'Verified',
        photoUrl: undefined,
        createdAt: parent.created_date.toISOString(),
        childrenCount: parent.parent_and_child.length,
        activityRecordCount: parent.activity_record.length
      };
    });

    return NextResponse.json({
      users,
      pagination: {
        currentPage: page,
        totalPages,
        totalCount,
        limit
      }
    });
  } catch (error: any) {
    console.error('GET /api/users error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch users', details: error.message },
      { status: 500 }
    );
  }
}