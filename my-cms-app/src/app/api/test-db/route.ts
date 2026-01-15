const { PrismaClient } = require('@prisma/client')
const prisma = new PrismaClient()

async function main() {
  console.log('🧪 Testing database connection...')
  
  const parentCount = await prisma.parent.count()
  console.log('✅ Parents:', parentCount)
  
  const activityCount = await prisma.activity.count()
  console.log('✅ Activities:', activityCount)
  
  const childCount = await prisma.child.count()
  console.log('✅ Children:', childCount)
}

main()
  .then(() => {
    console.log('✅ Database connection successful!')
    process.exit(0)
  })
  .catch((e) => {
    console.error('❌ Database connection failed:', e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })