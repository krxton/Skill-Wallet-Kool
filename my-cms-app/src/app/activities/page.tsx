// src/app/activities/page.tsx
import { Suspense } from 'react';
import Link from 'next/link';

// กำหนด Type ของ Activity (เพื่อให้ TypeScript รู้จักโครงสร้างข้อมูล)
interface Activity {
  id: string;
  name: string;
  category: string;
  content: string;
  difficulty: string;
  maxScore: number;
  description: string | null;
  // เพิ่ม field อื่น ๆ ที่จำเป็น เช่น createdAt, status (สมมติว่าเพิ่มในอนาคต)
}

// ฟังก์ชันสำหรับดึงข้อมูลกิจกรรมจาก API Route ของเรา
async function getActivities(): Promise<Activity[]> {
  // ดึงข้อมูลจาก API Route ภายในเครื่อง
  const response = await fetch('http://localhost:3000/api/activities', { 
    // ใช้ 'no-cache' เพื่อให้ดึงข้อมูลใหม่ทุกครั้งที่เข้าหน้า (เหมาะสำหรับ CMS Admin)
    cache: 'no-store' 
  }); 

  if (!response.ok) {
    // throw new Error('Failed to fetch activities');
    // ในกรณีที่ล้มเหลว ให้คืนค่า Array ว่างไปก่อน
    return []; 
  }
  return response.json();
}

// Component หลักของหน้า Activity List
export default async function ActivityListPage() {
  const activities = await getActivities();

  return (
    <div className="p-8">
      <h1 className="text-3xl font-bold mb-6">Activity List</h1>

      {/* ปุ่ม Create - อ้างอิงจากดีไซน์ */}
      <div className="flex justify-end mb-4">
        <Link href="/activities/create" className="bg-purple-600 text-white px-4 py-2 rounded-lg hover:bg-purple-700">
          + Create
        </Link>
      </div>

      {/* ตารางแสดงรายการกิจกรรม */}
      <div className="overflow-x-auto shadow-md rounded-lg">
        <table className="min-w-full divide-y divide-gray-200">
          <thead className="bg-gray-50">
            <tr>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">No.</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Activity Title</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Category</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Score</th>
              <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Difficulty</th>
              <th className="px-6 py-3"></th>
            </tr>
          </thead>
          <tbody className="bg-white divide-y divide-gray-200">
            {activities.length === 0 ? (
              <tr>
                <td colSpan={6} className="px-6 py-4 text-center text-gray-500">
                  No activities found. Click '+ Create' to add one.
                </td>
              </tr>
            ) : (
              activities.map((activity, index) => (
                <tr key={activity.id}>
                  <td className="px-6 py-4 whitespace-nowrap">{index + 1}</td>
                  <td className="px-6 py-4 whitespace-nowrap font-medium text-gray-900">{activity.name}</td>
                  <td className="px-6 py-4 whitespace-nowrap">{activity.category}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-center">{activity.maxScore}</td>
                  <td className="px-6 py-4 whitespace-nowrap">{activity.difficulty}</td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    {/* *** แก้ไข Link: ชี้ไปที่ /activities/edit?id=... *** */}
                    <Link href={`/activities/edit?id=${activity.id}`} className="text-indigo-600 hover:text-indigo-900 mr-4">
                      Edit
                    </Link>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}