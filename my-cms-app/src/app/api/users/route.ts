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
        users: { // ถ้ามี users relation
          select: {
            id: true
            // เพิ่มฟิลด์อื่นๆ ที่ต้องการ เช่น status, verification, photoUrl
          }
        }
      },
      orderBy: {
        created_date: 'desc'
      }
    });

    // Transform to match frontend interface
    const users = parents.map((parent) => ({
      id: parent.parent_id,
      fullName: parent.name_surname || 'N/A',
      email: parent.email,
      // ⚠️ ฟิลด์เหล่านี้ไม่มีใน parent table - ต้องเพิ่มหรือใช้ default value
      status: 'Active', // TODO: เพิ่มฟิลด์นี้ใน schema
      verification: 'Verified', // TODO: เพิ่มฟิลด์นี้ใน schema
      photoUrl: undefined, // TODO: เพิ่มฟิลด์นี้ใน schema
      createdAt: parent.created_date.toISOString(),
      childrenCount: parent.parent_and_child.length,
      activityRecordCount: parent.activity_record.length
    }));

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