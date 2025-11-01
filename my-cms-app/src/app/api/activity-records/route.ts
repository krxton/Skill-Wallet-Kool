// src/app/api/activity-records/route.ts (สร้างใหม่ถ้ายังไม่มี)

import { NextRequest, NextResponse } from 'next/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

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

    return NextResponse.json(records);
  } catch (error) {
    console.error('Error fetching activity records:', error);
    return NextResponse.json(
      { error: 'Failed to fetch activity records' },
      { status: 500 }
    );
  }
}