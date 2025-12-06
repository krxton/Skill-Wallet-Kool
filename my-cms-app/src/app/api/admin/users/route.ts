// src/app/api/admin/users/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { Prisma } from '@prisma/client';

/**
 * @swagger
 * /api/admin/users:
 *   get:
 *     tags:
 *       - Admin - Users
 *     summary: ดึงรายการผู้ปกครองทั้งหมด (สำหรับ Admin)
 *     description: |
 *       ดึงข้อมูลผู้ปกครองพร้อม Pagination และการค้นหา
 *       - รองรับการค้นหาตามชื่อหรืออีเมล
 *       - แสดงจำนวนลูกของแต่ละผู้ปกครอง
 *       - เรียงตามวันที่สร้างล่าสุด
 *     parameters:
 *       - in: query
 *         name: page
 *         schema:
 *           type: integer
 *           default: 1
 *           minimum: 1
 *         description: หน้าปัจจุบัน
 *         example: 1
 *       - in: query
 *         name: limit
 *         schema:
 *           type: integer
 *           default: 6
 *           minimum: 1
 *           maximum: 100
 *         description: จำนวนรายการต่อหน้า
 *         example: 6
 *       - in: query
 *         name: search
 *         schema:
 *           type: string
 *         description: คำค้นหา (ชื่อเต็มหรืออีเมล) - ไม่สนตัวพิมพ์เล็ก/ใหญ่
 *         example: ""
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 data:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       id:
 *                         type: string
 *                         example: "clparent12345"
 *                       fullName:
 *                         type: string
 *                         example: "สมชาย ใจดี"
 *                       email:
 *                         type: string
 *                         example: "somchai@example.com"
 *                       createdAt:
 *                         type: string
 *                         format: date-time
 *                         example: "2025-12-06T10:00:00.000Z"
 *                       status:
 *                         type: string
 *                         example: "Active"
 *                       verification:
 *                         type: string
 *                         example: "Verified"
 *                       _count:
 *                         type: object
 *                         properties:
 *                           children:
 *                             type: integer
 *                             description: จำนวนลูกของผู้ปกครอง
 *                             example: 2
 *                 pagination:
 *                   type: object
 *                   properties:
 *                     totalItems:
 *                       type: integer
 *                       description: จำนวนรายการทั้งหมด
 *                       example: 25
 *                     totalPages:
 *                       type: integer
 *                       description: จำนวนหน้าทั้งหมด
 *                       example: 5
 *                     currentPage:
 *                       type: integer
 *                       description: หน้าปัจจุบัน
 *                       example: 1
 *                     itemsPerPage:
 *                       type: integer
 *                       description: จำนวนรายการต่อหน้า
 *                       example: 6
 *             examples:
 *               success:
 *                 summary: ตัวอย่างการดึงข้อมูลสำเร็จ
 *                 value:
 *                   data:
 *                     - id: "clparent001"
 *                       fullName: "สมชาย ใจดี"
 *                       email: "somchai@example.com"
 *                       createdAt: "2025-12-06T10:00:00.000Z"
 *                       status: "Active"
 *                       verification: "Verified"
 *                       _count:
 *                         children: 2
 *                     - id: "clparent002"
 *                       fullName: "สมหญิง รักดี"
 *                       email: "somying@example.com"
 *                       createdAt: "2025-12-05T15:30:00.000Z"
 *                       status: "Active"
 *                       verification: "Unverified"
 *                       _count:
 *                         children: 1
 *                   pagination:
 *                     totalItems: 25
 *                     totalPages: 5
 *                     currentPage: 1
 *                     itemsPerPage: 6
 *               withSearch:
 *                 summary: ตัวอย่างการค้นหา
 *                 value:
 *                   data:
 *                     - id: "clparent001"
 *                       fullName: "สมชาย ใจดี"
 *                       email: "somchai@example.com"
 *                       createdAt: "2025-12-06T10:00:00.000Z"
 *                       status: "Active"
 *                       verification: "Verified"
 *                       _count:
 *                         children: 2
 *                   pagination:
 *                     totalItems: 1
 *                     totalPages: 1
 *                     currentPage: 1
 *                     itemsPerPage: 6
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               generalError:
 *                 summary: ข้อผิดพลาดทั่วไป
 *                 value:
 *                   error: "Failed to fetch user data."
 *               databaseError:
 *                 summary: ข้อผิดพลาดจาก Database
 *                 value:
 *                   error: "Database Error: P2002"
 */
export async function GET(request: NextRequest) {
    try {
        const { searchParams } = new URL(request.url);
        
        // 1. Pagination Parameters
        const page = parseInt(searchParams.get('page') || '1', 10);
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
                            mode: 'insensitive',
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
            : {};

        // 4. Fetch data and total count in parallel
        const [parents, totalCount] = await prisma.$transaction([
            prisma.parent.findMany({
                where: where,
                take: limit,
                skip: skip,
                orderBy: {
                    createdAt: 'desc',
                },
                include: {
                    _count: {
                        select: { children: true },
                    },
                },
            }),
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
        if (error instanceof Prisma.PrismaClientKnownRequestError) {
             return NextResponse.json({ error: `Database Error: ${error.code}` }, { status: 500 });
        }
        return NextResponse.json({ error: 'Failed to fetch user data.' }, { status: 500 });
    }
}