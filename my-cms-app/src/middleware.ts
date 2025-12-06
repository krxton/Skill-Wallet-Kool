// src/middleware.ts

import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

export function middleware(request: NextRequest) {
  // ตรวจสอบว่าเปิด Read-Only Mode หรือไม่
  const isReadOnlyMode = process.env.NEXT_PUBLIC_READONLY_MODE === 'true';
  
  // ตรวจสอบว่า request มาจาก Swagger UI หรือไม่
  const referer = request.headers.get('referer');
  const isFromSwagger = referer?.includes('/api-doc');
  
  // ถ้าเป็น Read-Only Mode และเป็น method ที่เปลี่ยนแปลงข้อมูล
  const isWriteOperation = ['POST', 'PUT', 'PATCH', 'DELETE'].includes(request.method);
  
  if (isReadOnlyMode && isWriteOperation) {
    return NextResponse.json(
      {
        error: 'Read-Only Mode',
        message: 'API อยู่ในโหมด Read-Only ไม่สามารถเปลี่ยนแปลงข้อมูลได้',
        tip: 'ถ้าต้องการทดสอบการเขียนข้อมูล กรุณาตั้งค่า NEXT_PUBLIC_READONLY_MODE=false',
      },
      { 
        status: 403,
        headers: {
          'Access-Control-Allow-Origin': '*',
          'X-Read-Only-Mode': 'true',
        },
      }
    );
  }
  
  // ถ้าเป็น request จาก Swagger และต้องการเตือน
  if (isFromSwagger && isWriteOperation && !isReadOnlyMode) {
    // เพิ่ม header เตือนว่ามาจาก Swagger
    const response = NextResponse.next();
    response.headers.set('X-Swagger-Warning', 'This operation will modify real data');
    return response;
  }
  
  return NextResponse.next();
}

// กำหนดว่า middleware จะทำงานกับ path ไหนบ้าง
export const config = {
  matcher: '/api/:path*',
};