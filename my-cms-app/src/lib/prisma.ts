// src/lib/prisma.ts
import { PrismaClient } from '@prisma/client'

// 1. สร้าง Type สำหรับ Global Prisma Client
type PrismaClientSingleton = PrismaClient
// 2. ขยาย Global Interface เพื่อเพิ่ม Prisma Client เข้าไป
declare global {
  // eslint-disable-next-line no-var
  var prismaGlobal: PrismaClientSingleton | undefined
}

// 3. สร้าง Client Instance ที่ใช้ร่วมกัน (Singleton)
const prisma = globalThis.prismaGlobal ?? new PrismaClient()

// 4. Export Client ที่สร้างขึ้น
export default prisma

// 5. ป้องกันการสร้าง Client ซ้ำซ้อนในโหมด Development
if (process.env.NODE_ENV !== 'production') {
  globalThis.prismaGlobal = prisma
}