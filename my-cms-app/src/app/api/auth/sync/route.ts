// app/api/auth/sync/route.ts
// 🎯 API สำหรับ sync Clerk user → Prisma Parent

import { auth, currentUser } from '@clerk/nextjs/server'
import { NextResponse } from 'next/server'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

export async function POST() {
  try {
    // 1. ตรวจสอบ authentication (รองรับ Next.js 15+)
    const authResult = await auth()
    const userId = authResult?.userId
    
    if (!userId) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 }
      )
    }

    // 2. ดึงข้อมูลจาก Clerk
    const user = await currentUser()
    
    if (!user) {
      return NextResponse.json(
        { error: 'User not found' },
        { status: 404 }
      )
    }

    // 3. หา Parent ใน database (หรือสร้างใหม่)
    const parent = await prisma.parent.upsert({
      where: { id: userId },
      update: {
        fullName: `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.username || 'User',
        email: user.emailAddresses[0]?.emailAddress || '',
        photoUrl: user.imageUrl || null,
        verification: 'Verified'
      },
      create: {
        id: userId, // ใช้ Clerk User ID
        fullName: `${user.firstName || ''} ${user.lastName || ''}`.trim() || user.username || 'User',
        email: user.emailAddresses[0]?.emailAddress || '',
        photoUrl: user.imageUrl || null,
        status: 'Active',
        verification: 'Verified'
      }
    })

    // 4. ดึงข้อมูลลูกทั้งหมด
    const children = await prisma.parentChild.findMany({
      where: { parentId: userId },
      include: {
        child: true
      }
    })

    // 5. Return ข้อมูล
    return NextResponse.json({
      success: true,
      parent: {
        id: parent.id,
        fullName: parent.fullName,
        email: parent.email,
        photoUrl: parent.photoUrl
      },
      hasChildren: children.length > 0,
      children: children.map(pc => ({
        id: pc.child.id,
        fullName: pc.child.fullName,
        dob: pc.child.dob,
        score: pc.child.score,
        relationship: pc.relationship
      }))
    })

  } catch (error) {
    console.error('Auth sync error:', error)
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    )
  } finally {
    await prisma.$disconnect()
  }
}