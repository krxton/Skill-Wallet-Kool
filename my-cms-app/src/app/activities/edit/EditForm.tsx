// src\app\activities\edit\EditForm.tsx

'use client'; 

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import cuid from 'cuid'; 
// *** NEW IMPORTS ***
import LanguageEditControls from './components/LanguageEditControls';
import AnalyticalEditControls from './components/AnalyticalEditControls';
// *** END NEW IMPORTS ***


// =======================================================
// 1. INTERFACES และ CONSTANTS
// =======================================================
interface Segment {
  id: string;
  start: number;
  end: number;
  text: string;
}

interface QuestionSegment {
    id: string; 
    question: string;
    answer: string;
    solution: string;
    score: number;
}

type LocalData = Segment[] | QuestionSegment[];

interface ActivityData {
    id: string;
    name: string;
    category: string;
    content: string; 
    difficulty: string;
    maxScore: number;
    description: string;
    videoUrl?: string | null;
    segments?: LocalData; 
}

interface EditFormProps {
    id: string;
}

const CATEGORIES = [
    'ด้านภาษา',
    'ด้านร่างกาย',
    'ด้านคิดวิเคราะห์',
    'อื่นๆ',
];

// Utility สำหรับ Session Storage
const getCacheKey = (id: string) => `edit-cache-${id}`;

// ฟังก์ชันดึงข้อมูลกิจกรรมเดิม
async function fetchActivity(id: string): Promise<ActivityData> {
    const response = await fetch(`/api/activities/${id}`);
    if (!response.ok) {
        throw new Error('Failed to fetch activity data. Status: ' + response.status);
    }
    const data = await response.json();
    return data;
}

// ----------------------------------------------------
// MAIN COMPONENT (Client Component)
// ----------------------------------------------------

