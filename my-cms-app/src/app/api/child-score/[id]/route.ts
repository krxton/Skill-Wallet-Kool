// my-cms-app/src/app/api/child-score/[id]/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';

// Utility สำหรับ CORS
const ALLOWED_ORIGIN = 'http://localhost:3001';

interface RouteContext {
    params: { id: string };
}

// ----------------------------------------------------
// GET /api/child-score/[id] : ดึงคะแนนปัจจุบันของเด็ก
// ----------------------------------------------------
export async function GET(
    request: NextRequest,
    { params }: RouteContext
) {
    // *** การแก้ไข Workaround: Unpack params อย่างชัดเจนใน async context ***
    const unwrappedParams = await Promise.resolve(params);
    const childId = unwrappedParams.id;
    // ----------------------------------------------------

    if (!childId) {
        // Log นี้จะถูกเรียกเมื่อ Dev Server ส่ง undefined เข้ามา
        console.error('Missing child ID in API route params.'); 
        return NextResponse.json({ error: 'Child ID is required' }, { status: 400 });
    }

    try {
        const child = await prisma.child.findUnique({
            where: { id: childId },
            select: { score: true, fullName: true }
        });

        if (!child) {
            return NextResponse.json({ error: 'Child not found' }, { status: 404 });
        }

        // ส่งคะแนนปัจจุบันกลับไป
        return NextResponse.json({
            childName: child.fullName,
            currentScore: child.score,
        }, {
            status: 200,
            headers: {
                // อนุญาต CORS สำหรับ GET
                'Access-Control-Allow-Origin': ALLOWED_ORIGIN,
            }
        });

    } catch (error) {
        console.error('Error fetching child score:', error);
        return NextResponse.json({ error: 'Internal Server Error' }, { status: 500 });
    }
}