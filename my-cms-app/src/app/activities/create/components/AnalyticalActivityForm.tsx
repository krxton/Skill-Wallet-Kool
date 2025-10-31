// src/app/activities/create/components/AnalyticalActivityForm.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import cuid from 'cuid'; // Import CUID

// =======================================================
// INTERFACES
// =======================================================

// Interface สำหรับ Question Segment
interface QuestionSegment {
    id: string; // เพิ่ม ID สำหรับการอ้างอิง
    question: string;  // โจทย์ปัญหา หรือโจทย์คณิตศาสตร์
    answer: string;    // คำตอบที่ถูกต้อง
    solution: string;  // วิธีทำ/เฉลย (ถ้ามี)
    score: number;     // คะแนนสำหรับข้อนี้
}

interface AnalyticalFormData {
    name: string;
    category: string;
    content: string; 
    difficulty: string;
    maxScore: number;
    description: string;
    videoUrl: string | null; 
    questions: QuestionSegment[]; // ใช้แทน segments
}

interface FormProps {
    initialCategory: string;
}


const AnalyticalActivityForm = ({ initialCategory }: FormProps) => {
    const router = useRouter();
    
    const [formData, setFormData] = useState<AnalyticalFormData>({
        name: '',
        category: initialCategory,
        content: '',
        difficulty: 'กลาง',
        maxScore: 0, // คะแนนรวม (จะถูกคำนวณจากคะแนนย่อย)
        description: '',
        videoUrl: null,
        questions: [],
    });
    const [isSubmitting, setIsSubmitting] = useState(false);

    // ----------------------------------------------------
    // Handlers สำหรับ Fields ทั่วไป
    // ----------------------------------------------------
    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: name === 'maxScore' ? parseInt(value) || 0 : value
        }));
    };
    
    // ----------------------------------------------------
    // Handlers สำหรับ Question/Answer Editor
    // ----------------------------------------------------

    const handleQuestionChange = (index: number, field: keyof QuestionSegment, value: string | number) => {
        setFormData(prev => {
            const newQuestions = [...prev.questions];
            
            if (field === 'score') {
                const scoreValue = parseInt(value as string) || 0;
                newQuestions[index].score = scoreValue;
            } else {
                newQuestions[index][field] = value as any;
            }

            // คำนวณคะแนนรวมใหม่ทั้งหมดจาก questions ทั้งหมด
            const newMaxScore = newQuestions.reduce((total, q) => total + q.score, 0);

            return {
                ...prev,
                questions: newQuestions,
                maxScore: newMaxScore // อัปเดตคะแนนรวม
            };
        });
    };

    const handleAddQuestion = () => {
        const newQuestion: QuestionSegment = {
            id: cuid(), // สร้าง ID ที่ไม่ซ้ำกัน
            question: '',
            answer: '',
            solution: '',
            score: 10
        };
        setFormData(prev => ({
            ...prev,
            questions: [...prev.questions, newQuestion],
            maxScore: prev.maxScore + newQuestion.score // เพิ่มคะแนนรวม
        }));
    };

    const handleDeleteQuestion = (indexToDelete: number) => {
        setFormData(prev => {
            const newQuestions = prev.questions.filter((_, index) => index !== indexToDelete);
            const scoreToDeduct = prev.questions[indexToDelete].score;
            
            return {
                ...prev,
                questions: newQuestions,
                maxScore: prev.maxScore - scoreToDeduct // หักคะแนนรวม
            };
        });
    };


    // ----------------------------------------------------
    // ฟังก์ชัน Submit Form (เรียก POST API /api/activities)
    // ----------------------------------------------------
    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setIsSubmitting(true);

        const dataToSubmit = {
             ...formData,
             // segments field จะถูกใช้เก็บ array ของ questions
             segments: formData.questions.length > 0 ? formData.questions : null,
             videoUrl: null, // ไม่มี video url
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

            {/* ------------------- Editable Fields (ข้อมูลพื้นฐาน) -------------------- */}
            <div className="space-y-4">
                <label className="body-medium-semibold text-gray-700 block">Activity Title</label>
                <input type="text" name="name" value={formData.name} onChange={handleChange} required className="input w-full" placeholder="ชื่อกิจกรรม (เช่น โจทย์คณิตศาสตร์เรื่องเศษส่วน)"/>
                
                <label className="body-medium-semibold text-gray-700 block">Activity Descriptor</label>
                <textarea name="description" value={formData.description} onChange={handleChange} required rows={4} className="input w-full" placeholder="คำอธิบายสั้นๆ ของชุดโจทย์"/>

                <div className="grid grid-cols-3 gap-4">
                    {/* Difficulty */}
                    <div>
                        <label className="body-medium-semibold text-gray-700 block">Difficulty</label>
                        <select name="difficulty" value={formData.difficulty} onChange={handleChange} required className="input w-full">
                            <option value="ง่าย">ง่าย</option>
                            <option value="กลาง">กลาง</option>
                            <option value="ยาก">ยาก</option>
                        </select>
                    </div>
                     {/* Total Score (Auto) */}
                    <div>
                        <label className="body-medium-semibold text-gray-700 block">Total Score (Auto)</label>
                        <input type="number" name="maxScore" value={formData.maxScore} disabled className="input w-full bg-gray-200"/>
                    </div>
                    {/* Category (Auto) */}
                     <div>
                        <label className="body-medium-semibold text-gray-700 block">Category (Auto)</label>
                        <input type="text" value={formData.category} disabled className="input w-full bg-gray-200"/>
                    </div>
                </div>
                 {/* Content / Instruction */}
                <label className="body-medium-semibold text-gray-700 block">Content / Instruction (คำแนะนำสำหรับเด็ก)</label>
                <input type="text" name="content" value={formData.content} onChange={handleChange} required className="input w-full" placeholder="เช่น กรุณาตอบโจทย์ปัญหาทีละข้อ"/>
            </div>

            {/* ------------------- Question/Answer Editor -------------------- */}
            <div className="border border-purple-300 p-6 rounded-lg bg-purple-50 space-y-4">
                <h3 className="heading-h5 text-purple-800">Question Set Editor</h3>
                
                <div className="space-y-4 max-h-96 overflow-y-auto">
                    {formData.questions.map((q, index) => (
                        // *** ใช้ q.id เป็น key เพื่อประสิทธิภาพและหลีกเลี่ยง error ***
                        <div key={q.id} className="border border-purple-300 p-4 rounded-md bg-white shadow-md space-y-3">
                            <div className="flex justify-between items-center pb-2 border-b border-gray-100">
                                <h4 className="body-large-semibold text-gray-700">Question #{index + 1}</h4>
                                <div className='flex items-center space-x-3'>
                                     <label className="body-medium-regular">Score:</label>
                                     <input
                                        type="number"
                                        value={q.score}
                                        onChange={(e) => handleQuestionChange(index, 'score', e.target.value)}
                                        className="input w-16 text-center text-sm"
                                        min="1"
                                        required
                                     />
                                    <button
                                        type="button"
                                        onClick={() => handleDeleteQuestion(index)}
                                        className="bg-red-500 text-white px-3 py-1 text-xs rounded-md hover:bg-red-600"
                                    >
                                        Delete
                                    </button>
                                </div>
                            </div>

                            {/* โจทย์ปัญหา */}
                            <div>
                                <label className="body-medium-semibold text-gray-700 block mb-1">Question/Problem:</label>
                                <textarea
                                    value={q.question}
                                    onChange={(e) => handleQuestionChange(index, 'question', e.target.value)}
                                    className="input w-full"
                                    rows={2}
                                    required
                                    placeholder="ใส่โจทย์คณิตศาสตร์ หรือโจทย์ปัญหา"
                                />
                            </div>

                            {/* คำตอบที่ถูกต้อง */}
                            <div>
                                <label className="body-medium-semibold text-gray-700 block mb-1">Correct Answer:</label>
                                <input
                                    type="text"
                                    value={q.answer}
                                    onChange={(e) => handleQuestionChange(index, 'answer', e.target.value)}
                                    className="input w-full"
                                    required
                                    placeholder="คำตอบที่ถูกต้อง (เช่น 42 หรือ 'True')"
                                />
                            </div>
                            
                            {/* เฉลย/วิธีทำ */}
                            <div>
                                <label className="body-medium-semibold text-gray-700 block mb-1">Solution/Explanation (Optional):</label>
                                <textarea
                                    value={q.solution}
                                    onChange={(e) => handleQuestionChange(index, 'solution', e.target.value)}
                                    className="input w-full"
                                    rows={2}
                                    placeholder="ใส่คำอธิบายวิธีทำ/เฉลย"
                                />
                            </div>
                        </div>
                    ))}
                </div>

                <button
                    type="button"
                    onClick={handleAddQuestion}
                    className="btn-secondary px-4 py-2 text-sm rounded-md hover:bg-purple-700"
                >
                    + Add New Question
                </button>
            </div>


            {/* Submit Button */}
            <div className="flex justify-end">
                <button
                    type="submit"
                    disabled={isSubmitting || formData.name === '' || formData.questions.length === 0}
                    className={`px-6 py-2 rounded-lg text-white font-semibold ${isSubmitting ? 'bg-gray-400' : 'bg-purple-600 hover:bg-purple-700'}`}
                >
                    {isSubmitting ? 'Publishing...' : 'Publish Activity'}
                </button>
            </div>
        </form>
    );
}

export default AnalyticalActivityForm;