// src/app/activities/create/components/LanguageActivityForm.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import cuid from 'cuid';

// =======================================================
// INTERFACES
// =======================================================
interface Segment {
  id: string;
  start: number;
  end: number;
  text: string;
}

interface LanguageFormData {
    name: string;
    category: string;
    content: string; 
    difficulty: string;
    maxScore: number;
    description: string;
    videoUrl: string;
    segments: Segment[];
}

interface VideoInfo {
    id: string | null;
    type: 'youtube' | 'tiktok' | null;
}

interface FormProps {
    initialCategory: string;
    extractVideoId: (url: string) => VideoInfo;
}


const LanguageActivityForm = ({ initialCategory, extractVideoId }: FormProps) => {
    const [formData, setFormData] = useState<LanguageFormData>({
        name: '',
        category: initialCategory,
        content: '',
        difficulty: 'ง่าย',
        maxScore: 20,
        description: '',
        videoUrl: '',
        segments: [],
    });
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [isFetching, setIsFetching] = useState(false);
    const [youtubeId, setYoutubeId] = useState<string | null>(null); // ใช้เก็บ ID สำหรับ Embedded Video
    const router = useRouter();


    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: name === 'maxScore' ? parseInt(value) || 0 : value
        }));
        
        if (name === 'videoUrl') {
            const { id, type } = extractVideoId(value);
            // แสดงเฉพาะ YouTube ID ใน Embedded Player (ถ้าเป็น TikTok จะไม่แสดง/หรือต้องใช้โค้ด TikTok)
            setYoutubeId(type === 'youtube' ? id : null); 
        }
    };

    // ฟังก์ชันดึงข้อมูลจริงจาก API Route /api/fetch-video-data (รัน Python Script)
    const handleFetch = async () => {
        const { id, type } = extractVideoId(formData.videoUrl);
        if (!id || type !== 'youtube') {
            alert('Invalid YouTube URL. Only YouTube is supported for subtitle fetching.');
            return;
        }

        setIsFetching(true);
        
        try {
            const response = await fetch('/api/fetch-video-data', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ videoUrl: formData.videoUrl }),
            });

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.error || 'Failed to fetch video data from API.');
            }

            const data = await response.json();

            const segmentsWithIds: Segment[] = data.segments.map((segment: Omit<Segment, 'id'>) => ({
                ...segment,
                id: cuid(), // สร้าง ID ที่ไม่ซ้ำกัน
            }));
            // *** -------------------------------------------- ***
            
            // 2. อัปเดต Form Data ด้วยข้อมูลที่ดึงมาจริง
            setFormData(prev => ({
                ...prev,
                name: data.title, 
                description: data.description, 
                segments: segmentsWithIds,
                content: `Video Source: YouTube ID ${data.videoId}`,
            }));

            alert('Video data and segments fetched successfully! Please review the segments below.');

        } catch (error) {
            console.error('Fetch Error:', error);
            alert(`Error: ${error instanceof Error ? error.message : 'An unknown error occurred during fetching.'}`);
        } finally {
            setIsFetching(false);
        }
    };

    // ฟังก์ชัน Submit Form (เรียก POST API /api/activities)
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);

        const dataToSubmit = {
             ...formData,
        }
        
        try {
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

    return (
        <form onSubmit={handleSubmit} className="space-y-8">
            <h2 className="heading-h4 text-purple-600">Activity Details: {initialCategory}</h2>

            {/* ------------------- Video Information ------------------ */}
            <div className="border border-gray-300 p-6 rounded-lg bg-gray-50 space-y-4">
                <h3 className="heading-h5 mb-4 text-gray-700">Video Information (Activity Source)</h3>
                <label className="body-medium-semibold text-gray-700 block">Paste YouTube Link</label>
                <div className="flex space-x-3">
                    <input
                        type="url"
                        name="videoUrl"
                        value={formData.videoUrl}
                        onChange={handleChange}
                        className="input w-full"
                        placeholder="e.g. https://www.youtube.com/watch?v=..."
                        required
                    />
                    <button
                        type="button"
                        onClick={handleFetch}
                        disabled={isFetching || !youtubeId}
                        className="btn-primary2 rounded-md px-4 py-2 flex items-center justify-center min-w-[100px]"
                    >
                        {isFetching ? 'Fetching...' : 'Fetch'}
                    </button>
                </div>

                {/* Embedded Video Preview */}
                {youtubeId && (
                    <div className="mt-4">
                        <h4 className="body-medium-semibold mb-2">Video Preview</h4>
                        <div className="aspect-video w-full max-w-lg mx-auto border border-purple-300 rounded-lg overflow-hidden">
                            <iframe
                                width="100%"
                                height="100%"
                                src={`https://www.youtube.com/embed/${youtubeId}`}
                                allowFullScreen
                                title="Embedded YouTube Video"
                            />
                        </div>
                    </div>
                )}
            </div>

            {/* ------------------- Editable Fields -------------------- */}
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
            
            {/* ------------------- Segment Preview (Read-Only) -------------------- */}
            {formData.segments.length > 0 && (
                <div className="border border-purple-300 p-6 rounded-lg bg-purple-50 space-y-4">
                    <h3 className="heading-h5 text-purple-800">Fetched Subtitle Segments ({formData.segments.length})</h3>
                    <div className="space-y-2 max-h-40 overflow-y-auto">
                        {formData.segments.map((segment, index) => (
                            <p key={segment.id} className="body-small-regular text-gray-800 truncate">
                                <strong>[{segment.start}s - {segment.end}s]</strong> {segment.text}
                            </p>
                        ))}
                    </div>
                </div>
            )}


            {/* Submit Button */}
            <div className="flex justify-end">
                <button
                    type="submit"
                    disabled={isSubmitting || formData.name === ''}
                    className={`px-6 py-2 rounded-lg text-white font-semibold ${isSubmitting ? 'bg-gray-400' : 'bg-purple-600 hover:bg-purple-700'}`}
                >
                    {isSubmitting ? 'Publishing...' : 'Publish Activity'}
                </button>
            </div>
        </form>
    );
}

export default LanguageActivityForm;