// src/app/api/admin/users/[id]/route.ts

import { NextResponse, NextRequest } from 'next/server';
import prisma from '@/lib/prisma';
import { Prisma } from '@prisma/client';

/**
 * @swagger
 * /api/admin/users/{id}:
 *   get:
 *     tags:
 *       - Admin - Users
 *     summary: ดึงข้อมูลผู้ปกครอง 1 คน (สำหรับ Admin)
 *     description: |
 *       ดึงข้อมูลผู้ปกครองรายละเอียดพร้อมข้อมูลลูกทั้งหมด
 *       - แสดงข้อมูลผู้ปกครองทั้งหมด
 *       - แสดงรายการลูกพร้อมความสัมพันธ์
 *       - แสดงคะแนนของแต่ละลูก
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *         description: Parent ID
 *         example: "PR2"
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: string
 *                   description: Parent ID
 *                   example: "clparent12345"
 *                 fullName:
 *                   type: string
 *                   description: ชื่อเต็มของผู้ปกครอง
 *                   example: "สมชาย ใจดี"
 *                 email:
 *                   type: string
 *                   format: email
 *                   description: อีเมลของผู้ปกครอง
 *                   example: "somchai@example.com"
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *                   description: วันที่สร้างบัญชี
 *                   example: "2025-12-06T10:00:00.000Z"
 *                 status:
 *                   type: string
 *                   description: สถานะบัญชี
 *                   enum: ['Active', 'Inactive']
 *                   example: "Active"
 *                 verification:
 *                   type: string
 *                   description: สถานะการยืนยันตัวตน
 *                   enum: ['Verified', 'Unverified']
 *                   example: "Verified"
 *                 children:
 *                   type: array
 *                   description: รายการลูกของผู้ปกครอง
 *                   items:
 *                     type: object
 *                     properties:
 *                       relationship:
 *                         type: string
 *                         description: ความสัมพันธ์กับลูก
 *                         example: "Father"
 *                       child:
 *                         type: object
 *                         description: ข้อมูลลูก
 *                         properties:
 *                           id:
 *                             type: string
 *                             description: Child ID
 *                             example: "clchild12345"
 *                           fullName:
 *                             type: string
 *                             description: ชื่อเต็มของลูก
 *                             example: "ด.ญ. สมศรี ใจดี"
 *                           dob:
 *                             type: string
 *                             format: date-time
 *                             nullable: true
 *                             description: วันเกิดของลูก
 *                             example: "2018-05-15T00:00:00.000Z"
 *                           score:
 *                             type: integer
 *                             description: คะแนนสะสมของลูก
 *                             example: 350
 *             examples:
 *               success:
 *                 summary: ตัวอย่างข้อมูลผู้ปกครองที่มีลูก 2 คน
 *                 value:
 *                   id: "clparent001"
 *                   fullName: "สมชาย ใจดี"
 *                   email: "somchai@example.com"
 *                   createdAt: "2025-12-06T10:00:00.000Z"
 *                   status: "Active"
 *                   verification: "Verified"
 *                   children:
 *                     - relationship: "Father"
 *                       child:
 *                         id: "clchild001"
 *                         fullName: "ด.ญ. สมศรี ใจดี"
 *                         dob: "2018-05-15T00:00:00.000Z"
 *                         score: 350
 *                     - relationship: "Father"
 *                       child:
 *                         id: "clchild002"
 *                         fullName: "ด.ช. สมหมาย ใจดี"
 *                         dob: "2020-08-20T00:00:00.000Z"
 *                         score: 180
 *               noChildren:
 *                 summary: ตัวอย่างผู้ปกครองที่ยังไม่มีลูก
 *                 value:
 *                   id: "clparent002"
 *                   fullName: "สมหญิง รักดี"
 *                   email: "somying@example.com"
 *                   createdAt: "2025-12-05T15:30:00.000Z"
 *                   status: "Active"
 *                   verification: "Unverified"
 *                   children: []
 *       400:
 *         description: Bad Request - ไม่มี Parent ID
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             example:
 *               error: "Parent ID is required."
 *       404:
 *         description: Not Found - ไม่พบผู้ปกครองหรือ ID ไม่ถูกต้อง
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               notFound:
 *                 summary: ไม่พบผู้ปกครอง
 *                 value:
 *                   error: "Parent not found."
 *               invalidId:
 *                 summary: รูปแบบ ID ไม่ถูกต้อง
 *                 value:
 *                   error: "Parent not found or Invalid ID format."
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
 *                   error: "Failed to fetch user detail."
 *               databaseError:
 *                 summary: ข้อผิดพลาดจาก Database
 *                 value:
 *                   error: "Database Error: P2002"
 */
export async function GET(
    request: NextRequest,
    context: any
) {
    try {
        // Await context.params เพื่อให้ได้ค่าที่แท้จริง
        const params = await context.params;
        const id = params.id;

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