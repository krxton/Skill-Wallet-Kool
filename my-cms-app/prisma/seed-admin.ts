/**
 * Seed script to create the initial admin user.
 * Run once after deploying Better Auth:
 *   npx ts-node --compiler-options '{"module":"CommonJS"}' prisma/seed-admin.ts
 *
 * Change ADMIN_EMAIL and ADMIN_PASSWORD before running!
 */

import { PrismaClient } from '@prisma/client'
import { createHmac, randomBytes } from 'crypto'

const prisma = new PrismaClient()

const ADMIN_EMAIL = 'admin@swk.local'
const ADMIN_PASSWORD = 'SwkAdmin2026!'
const ADMIN_NAME = 'SWK Admin'

function hashPassword(password: string): string {
  // Better Auth uses bcrypt by default, but for seeding we call the auth API.
  // This is a placeholder — use the /api/auth/sign-up/email endpoint instead.
  throw new Error('Use the API endpoint to create the admin user (see instructions below)')
}

async function main() {
  console.log('='.repeat(60))
  console.log('SWK Admin Seed Script')
  console.log('='.repeat(60))
  console.log()
  console.log('To create the admin user, call this API endpoint:')
  console.log()
  console.log('  POST /api/auth/sign-up/email')
  console.log('  Body:', JSON.stringify({
    email: ADMIN_EMAIL,
    password: ADMIN_PASSWORD,
    name: ADMIN_NAME,
  }, null, 2))
  console.log()
  console.log('Then update the role to admin in the database:')
  console.log()
  console.log(`  UPDATE ba_user SET role = 'admin' WHERE email = '${ADMIN_EMAIL}';`)
  console.log()
  console.log('Or use pgAdmin at http://103.216.158.225:5050')
  console.log()

  // Check if admin already exists
  const existing = await prisma.user.findUnique({ where: { email: ADMIN_EMAIL } })
  if (existing) {
    console.log(`Admin user already exists: ${existing.email} (role: ${existing.role})`)
    if (existing.role !== 'admin') {
      await prisma.user.update({
        where: { email: ADMIN_EMAIL },
        data: { role: 'admin' },
      })
      console.log('  → Role updated to admin')
    }
  } else {
    console.log('Admin user not found. Please sign up via the API first, then re-run this script.')
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
