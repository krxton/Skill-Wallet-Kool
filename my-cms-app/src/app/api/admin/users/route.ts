import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { Prisma } from '@prisma/client';

// นี่คือ API สำหรับหน้า User List หลัก: /api/admin/users

/**
 * @method GET
 * @desc ดึงข้อมูลผู้ปกครอง (Users) ทั้งหมด
 * @query page - หน้าปัจจุบัน (default: 1)
 * @query limit - จำนวนต่อหน้า (default: 6)
 * @query search - คำค้นหา (fullName or email)
 */
export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        
        // 1. Pagination Parameters
        const page = parseInt(searchParams.get('page') || '1', 10);
        // ตั้งค่า limit เริ่มต้นเป็น 6 เพื่อให้ตรงกับ Wireframe
        const limit = parseInt(searchParams.get('limit') || '6', 10); 
        const skip = (page - 1) * limit;

        // 2. Search Parameter
        const search = searchParams.get('search') || '';

        // 3. Prisma 'where' clause for searching
        const where: Prisma.ParentWhereInput = search
            ? {
                OR: [
                    {
                        fullName: {
                            contains: search,
                            mode: 'insensitive', // ค้นหาแบบไม่สนตัวพิมพ์เล็ก/ใหญ่
                        },
                    },
                    {
                        email: {
                            contains: search,
                            mode: 'insensitive',
                        },
                    },
                ],
            }
            : {}; // ถ้าไม่มี 'search' ก็เป็น object ว่าง (ดึงทั้งหมด)

        // 4. Fetch data and total count in parallel
        const [parents, totalCount] = await prisma.$transaction([
            // Query ที่ 1: ดึงข้อมูลผู้ปกครอง (ตามหน้า, ค้นหา)
            prisma.parent.findMany({
                where: where,
                take: limit,
                skip: skip,
                orderBy: {
                    createdAt: 'desc', // เรียงตามวันที่สร้างล่าสุด
                },
                include: {
                    // *** [IMPORTANT] นี่คือส่วนที่นับจำนวนลูก ***
                    _count: {
                        select: { children: true },
                    },
                },
            }),
            // Query ที่ 2: นับจำนวนผู้ปกครองทั้งหมด (ที่ตรงเงื่อนไขค้นหา)
            prisma.parent.count({
                where: where,
            }),
        ]);

        // 5. Calculate total pages
        const totalPages = Math.ceil(totalCount / limit);

        // 6. Return response
        return NextResponse.json({
            data: parents,
            pagination: {
                totalItems: totalCount,
                totalPages: totalPages,
                currentPage: page,
                itemsPerPage: limit,
            },
        });

    } catch (error) {
        console.error('Failed to fetch users:', error);
        // ตรวจสอบว่าเป็น Prisma error หรือไม่
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
             return NextResponse.json({ error: `Database Error: ${error.code}` }, { status: 500 });
        }
        return NextResponse.json({ error: 'Failed to fetch user data.' }, { status: 500 });
    }
}

