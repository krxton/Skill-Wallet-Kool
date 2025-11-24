// src/app/activities/create/page.tsx
'use client'; 

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import LanguageActivityForm from './components/LanguageActivityForm';
import PhysicalActivityForm from './components/PhysicalActivityForm';
import AnalyticalActivityForm from './components/AnalyticalActivityForm';

// Constants
const ACTIVITY_TYPES = [
    { value: 'ด้านภาษา', label: '1. ด้านภาษา' },
    { value: 'ด้านร่างกาย', label: '2. ด้านร่างกาย' },
    { value: 'ด้านคิดวิเคราะห์', label: '3. ด้านคิดวิเคราะห์' },
];

// Utility: ดึง Video ID จาก URL (รองรับ YouTube และ TikTok)
export const extractVideoId = (url: string) => {
    let id: string | null = null;
    let type: 'youtube' | 'tiktok' | null = null;

    // 1. YouTube ID extraction
    const youtubeRegex =
        /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const youtubeMatch = url.match(youtubeRegex);

    if (youtubeMatch) {
        id = youtubeMatch[1];
        type = 'youtube';
        return { id, type };
    }

    // 2. TikTok extraction
    const tiktokRegex =
        /(?:tiktok\.com\/(?:@[\w.]+\/video\/|v\/|t\/)|vt\.tiktok\.com\/.*\/)(\d+)/i;
    const tiktokMatch = url.match(tiktokRegex);

    if (tiktokMatch) {
        id = tiktokMatch[1];
        type = 'tiktok';
        return { id, type };
    }

    return { id: null, type: null };
};

export default function CreateActivityPage() {
    const [selectedType, setSelectedType] = useState<string | null>(null);

    const renderForm = () => {
        if (!selectedType) return null;

        switch (selectedType) {
            case 'ด้านภาษา':
                return (
                    <LanguageActivityForm
                        initialCategory={selectedType}
                        extractVideoId={extractVideoId}
                    />
                );
            case 'ด้านร่างกาย':
                return (
                    <PhysicalActivityForm
                        initialCategory={selectedType}
                        extractVideoId={extractVideoId}
                    />
                );
            case 'ด้านคิดวิเคราะห์':
                return (
                    <AnalyticalActivityForm initialCategory={selectedType} />
                );
            default:
                return null;
        }
    };

    return (
        <div className="p-8 max-w-5xl mx-auto">
            <h1 className="heading-h2 mb-8 text-gray-800">Create New Activity</h1>

            {/* Step 1: เลือกประเภทกิจกรรม */}
            {!selectedType && (
                <div className="space-y-6">
                    <h2 className="heading-h4 text-gray-700">
                        Step 1: Select Activity Type
                    </h2>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                        {ACTIVITY_TYPES.map((type) => (
                            <button
                                key={type.value}
                                onClick={() => setSelectedType(type.value)}
                                className="p-8 border border-gray-300 rounded-lg shadow-md hover:shadow-lg transition-all duration-200 
                                           text-left bg-white hover:bg-purple-50 focus:outline-none focus:ring-4 focus:ring-purple-300"
                            >
                                <p className="heading-h5 text-purple-600">
                                    {type.label}
                                </p>
                                <p className="body-medium-regular text-gray-500 mt-2">
                                    {type.value === 'ด้านภาษา' &&
                                        'วิดีโอ YouTube, Subtitle, การฝึกอ่านออกเสียง'}
                                    {type.value === 'ด้านร่างกาย' &&
                                        'ภาพถ่าย, วิดีโอสั้น, การฝึกทักษะการเคลื่อนไหว'}
                                    {type.value === 'ด้านคิดวิเคราะห์' &&
                                        'ปริศนา, โจทย์คณิตศาสตร์, เกมตรรกะ'}
                                </p>
                            </button>
                        ))}
                    </div>
                </div>
            )}

            {/* Step 2: แสดงฟอร์มที่เกี่ยวข้อง */}
            {selectedType && (
                <div className="space-y-6">
                    <button
                        onClick={() => setSelectedType(null)}
                        className="btn-white px-4 py-2 text-sm rounded-md mb-4"
                    >
                        &larr; Change Type
                    </button>
                    {renderForm()}
                </div>
            )}
        </div>
    );
}
