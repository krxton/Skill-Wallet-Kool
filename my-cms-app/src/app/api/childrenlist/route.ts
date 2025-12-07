// app/api/children/list/route.ts
// 🎯 API สำหรับดึงรายการลูกทั้งหมด

import { auth } from '@clerk/nextjs/server'
import { NextResponse } from 'next/server'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export async function GET() {
  try {
    // 1. ตรวจสอบ authentication
    const authResult = await auth()
    const userId = authResult?.userId
    
    if (!userId) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // 2. ดึงรายการลูกทั้งหมด
    const children = await prisma.parentChild.findMany({
      where: { parentId: userId },
      include: {
        child: {
          select: {
            id: true,
            fullName: true,
            dob: true,
            score: true,
            scoreUpdate: true
          }
        }
      },
      orderBy: {
        child: {
          fullName: 'asc'
        }
      }
    })

    // 3. Return formatted data
    return NextResponse.json({
      success: true,
      hasChildren: children.length > 0,
      count: children.length,
      children: children.map(pc => ({
        id: pc.child.id,
        fullName: pc.child.fullName,
        dob: pc.child.dob,
        score: pc.child.score,
        scoreUpdate: pc.child.scoreUpdate,
        relationship: pc.relationship
      }))
    })

  } catch (error) {
    console.error('List children error:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  } finally {
    await prisma.$disconnect()
  }
}