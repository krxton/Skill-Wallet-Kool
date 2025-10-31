// src\app\activities\edit\page.tsx (New Client Component)

'use client';

import EditForm from './EditForm'; 
import { useSearchParams } from 'next/navigation';

export default function EditActivityPageWrapper() {
    
    const searchParams = useSearchParams();
    const activityId = searchParams.get('id'); 
    
    // ตรวจสอบความถูกต้องของ ID ที่ได้จาก Query
    if (!activityId) {
        return (
            <div className="p-8 text-center text-red-600 text-xl">
                404: Activity ID is missing from the URL query.
            </div>
        );
    }

    // ส่ง id ที่ดึงมาอย่างปลอดภัย ลงไปยัง Client Component
    return (
        <EditForm id={activityId} />
    );
}