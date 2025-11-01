import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// ข้อมูลที่เราจะ Mockup
const parentData = [
  { id: 'PR1', fullName: 'คันธารัตน์ อเนกบุณย์', email: 'khantharat.a@sci.kmutnb.ac.th' },
  { id: 'PR2', fullName: 'สุวัจชัย กมลสันติโรจน์', email: 'suwatchai.k@sci.kmutnb.ac.th' },
  { id: 'PR3', fullName: 'ธรรศฏภณ สุระศักดิ์', email: 'thattapon.s@sci.kmutnb.ac.th' },
];

const childData = [
  { id: 'CH1', fullName: 'ณัฐิวุฒิ สำเภาพันธ์', dob: new Date('2004-05-12'), score: 180 },
  { id: 'CH2', fullName: 'ณัฏฐณิชา อ่อนสุวรรณ์', dob: new Date('2004-05-20'), score: 540 },
  { id: 'CH3', fullName: 'ณัฐชนน พูลเพิ่ม', dob: new Date('2003-09-12'), score: 600 },
  { id: 'CH4', fullName: 'กฤตณัฐ สาโถน', dob: new Date('2003-03-10'), score: 720 },
];

const parentChildData = [
  { parentId: 'PR1', childId: 'CH1', relationship: 'มารดา' },
  { parentId: 'PR2', childId: 'CH2', relationship: 'บิดา' },
  { parentId: 'PR2', childId: 'CH3', relationship: 'บิดา' },
  { parentId: 'PR3', childId: 'CH4', relationship: 'บิดา' },
];

const rewardData = [
    { id: 'RW1', name: 'YouTube : 30 นาที', cost: 120 }, 
    { id: 'RW2', name: 'ตุ๊กตาหมี : 1 ตัว', cost: 420 },
    { id: 'RW3', name: 'กันดรัม : 1 ตัว', cost: 680 },
];

const parentRewardData = [
    { parentId: 'PR1', rewardId: 'RW1' },
    { parentId: 'PR2', rewardId: 'RW2' },
    { parentId: 'PR3', rewardId: 'RW3' },
];

// 🗑️ ลบส่วนนี้ออก - ไม่สร้าง Activity ใน seed อีกต่อไป
// const activityData = [...];

async function main() {
  console.log(`🌱 Start seeding ...`);

  // *** 1. ลบข้อมูลเก่าตามลำดับ (ลำดับสำคัญมาก) ***
  console.log('🗑️  Deleting old data...');
  
  await prisma.activityRecord.deleteMany({});     // 1. ActivityRecord
  console.log('   ✅ Deleted ActivityRecords');
  
  await prisma.rewardRedemption.deleteMany({});   // 2. RewardRedemption
  console.log('   ✅ Deleted RewardRedemptions');
  
  await prisma.parentReward.deleteMany({});       // 3. ParentReward
  console.log('   ✅ Deleted ParentRewards');
  
  await prisma.parentChild.deleteMany({});        // 4. ParentChild
  console.log('   ✅ Deleted ParentChildren');

  // ลบ Entity หลัก (หลังจากตารางที่อ้างอิงถูกลบแล้ว)
  await prisma.reward.deleteMany({});             // 5. Reward
  console.log('   ✅ Deleted Rewards');
  
  await prisma.activity.deleteMany({});           // 6. Activity
  console.log('   ✅ Deleted Activities');
  
  await prisma.child.deleteMany({});              // 7. Child
  console.log('   ✅ Deleted Children');
  
  await prisma.parent.deleteMany({});             // 8. Parent
  console.log('   ✅ Deleted Parents');

  console.log('✨ Old data deleted.\n');

  // 2. สร้าง Parent (ผู้ปกครอง)
  for (const p of parentData) {
    await prisma.parent.create({
      data: {
        id: p.id,
        fullName: p.fullName,
        email: p.email,
      },
    });
  }
  console.log('✅ Parents created.');

  // 3. สร้าง Child (เด็ก)
  for (const c of childData) {
    await prisma.child.create({
      data: {
        id: c.id,
        fullName: c.fullName,
        dob: c.dob,
        score: c.score,
      },
    });
  }
  console.log('✅ Children created.');
  
  // 4. สร้าง ParentChild (ความสัมพันธ์)
  for (const pc of parentChildData) {
    await prisma.parentChild.create({
      data: pc,
    });
  }
  console.log('✅ ParentChild relations created.');

  // 5. สร้าง Reward (ของรางวัล)
  for (const r of rewardData) {
    await prisma.reward.create({
      data: r,
    });
  }
  console.log('✅ Rewards created.');
  
  // 6. สร้าง ParentReward (ความสัมพันธ์ผู้ปกครองกับรางวัล)
  for (const pr of parentRewardData) {
      await prisma.parentReward.create({
          data: pr,
      });
  }
  console.log('✅ ParentReward relations created.');

  // 🆕 7. ไม่สร้าง Activity - จะสร้างผ่าน CMS
  console.log('📝 Activities: Ready to create via CMS\n');

  console.log('🎉 Seeding finished successfully!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });