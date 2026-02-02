// src\app\activities\edit\page.tsx (New Client Component)

'use client';

import { Suspense } from 'react';
import EditForm from './EditForm';
import { useSearchParams } from 'next/navigation';

// 🔧 Separate component for useSearchParams to enable Suspense
function EditFormWithParams() {
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
    return <EditForm id={activityId} />;
}

// 🚀 Main page component with Suspense boundary
export default function EditActivityPageWrapper() {
    return (
        <Suspense fallback={
            <div className="p-8 text-center text-gray-600 text-xl">
                Loading activity...
            </div>
        }>
            <EditFormWithParams />
        </Suspense>
    );
}