export default function EditForm({ id }: EditFormProps) { 
    
    const router = useRouter();
    
    // State หลัก
    const [formData, setFormData] = useState<ActivityData | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [youtubeId, setYoutubeId] = useState<string | null>(null);
    const [localData, setLocalData] = useState<LocalData>([]); 
    const [localScore, setLocalScore] = useState(0); 
    
    // State ใหม่: เก็บสถานะเริ่มต้นที่ดึงมาจาก API (สำหรับ Reset)
    const [initialFormData, setInitialFormData] = useState<ActivityData | null>(null);
    
    // History Stack
    const [history, setHistory] = useState<LocalData[]>([]);
    const [historyIndex, setHistoryIndex] = useState(-1);
    
    // ** ฟังก์ชันสำหรับบันทึกสถานะปัจจุบัน (Snapshot) **
    const saveSnapshot = (data: LocalData, currentScore: number) => {
        setLocalScore(currentScore);
        setHistory(prevHistory => {
            if (prevHistory.length > 0 && JSON.stringify(prevHistory[historyIndex]) === JSON.stringify(data)) {
                return prevHistory; 
            }
            
            const newHistory = prevHistory.slice(0, historyIndex + 1);
            newHistory.push(data);
            
            // บันทึกสถานะปัจจุบันลงใน Session Storage เพื่อ Persistent State
            try {
                sessionStorage.setItem(getCacheKey(id), JSON.stringify({ formData: formData, localData: newHistory[newHistory.length - 1], localScore: currentScore }));
            } catch (e) {
                console.error("Failed to save to session storage:", e);
            }

            if (newHistory.length > 50) { 
                newHistory.shift(); 
                setHistoryIndex(prev => prev - 1); 
                return newHistory;
            }

            setHistoryIndex(newHistory.length - 1);
            return newHistory;
        });
    };

    // ----------------------------------------------------
    // useEffect: โหลดข้อมูล (ใช้ Cache หรือ Fetch)
    // ----------------------------------------------------
    const loadActivity = useCallback(async () => {
        if (!id) {
            setIsLoading(false);
            return;
        }

        const cacheKey = getCacheKey(id);
        const cachedItem = sessionStorage.getItem(cacheKey);

        let data: ActivityData | null = null;
        let initialData: ActivityData | null = null;
        let initialLocalData: LocalData | null = null;
        let initialScore: number = 0;


        // 1. ลองโหลดจาก Cache (State ที่แก้ไขล่าสุด)
        if (cachedItem) {
             try {
                const cache = JSON.parse(cachedItem);
                
                // ใช้ข้อมูลจาก Cache สำหรับ State ปัจจุบัน
                data = cache.formData; 
                initialLocalData = cache.localData;
                initialScore = cache.localScore;
                
                // Fetch ข้อมูลเริ่มต้น (InitialData) จาก API เสมอเพื่อใช้ในการ Reset 
                // แต่ไม่รอให้มันเสร็จ เพื่อให้หน้าโหลดเร็วขึ้น (Progressive Loading)
                fetchActivity(id).then(apiData => {
                    setInitialFormData(apiData);
                }).catch(e => console.error("Failed to fetch initial data for reset:", e));

                console.log("✅ Loaded from Session Cache.");

             } catch (e) {
                 sessionStorage.removeItem(cacheKey);
             }
        }

        // 2. ถ้าไม่มี Cache หรือโหลดไม่สำเร็จ ให้ Fetch ใหม่ทั้งหมด
        if (!data) {
            try {
                data = await fetchActivity(id);
                initialData = data;
                initialLocalData = (data.segments || []) as LocalData;
                initialScore = data.maxScore;
                
                setInitialFormData(data);
                
                // บันทึกสถานะเริ่มต้นลงใน Cache เพื่อให้การรีเฟรชครั้งต่อไปใช้ Cache
                sessionStorage.setItem(cacheKey, JSON.stringify({ formData: data, localData: initialLocalData, localScore: initialScore }));

            } catch (error) {
                console.error("❌ Failed to fetch data from API:", error);
                setIsLoading(false);
                return;
            }
        }
        
        // 3. ตั้งค่า State จากข้อมูลที่ได้ (Cache หรือ API)
        if (data && initialLocalData !== null) {
            setFormData(data);

            setLocalData(initialLocalData);
            setLocalScore(initialScore);

            // บันทึก History Stack ด้วยสถานะปัจจุบันที่โหลดมา
            setHistory([initialLocalData]);
            setHistoryIndex(0);
            
            // ตั้งค่า youtubeId สำหรับ Embedded Video
            if (data.videoUrl) {
                const youtubeRegex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
                const tiktokRegex = /(?:tiktok\.com\/.*\/video\/|tiktok\.com\/v\/|vt\.tiktok\.com\/.*\/)(\d+)/i;
                
                const youtubeMatch = data.videoUrl.match(youtubeRegex);
                const tiktokMatch = data.videoUrl.match(tiktokRegex);
                
                if (youtubeMatch) {
                        setYoutubeId(youtubeMatch[1]);
                } else if (tiktokMatch) {
                    setYoutubeId(tiktokMatch[1]);
                }
            }
        }
        setIsLoading(false);
    }, [id]); 

    useEffect(() => {
        loadActivity();
    }, [loadActivity]); 
    

    // ----------------------------------------------------
    // Handlers (สำหรับ Form หลัก)
    // ----------------------------------------------------
    // *** แก้ไข: บันทึก Snapshot ของ formData เมื่อมีการเปลี่ยนแปลง Text Field ***
    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        if (!formData) return;
        
        // อัปเดต formData
        const newFormData = {
            ...formData,
            [name]: name === 'maxScore' ? parseInt(value) || 0 : value
        };
        
        setFormData(newFormData);
        
        // *** อัปเดต localScore ด้วยถ้าเป็นการแก้ maxScore โดยตรง (สำหรับกิจกรรมที่ไม่ใช่ Analytical) ***
        if (name === 'maxScore') {
            setLocalScore(parseInt(value) || 0);
        }

        // *** 1. บันทึก New FormData ลงใน Session Storage ทันที ***
        try {
            const cacheKey = getCacheKey(id);
            const cache = { 
                formData: newFormData, 
                localData: localData, // ข้อมูล Questions/Segments ปัจจุบัน
                localScore: name === 'maxScore' ? (parseInt(value) || 0) : localScore
            };
            sessionStorage.setItem(cacheKey, JSON.stringify(cache));
        } catch (e) {
            console.error("Failed to update formData in session storage:", e);
        }
    };
    
    // *** ฟังก์ชัน Undo/Redo (เรียกใช้ Logic ใน History Stack) ***
    const handleUndo = () => {
        if (historyIndex > 0) {
            const newIndex = historyIndex - 1;
            setHistoryIndex(newIndex);
            const historicalData = history[newIndex];
            setLocalData(historicalData);
            
            const totalScore = (historicalData as Segment[]).reduce((sum, item: any) => sum + (item.score || 0), 0);
            setLocalScore(totalScore);
        }
    };

    const handleRedo = () => {
        if (historyIndex < history.length - 1) {
            const newIndex = historyIndex + 1;
            setHistoryIndex(newIndex);
            const historicalData = history[newIndex];
            setLocalData(historicalData);
            
            const totalScore = (historicalData as Segment[]).reduce((sum, item: any) => sum + (item.score || 0), 0);
            setLocalScore(totalScore);
        }
    };

    const handleReset = () => {
        if (!initialFormData) return;
        
        if (!confirm('Are you sure you want to reset all changes to the original state? This cannot be undone by Undo/Redo.')) {
            return;
        }

        const initialSegments = (initialFormData.segments || []) as LocalData;
        const initialScore = initialFormData.maxScore;

        // 1. รีเซ็ตฟอร์มหลัก
        setFormData(initialFormData); 
        
        // 2. รีเซ็ต Local Data
        setLocalData(initialSegments); 
        setLocalScore(initialScore);
        
        // 3. รีเซ็ต History Stack (เริ่มต้นใหม่ด้วยสถานะเริ่มต้น)
        setHistory([initialSegments]);
        setHistoryIndex(0);
        
        // 4. ล้าง Session Cache เพื่อให้การโหลดครั้งต่อไปใช้ข้อมูล API (ถ้าไม่ Save)
        sessionStorage.removeItem(getCacheKey(id));
        
        alert('All changes have been reset to the initial state.');
    };


    // ฟังก์ชันสำหรับบันทึกการแก้ไข (PUT method)
    const handleUpdate = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!formData) return;

        setIsSubmitting(true);
        
        // *** แก้ไข: ใช้ localScore แทน formData.maxScore สำหรับกิจกรรม Analytical ***
        const isAnalytical = formData.category === 'ด้านคิดวิเคราะห์';
        
        const payload = {
            ...formData,
            maxScore: isAnalytical ? localScore : formData.maxScore, // ✅ ใช้ localScore ถ้าเป็น Analytical
            segments: localData,
        };
        
        // *** DEBUG: ดูว่าส่งค่าอะไรไป ***
        console.log('🔍 DEBUG - Payload to send:', {
            category: formData.category,
            isAnalytical,
            localScore,
            'formData.maxScore': formData.maxScore,
            'payload.maxScore': payload.maxScore,
            'segments count': localData.length,
        });

        try {
            const response = await fetch(`/api/activities/${id}`, {
                method: 'PUT',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(payload), 
            });

            if (response.ok) {
                alert('Activity updated successfully! ✅');
                // *** ล้าง Cache เพื่อให้การโหลดครั้งต่อไปใช้ข้อมูลล่าสุดจาก DB ***
                sessionStorage.removeItem(getCacheKey(id)); 
                router.push('/activities');
            } else {
                const errorData = await response.json();
                alert(`Failed to update activity: ${errorData.error}`);
            }
        } catch (error) {
            alert('An unexpected error occurred during update.');
        } finally {
            setIsSubmitting(false);
        }
    };
    
    // ฟังก์ชันสำหรับลบกิจกรรม (DELETE method)
    const handleDelete = async () => {
        if (!confirm('Are you sure you want to delete this activity? This action cannot be undone.')) {
            return;
        }

        try {
            const response = await fetch(`/api/activities/${id}`, {
                method: 'DELETE',
            });

            if (response.status === 204) { // 204 No Content
                alert('Activity deleted successfully! 🗑️');
                // *** ล้าง Cache ของกิจกรรมที่ถูกลบ ***
                sessionStorage.removeItem(getCacheKey(id));
                router.push('/activities');
            } else {
                alert('Failed to delete activity.');
            }
        } catch (error) {
            alert('An unexpected error occurred during deletion.');
        }
    };

    // RENDER UTILITY: แสดงผลวิดีโอ (รองรับ TikTok และ YouTube)
    const renderEmbeddedVideo = () => {
        if (!youtubeId || !formData) return null;

        const isTikTok = formData.videoUrl?.includes('tiktok.com');
        const containerStyle = "max-w-md mx-auto border border-purple-300 rounded-lg overflow-hidden";
        
        if (isTikTok) {
            // TikTok: 3:4 Vertical
            const verticalStyle = "relative w-full pb-[133.33%]"; 
            const embedUrl = `https://www.tiktok.com/embed/v2/${youtubeId}`; 
            
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
        } else {
            // YouTube: 16:9
            const youtubeStyle = "aspect-video w-full"; 
            return (
                <div className={`${containerStyle} ${youtubeStyle}`}>
                    <iframe
                        width="100%"
                        height="100%"
                        src={`https://www.youtube.com/embed/${youtubeId}`}
                        allowFullScreen
                        title="Embedded YouTube Video"
                    />
                </div>
            );
        }
    };


    // ----------------------------------------------------
    // Rendering
    // ----------------------------------------------------
    if (isLoading) {
        return <div className="p-8 text-center text-xl text-purple-600">Loading Activity Details... ⏳</div>;
    }

    if (!formData) {
        return <div className="p-8 text-center text-red-600 text-xl">Activity not found or failed to load.</div>;
    }
    
    // ตรวจสอบประเภทกิจกรรมสำหรับการแสดงผลแบบมีเงื่อนไข
    const isLanguageActivity = formData.category === 'ด้านภาษา';
    const isAnalyticalActivity = formData.category === 'ด้านคิดวิเคราะห์';
    const isVideoActivity = isLanguageActivity || formData.category === 'ด้านร่างกาย';
    
    return (
        <div className="p-8 max-w-5xl mx-auto">
            <form onSubmit={handleUpdate} className="space-y-8">
                
                {/* --- HEADER/CONTROL BAR --- */}
                <div className="flex justify-between items-center">
                    <h1 className="heading-h2 text-gray-800">Edit Activity</h1>
                    
                    {/* *** ปุ่ม SET DEFAULT และ SAVE/DELETE Buttons *** */}
                    <div className="flex space-x-4">
                        {/* ปุ่ม SET DEFAULT/RESET */}
                        <button
                            type="button"
                            onClick={handleReset}
                            disabled={isSubmitting || isLoading}
                            className={`px-4 py-2 rounded-lg text-sm font-semibold transition-colors border border-gray-400 ${
                                isSubmitting || isLoading ? 'bg-gray-200 text-gray-500 cursor-not-allowed' : 'bg-white text-gray-700 hover:bg-gray-100'
                            }`}
                        >
                            Set Default
                        </button>
                    </div>
                </div>
                
                {/* ------------------- Video Information / Preview ------------------ */}
                {isVideoActivity && (
                     <div className="border border-gray-300 p-6 rounded-lg bg-gray-50 space-y-4">
                        <h3 className="heading-h5 mb-4 text-gray-700">Video Information</h3>
                        
                        <label className="body-medium-semibold text-gray-700 block">YouTube/TikTok URL</label>
                         <input type="url" name="videoUrl" value={formData.videoUrl || ''} onChange={handleChange} className="input w-full bg-gray-200" disabled/>
                        
                        {/* Embedded Video Preview */}
                        <div className='mt-4'>
                            {renderEmbeddedVideo()}
                        </div>
                    </div>
                )}


                {/* ------------------- Editable Fields -------------------- */}
                <div className="space-y-4">
                     <label className="body-medium-semibold text-gray-700 block">Activity Title</label>
                    <input type="text" name="name" value={formData.name || ''} onChange={handleChange} required className="input w-full"/>
                    
                    <label className="body-medium-semibold text-gray-700 block">Activity Descriptor</label>
                    <textarea name="description" value={formData.description || ''} onChange={handleChange} required rows={4} className="input w-full"/>

                    <div className="grid grid-cols-3 gap-4">
                        <div>
                            <label className="body-medium-semibold text-gray-700 block">Category</label>
                            <select name="category" value={formData.category || ''} onChange={handleChange} required className="input w-full">
                                {CATEGORIES.map(cat => <option key={cat} value={cat}>{cat}</option>)}
                            </select>
                        </div>
                        <div>
                            <label className="body-medium-semibold text-gray-700 block">Difficulty</label>
                            <select name="difficulty" value={formData.difficulty || ''} onChange={handleChange} required className="input w-full">
                                <option value="ง่าย">ง่าย</option>
                                <option value="กลาง">กลาง</option>
                                <option value="ยาก">ยาก</option>
                            </select>
                        </div>
                        <div>
                            <label className="body-medium-semibold text-gray-700 block">Score</label>
                            {/* Score ถูก disabled ถ้าเป็น Analytical เพราะคำนวณอัตโนมัติ */}
                            <input type="number" name="maxScore" value={isAnalyticalActivity ? localScore : formData.maxScore} onChange={handleChange} required min="1" className={`input w-full ${isAnalyticalActivity ? 'bg-gray-200' : ''}`} disabled={isAnalyticalActivity}/>
                        </div>
                    </div>
                    <label className="body-medium-semibold text-gray-700 block">Content / Instruction</label>
                    <input type="text" name="content" value={formData.content || ''} onChange={handleChange} required className="input w-full"/>
                </div>

                {/* ------------------- DYNAMIC CONTROLS (Language) -------------------- */}
                {isLanguageActivity && (
                    <LanguageEditControls 
                        localSegments={localData as Segment[]}
                        setLocalSegments={setLocalData as React.Dispatch<React.SetStateAction<Segment[]>>}
                        history={history as Segment[][]}
                        historyIndex={historyIndex}
                        setHistoryIndex={setHistoryIndex}
                        saveSnapshot={saveSnapshot as any} // Cast Type
                        maxScore={formData.maxScore}
                    />
                )}
                
                {/* ------------------- DYNAMIC CONTROLS (Analytical) -------------------- */}
                {isAnalyticalActivity && (
                    <AnalyticalEditControls 
                        localQuestions={localData as QuestionSegment[]}
                        setLocalQuestions={setLocalData as React.Dispatch<React.SetStateAction<QuestionSegment[]>>}
                        setTotalScore={setLocalScore}
                        history={history as QuestionSegment[][]}
                        historyIndex={historyIndex}
                        setHistoryIndex={setHistoryIndex}
                        saveSnapshot={saveSnapshot as any} // Cast Type
                    />
                )}
                
                {/* ปุ่ม DELETE/SAVE Buttons */}
                <div className='flex space-x-4 justify-end'>
                    <button
                        type="button"
                        onClick={handleDelete}
                        className="px-4 py-2 rounded-lg text-white font-semibold bg-red-600 hover:bg-red-700 transition-colors"
                    >
                        Delete Activity
                    </button>
                    <button
                        type="submit"
                        disabled={isSubmitting || formData.name === ''}
                        className={`px-6 py-2 rounded-lg text-white font-semibold ${isSubmitting ? 'bg-gray-400' : 'bg-purple-600 hover:bg-purple-700'}`}
                    >
                        {isSubmitting ? 'Saving Changes...' : 'Save Changes'}
                    </button>
                </div>
            </form>
        </div>
    );
}