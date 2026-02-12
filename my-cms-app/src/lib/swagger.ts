// lib/swagger.ts - สิ่งที่ต้องเพิ่ม/แก้ไข

import { createSwaggerSpec } from 'next-swagger-doc';

function getServerUrls() {
  const servers: Array<{ url: string; description: string }> = [];

  if (process.env.NODE_ENV === 'development') {
    servers.push({
      url: 'http://localhost:3000',
      description: '🟢 Local Development Server',
    });
  }

  if (process.env.NEXT_PUBLIC_NGROK_URL) {
    servers.push({
      url: process.env.NEXT_PUBLIC_NGROK_URL,
      description: '🔵 ngrok Tunnel (Testing)',
    });
  }

  if (process.env.NEXT_PUBLIC_VERCEL_URL) {
    const vercelUrl = `https://${process.env.NEXT_PUBLIC_VERCEL_URL}`;
    const isProduction = process.env.VERCEL_ENV === 'production';
    
    servers.push({
      url: vercelUrl,
      description: isProduction 
        ? '🟢 Vercel Production' 
        : '🟡 Vercel Preview',
    });
  }

  if (process.env.NEXT_PUBLIC_API_URL) {
    servers.push({
      url: process.env.NEXT_PUBLIC_API_URL,
      description: '🚀 Production API',
    });
  }

  if (servers.length === 0) {
    servers.push({
      url: 'http://localhost:3000',
      description: 'Default Server',
    });
  }

  return servers;
}

