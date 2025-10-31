// src/app/activities/create/components/PhysicalActivityForm.tsx

'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

// Interface
interface PhysicalFormData {
    name: string;
    category: string;
    content: string; 
    difficulty: string;
    maxScore: number;
    description: string;
    videoUrl: string;
}

interface VideoInfo {
    id: string | null;
    type: 'youtube' | 'tiktok' | null;
}

interface FormProps {
    initialCategory: string;
    extractVideoId: (url: string) => VideoInfo;
}


const PhysicalActivityForm = ({ initialCategory, extractVideoId }: FormProps) => {
    const [formData, setFormData] = useState<PhysicalFormData>({
        name: '',
        category: initialCategory,
        content: '',
        difficulty: 'ง่าย',
        maxScore: 20,
        description: '',
        videoUrl: '',
    });
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [videoInfo, setVideoInfo] = useState<VideoInfo>({ id: null, type: null });
    const router = useRouter();

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: name === 'maxScore' ? parseInt(value) || 0 : value
        }));
        
        if (name === 'videoUrl') {
            const info = extractVideoId(value);
            setVideoInfo(info);
        }
    };
    
    // ฟังก์ชัน Fetch Info (เรียก API Route ที่รัน Python Scraper)
    const handleFetch = async () => {
        const { id, type } = videoInfo;
        if (!type) {
            alert('Invalid video URL. Please paste a valid YouTube or TikTok link.');
            return;
        }

        try {
            // **1. เรียกใช้ API Route จริงที่รัน Python Scraper**
            const response = await fetch('/api/fetch-video-data', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                // Note: API นี้ถูกออกแบบมาสำหรับ Subtitle แต่เราใช้มันในการ Scraping Metadata ด้วย
                body: JSON.stringify({ videoUrl: formData.videoUrl }), 
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Failed to fetch video data from API.');
            }

            const data = await response.json();
            
            // **2. อัปเดต Form Data ด้วยข้อมูลที่ดึงมาจริงจาก Scraper**
            setFormData(prev => ({
                ...prev,
                name: data.title || `[${type!.toUpperCase()}] Activity Title`, 
                description: data.description || 'Auto-generated description based on video type.', 
            }));

            alert(`Video info fetched successfully from ${type!.toUpperCase()}! Please review the details.`);

        } catch (error) {
            console.error('Fetch Error:', error);
            alert(`Error fetching info: ${error instanceof Error ? error.message : 'An unknown error occurred.'}`);
        }
    };

    // ฟังก์ชัน Submit Form (เรียก POST API /api/activities)
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);

        const dataToSubmit = {
             // ส่ง segments เป็น null เสมอสำหรับกิจกรรมนี้ (ตาม requirements)
             ...formData,
             segments: null, 
        }
        
        try {
            // **3. เรียกใช้ API Route POST /api/activities เพื่อสร้างกิจกรรม**
            const response = await fetch('/api/activities', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(dataToSubmit),
            });

            if (response.ok) {
                alert('Activity created successfully!');
                router.push('/activities');
            } else {
                const errorData = await response.json();
                alert(`Failed to create activity: ${errorData.error}`);
            }
        } catch (error) {
            console.error('Submission error:', error);
            alert('An unexpected error occurred.');
        } finally {
            setIsSubmitting(false);
        }
    };

    // การแสดงผลวิดีโอแบบ Embedded (รองรับ YouTube และ TikTok)
    const renderEmbeddedVideo = () => {
        if (!videoInfo.id || !videoInfo.type) return null;
        
        // คลาส Responsive สำหรับ container หลัก
        const containerStyle = "max-w-md mx-auto border border-purple-300 rounded-lg overflow-hidden";
        
        if (videoInfo.type === 'youtube') {
            // YouTube: 16:9
            const youtubeStyle = "aspect-video w-full"; 
            return (
                <div className={`${containerStyle} ${youtubeStyle}`}>
                    <iframe
                        width="100%"
                        height="100%"
                        src={`https://www.youtube.com/embed/${videoInfo.id}`}
                        allowFullScreen
                        title="Embedded YouTube Video"
                    />
                </div>
            );
        } else if (videoInfo.type === 'tiktok') {
            // TikTok: 3:4 Vertical
            const verticalStyle = "relative w-full pb-[160%]"; 
            const embedUrl = `https://www.tiktok.com/embed/v2/${videoInfo.id}`;
            
            return (
                <div className={`${containerStyle} w-full`}>
                    <div className={verticalStyle}>
                        <iframe
                            className="absolute inset-0 w-full h-full"
                            src={embedUrl}
                            allowFullScreen
                            scrolling="no"
                            frameBorder="0"
                            title="Embedded TikTok Video"
                        />
                    </div>
                </div>
            );
        }
        
        return null;
    };


    return (
        <form onSubmit={handleSubmit} className="space-y-8">
            <h2 className="heading-h4 text-purple-600">Activity Details: {initialCategory}</h2>

            {/* ------------------- Video Information ------------------ */}
            <div className="border border-gray-300 p-6 rounded-lg bg-gray-50 space-y-4">
                <h3 className="heading-h5 mb-4 text-gray-700">Video Information (Activity Source)</h3>
                <label className="body-medium-semibold text-gray-700 block">Paste YouTube or TikTok Link</label>
                <div className="flex space-x-3">
                    <input
                        type="url"
                        name="videoUrl"
                        value={formData.videoUrl}
                        onChange={handleChange}
                        className="input w-full"
                        placeholder="e.g. https://www.youtube.com/... or https://vt.tiktok.com/..."
                        required
                    />
                    {/* *** เปิดใช้งานปุ่ม FETCH INFO *** */}
                    {/* <button
                        type="button"
                        onClick={handleFetch}
                        disabled={!videoInfo.type}
                        className="btn-primary2 rounded-md px-4 py-2 flex items-center justify-center min-w-[100px]"
                    >
                        Fetch Info
                    </button> */}
                </div>

                {/* Embedded Video Preview */}
                <div className='mt-2'>
                    {renderEmbeddedVideo()}
                </div>
            </div>

            {/* ------------------- Editable Fields (เหมือนเดิม) -------------------- */}
            <div className="space-y-4">
                <label className="body-medium-semibold text-gray-700 block">Activity Title</label>
                <input
                    type="text"
                    name="name"
                    value={formData.name}
                    onChange={handleChange}
                    required
                    className="input w-full"
                    placeholder="ชื่อกิจกรรม"
                />
                
                <label className="body-medium-semibold text-gray-700 block">Activity Descriptor</label>
                <textarea
                    name="description"
                    value={formData.description}
                    onChange={handleChange}
                    required
                    rows={4}
                    className="input w-full"
                    placeholder="คำอธิบายกิจกรรม"
                />

                <div className="grid grid-cols-3 gap-4">
                    {/* Difficulty */}
                    <div>
                        <label className="body-medium-semibold text-gray-700 block">Difficulty</label>
                        <select
                            name="difficulty"
                            value={formData.difficulty}
                            onChange={handleChange}
                            required
                            className="input w-full"
                        >
                            <option value="ง่าย">ง่าย</option>
                            <option value="กลาง">กลาง</option>
                            <option value="ยาก">ยาก</option>
                        </select>
                    </div>
                     {/* Score */}
                    <div>
                        <label className="body-medium-semibold text-gray-700 block">Score</label>
                        <input
                            type="number"
                            name="maxScore"
                            value={formData.maxScore}
                            onChange={handleChange}
                            required
                            min="1"
                            className="input w-full"
                        />
                    </div>
                    {/* Category (Auto) */}
                     <div>
                        <label className="body-medium-semibold text-gray-700 block">Category (Auto)</label>
                        <input
                            type="text"
                            value={formData.category}
                            disabled
                            className="input w-full bg-gray-200"
                        />
                    </div>
                </div>
                 {/* Content / Instruction */}
                <label className="body-medium-semibold text-gray-700 block">Content / Instruction (วิธีการเล่น)</label>
                <input
                    type="text"
                    name="content"
                    value={formData.content}
                    onChange={handleChange}
                    required
                    className="input w-full"
                />
            </div>

            {/* Submit Button */}
            <div className="flex justify-end">
                <button
                    type="submit"
                    // ปุ่ม Submit ถูกเชื่อมโยงกับ handleSubmit แล้ว
                    disabled={isSubmitting || formData.name === ''} 
                    className={`px-6 py-2 rounded-lg text-white font-semibold ${isSubmitting ? 'bg-gray-400' : 'bg-purple-600 hover:bg-purple-700'}`}
                >
                    {isSubmitting ? 'Publishing...' : 'Publish Activity'}
                </button>
            </div>
        </form>
    );
}

export default PhysicalActivityForm;