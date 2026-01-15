// import { NextResponse } from 'next/server';
// import { prisma } from '@/lib/prisma';

// export async function GET() {
//   try {
//     const stats = {
//       parents: await prisma.parent.count(),
//       activities: await prisma.activity.count(),
//       children: await prisma.child.count(),
//       medals: await prisma.medals.count(),
//     };

//     return NextResponse.json({ 
//     //   success: true,
//       stats,
//       message: 'Connected to Supabase!' 
//     });
//   } catch (error: any) {
//     return NextResponse.json({ 
//       success: false,
//       error: error.message 
//     }, { status: 500 });
//   }
// }