export const getApiDocs = () => {
  const spec = createSwaggerSpec({
    apiFolder: 'src/app/api',
    definition: {
      openapi: '3.0.0',
      info: {
        title: 'Parent-Child Activity Management API',
        version: '1.0.0',
        description: `
## API สำหรับจัดการกิจกรรม ผู้ปกครอง เด็ก และรางวัล

### Features:
- 📚 จัดการกิจกรรมและเนื้อหาการเรียนรู้
- 👨‍👩‍👧‍👦 ระบบผู้ปกครองและเด็ก
- 🎯 บันทึกผลการทำกิจกรรมและคะแนน
- 🎁 ระบบรางวัลและการแลกรางวัล
- 🎥 รองรับวิดีโอและ segments
- 🤖 AI Evaluation (Whisper Speech Recognition)
- 📊 ติดตามประวัติและสถิติ

### Tech Stack:
- Next.js 16 (App Router)
- PostgreSQL + Prisma ORM
- TypeScript
- OpenAI Whisper (Python)
- youtube-transcript-api (Python)

### Environment:
- **NODE_ENV**: ${process.env.NODE_ENV || 'development'}
- **Platform**: ${process.env.VERCEL ? 'Vercel' : 'Local'}

### CORS Policy:
- **All API endpoints** support CORS with \`Access-Control-Allow-Origin: *\`
- Suitable for Flutter/Mobile app integration
        `,
        contact: {
          name: 'API Support',
          email: 'support@example.com',
        },
        license: {
          name: 'MIT',
        },
      },
      servers: getServerUrls(),
      tags: [
        {
          name: 'Admin - Users',
          description: '👥 จัดการข้อมูลผู้ปกครองทั้งหมด (สำหรับ Admin)',
        },
        {
          name: 'Activities',
          description: '📚 จัดการกิจกรรม และดึงข้อมูลจาก YouTube',
        },
        {
          name: 'Parents',
          description: '👨‍👩‍👧 จัดการข้อมูลผู้ปกครอง',
        },
        {
          name: 'Children',
          description: '👶 จัดการข้อมูลเด็กและคะแนน',
        },
        {
          name: 'Rewards',
          description: '🎁 จัดการรางวัลและการแลกรางวัล',
        },
        {
          name: 'Activity Records',
          description: '📊 จัดการบันทึกการทำกิจกรรมและประวัติ',
        },
        {
          name: 'AI Evaluation',
          description: '🤖 ประเมินการออกเสียงด้วย AI (Whisper) และ Proxy',
        },
      ],
      components: {
        schemas: {
          Parent: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Parent ID (CUID)',
                example: 'clparent12345',
              },
              fullName: {
                type: 'string',
                description: 'ชื่อเต็มของผู้ปกครอง',
                example: 'สมชาย ใจดี',
              },
              email: {
                type: 'string',
                format: 'email',
                description: 'อีเมลของผู้ปกครอง',
                example: 'somchai@example.com',
              },
              createdAt: {
                type: 'string',
                format: 'date-time',
                description: 'วันที่สร้างบัญชี',
                example: '2025-12-06T10:00:00.000Z',
              },
              status: {
                type: 'string',
                description: 'สถานะบัญชี',
                enum: ['Active', 'Inactive'],
                example: 'Active',
              },
              verification: {
                type: 'string',
                description: 'สถานะการยืนยันตัวตน',
                enum: ['Verified', 'Unverified'],
                example: 'Verified',
              },
              _count: {
                type: 'object',
                description: 'จำนวนความสัมพันธ์',
                properties: {
                  children: {
                    type: 'integer',
                    description: 'จำนวนลูก',
                    example: 2,
                  },
                },
              },
            },
          },
          Child: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Child ID (CUID)',
                example: 'clchild12345',
              },
              fullName: {
                type: 'string',
                description: 'ชื่อเต็มของเด็ก',
                example: 'ด.ญ. สมศรี ใจดี',
              },
              dob: {
                type: 'string',
                format: 'date-time',
                nullable: true,
                description: 'วันเกิด',
                example: '2018-05-15T00:00:00.000Z',
              },
              score: {
                type: 'integer',
                description: 'คะแนนสะสมปัจจุบัน',
                example: 350,
              },
              scoreUpdate: {
                type: 'integer',
                description: 'คะแนนที่อัปเดตล่าสุด',
                example: 0,
              },
            },
          },
          Activity: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Activity ID (CUID)',
                example: 'cmiu3ysuu0001ulc42rg7kksb',
              },
              name: {
                type: 'string',
                description: 'ชื่อกิจกรรม',
                example: 'กิจกรรมเรียนรู้ตัวเลข',
              },
              category: {
                type: 'string',
                description: 'หมวดหมู่กิจกรรม',
                enum: ['ด้านคำนวณ', 'ด้านสังคม', 'ด้านร่างกาย', 'ด้านอารมณ์', 'ด้านภาษา'],
                example: 'ด้านคำนวณ',
              },
              content: {
                type: 'string',
                description: 'เนื้อหากิจกรรม',
                example: 'กิจกรรมสำหรับเด็กอายุ 3-5 ปี',
              },
              difficulty: {
                type: 'string',
                description: 'ระดับความยาก',
                enum: ['ง่าย', 'ปานกลาง', 'ยาก'],
                example: 'ง่าย',
              },
              maxScore: {
                type: 'integer',
                description: 'คะแนนสูงสุดที่ได้รับ',
                example: 100,
              },
              description: {
                type: 'string',
                nullable: true,
                description: 'คำอธิบายเพิ่มเติม',
                example: 'เรียนรู้การนับเลข 1-10',
              },
              videoUrl: {
                type: 'string',
                nullable: true,
                description: 'URL ของวิดีโอประกอบ',
                example: 'https://www.youtube.com/watch?v=abc123',
              },
              segments: {
                type: 'string',
                nullable: true,
                description: 'ข้อมูล segments ในรูปแบบ JSON string (คำถาม-คำตอบ)',
                example: '[{"id":"seg1","question":"1+1","answer":"2","solution":"","score":100}]',
              },
              createdAt: {
                type: 'string',
                format: 'date-time',
                description: 'วันที่สร้าง',
                example: '2025-12-06T09:45:39.949Z',
              },
              updatedAt: {
                type: 'string',
                format: 'date-time',
                description: 'วันที่อัปเดตล่าสุด',
                example: '2025-12-06T09:45:39.949Z',
              },
            },
          },
          ActivityInput: {
            type: 'object',
            required: ['name', 'category', 'content', 'difficulty', 'maxScore'],
            properties: {
              name: {
                type: 'string',
                description: 'ชื่อกิจกรรม',
                example: 'กิจกรรมเรียนรู้ตัวเลข',
              },
              category: {
                type: 'string',
                description: 'หมวดหมู่กิจกรรม',
                enum: ['ด้านคำนวณ', 'ด้านสังคม', 'ด้านร่างกาย', 'ด้านอารมณ์', 'ด้านภาษา'],
                example: 'ด้านคำนวณ',
              },
              content: {
                type: 'string',
                description: 'เนื้อหากิจกรรม',
                example: 'กิจกรรมสำหรับเด็กอายุ 3-5 ปี',
              },
              difficulty: {
                type: 'string',
                description: 'ระดับความยาก',
                enum: ['ง่าย', 'ปานกลาง', 'ยาก'],
                example: 'ง่าย',
              },
              maxScore: {
                type: 'integer',
                description: 'คะแนนสูงสุดที่ได้รับ',
                example: 100,
                minimum: 0,
              },
              description: {
                type: 'string',
                description: 'คำอธิบายเพิ่มเติม',
                example: 'เรียนรู้การนับเลข 1-10',
              },
              videoUrl: {
                type: 'string',
                nullable: true,
                description: 'URL ของวิดีโอประกอบ',
                example: 'https://www.youtube.com/watch?v=abc123',
              },
              segments: {
                type: 'array',
                description: 'รายการคำถาม-คำตอบในกิจกรรม',
                items: {
                  type: 'object',
                  properties: {
                    id: {
                      type: 'string',
                      example: 'seg1',
                    },
                    question: {
                      type: 'string',
                      example: '1+1',
                    },
                    answer: {
                      type: 'string',
                      example: '2',
                    },
                    solution: {
                      type: 'string',
                      example: '',
                    },
                    score: {
                      type: 'integer',
                      example: 100,
                    },
                  },
                },
              },
            },
          },
          ActivityRecord: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Activity Record ID (CUID)',
                example: 'clrecord12345',
              },
              activityId: {
                type: 'string',
                description: 'Activity ID ที่ทำ',
                example: 'clactivity12345',
              },
              parentId: {
                type: 'string',
                description: 'Parent ID',
                example: 'clparent12345',
              },
              childId: {
                type: 'string',
                description: 'Child ID ที่ทำกิจกรรม',
                example: 'clchild12345',
              },
              dateCompleted: {
                type: 'string',
                format: 'date-time',
                description: 'วันที่ทำกิจกรรมเสร็จ',
                example: '2024-12-06T10:30:00.000Z',
              },
              timeSpentSeconds: {
                type: 'integer',
                nullable: true,
                description: 'เวลาที่ใช้ (วินาที)',
                example: 300,
              },
              status: {
                type: 'string',
                description: 'สถานะการทำกิจกรรม',
                enum: ['Pending', 'Approved', 'Failed'],
                example: 'Approved',
              },
              detailResults: {
                type: 'object',
                nullable: true,
                description: 'ผลลัพธ์โดยละเอียด (JSON)',
                example: { 
                  questType: 'ด้านภาษา',
                  results: [],
                  evidence: {},
                  description: 'ลูกทำได้ดีมาก'
                },
              },
              scoreEarned: {
                type: 'number',
                description: 'คะแนนที่ได้รับ',
                example: 85.5,
              },
              roundNumber: {
                type: 'integer',
                description: 'รอบที่ทำภารกิจ',
                example: 1,
              },
            },
          },
          Reward: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Reward ID (CUID)',
                example: 'clreward12345',
              },
              name: {
                type: 'string',
                description: 'ชื่อรางวัล',
                example: 'ไอศกรีม',
              },
              cost: {
                type: 'integer',
                description: 'คะแนนที่ต้องใช้แลก',
                example: 100,
              },
            },
          },
          RewardRedemption: {
            type: 'object',
            properties: {
              id: {
                type: 'string',
                description: 'Redemption ID (CUID)',
                example: 'clredemption12345',
              },
              childId: {
                type: 'string',
                description: 'Child ID ที่แลก',
                example: 'clchild12345',
              },
              parentId: {
                type: 'string',
                description: 'Parent ID ที่อนุมัติ',
                example: 'clparent12345',
              },
              rewardId: {
                type: 'string',
                description: 'Reward ID ที่แลก',
                example: 'clreward12345',
              },
              dateRedeemed: {
                type: 'string',
                format: 'date-time',
                description: 'วันที่แลก',
                example: '2025-12-06T15:30:00.000Z',
              },
              scoreUsed: {
                type: 'integer',
                description: 'คะแนนที่ใช้',
                example: 100,
              },
            },
          },
          Pagination: {
            type: 'object',
            properties: {
              totalItems: {
                type: 'integer',
                description: 'จำนวนรายการทั้งหมด',
                example: 25,
              },
              totalPages: {
                type: 'integer',
                description: 'จำนวนหน้าทั้งหมด',
                example: 5,
              },
              currentPage: {
                type: 'integer',
                description: 'หน้าปัจจุบัน',
                example: 1,
              },
              itemsPerPage: {
                type: 'integer',
                description: 'จำนวนรายการต่อหน้า',
                example: 6,
              },
            },
          },
          Error: {
            type: 'object',
            properties: {
              error: {
                type: 'string',
                description: 'ข้อความแสดง error',
                example: 'Missing required fields',
              },
            },
          },
        },
        responses: {
          BadRequest: {
            description: 'Bad Request - ข้อมูลที่ส่งมาไม่ถูกต้อง',
            content: {
              'application/json': {
                schema: {
                  $ref: '#/components/schemas/Error',
                },
              },
            },
          },
          NotFound: {
            description: 'Not Found - ไม่พบข้อมูล',
            content: {
              'application/json': {
                schema: {
                  $ref: '#/components/schemas/Error',
                },
              },
            },
          },
          InternalServerError: {
            description: 'Internal Server Error - เกิดข้อผิดพลาดในระบบ',
            content: {
              'application/json': {
                schema: {
                  $ref: '#/components/schemas/Error',
                },
              },
            },
          },
        },
      },
    },
  });

  return spec;
};