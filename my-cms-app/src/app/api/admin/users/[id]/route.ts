import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { Prisma } from '@prisma/client';

// นี่คือ API สำหรับหน้ารายละเอียด User: /api/admin/users/[id]

/**
 * @method GET
 * @desc ดึงข้อมูลผู้ปกครอง (User) 1 คน พร้อมข้อมูลลูก
 * @param params - มี id ของผู้ปกครอง
 */
export async function GET(
    request: NextRequest,
    // context: { params: { id: string } } // <--- แบบเดิม
    context: any // <--- แก้ไข: ใช้ 'any' เพื่อจัดการกับ params ที่เป็น Promise
) {
    try {
        // const { id } = params; // <--- แบบเดิม (Fails)
        
        // <--- แก้ไข: Await context.params เพื่อให้ได้ค่าที่แท้จริง
        // นี่คือการแก้ไขตาม Error Log ของ Next.js ที่ว่า "params is a Promise"
        const params = await context.params;
        const id = params.id;
        // ---------------------------------------------------

        if (!id) {
            return NextResponse.json({ error: 'Parent ID is required.' }, { status: 400 });
        }

        // 1. ดึงข้อมูลผู้ปกครอง
        const parent = await prisma.parent.findUnique({
            where: {
                id: id,
            },
            include: {
                // 2. [IMPORTANT] ดึงข้อมูลความสัมพันธ์ (ParentChild)
                // และให้ดึงข้อมูล 'child' (ข้อมูลเด็ก) ที่อยู่ข้างในมาด้วย
                children: {
                    select: {
                        relationship: true, // ดึง 'ความสัมพันธ์' จากตารางเชื่อม
                        child: {
                            // ดึงข้อมูลจากตาราง Child
                            select: {
                                id: true,
                                fullName: true,
                                dob: true,
                                score: true,
                            },
                        },
                    },
                },
            },
        });

        // 3. ตรวจสอบว่าเจอผู้ปกครองหรือไม่
        if (!parent) {
            return NextResponse.json({ error: 'Parent not found.' }, { status: 404 });
        }

        // 4. ส่งข้อมูลกลับ
        return NextResponse.json(parent);

    } catch (error) {
        // <--- แก้ไข: ปรับปรุงการดักจับ Error
        const errorId = context?.params?.id || (await context?.params)?.id || "unknown";
        console.error(`Failed to fetch user detail for ID: ${errorId}`, error);

        // ตรวจสอบว่าเป็น Prisma error (เช่น ID format ผิด)
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
            if (error.code === 'P2023' || error.code === 'P2025') {
                 // P2023: Invalid CUID/UUID, P2025: Record not found
                 return NextResponse.json({ error: 'Parent not found or Invalid ID format.' }, { status: 404 });
            }
             return NextResponse.json({ error: `Database Error: ${error.code}` }, { status: 500 });
        }

        return NextResponse.json({ error: 'Failed to fetch user detail.' }, { status: 500 });
    }
}

