// src\app\activities\edit\components\AnalyticalEditControls.tsx
'use client';

import React, { useCallback, useRef } from 'react';
import cuid from 'cuid'; // สำหรับการเพิ่มคำถามใหม่

// =======================================================
// INTERFACES (ต้องตรงกับ EditForm.tsx)
// =======================================================
interface QuestionSegment {
    id: string; 
    question: string;
    answer: string;
    solution: string;
    score: number;
}

interface AnalyticalControlsProps {
    localQuestions: QuestionSegment[];
    setLocalQuestions: React.Dispatch<React.SetStateAction<QuestionSegment[]>>;
    setTotalScore: (score: number) => void;
    history: QuestionSegment[][];
    historyIndex: number;
    setHistoryIndex: React.Dispatch<React.SetStateAction<number>>;
    saveSnapshot: (data: QuestionSegment[], currentScore: number) => void;
}

export default function AnalyticalEditControls({
    localQuestions,
    setLocalQuestions,
    setTotalScore,
    history,
    historyIndex,
    setHistoryIndex,
    saveSnapshot,
}: AnalyticalControlsProps) {
    
    // Debounce timer สำหรับ text changes
    const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);
    
    // ----------------------------------------------------
    // Handlers
    // ----------------------------------------------------

    // Handler สำหรับการแก้ไข Question แต่ละตัว (Update)
    const handleQuestionChange = (index: number, field: keyof QuestionSegment, value: string | number) => {
        setLocalQuestions(prevQuestions => {
            const newQuestions = prevQuestions.map((q, i) => {
                if (i !== index) return q;
                
                let updatedQ = { ...q };
                
                if (field === 'score') {
                    const scoreValue = parseInt(value as string) || 0;
                    updatedQ.score = scoreValue;
                } else {
                    updatedQ[field] = value as any;
                }
                return updatedQ;
            });
            
            // คำนวณคะแนนรวมใหม่ทุกครั้ง
            const newScoreTotal = newQuestions.reduce((sum, item) => sum + item.score, 0);
            setTotalScore(newScoreTotal);
            
            // *** การแก้ไข: Debounce สำหรับ text fields, Immediate save สำหรับ score ***
            if (field === 'score') {
                // บันทึก snapshot ทันทีเมื่อเปลี่ยนคะแนน
                saveSnapshot(newQuestions, newScoreTotal);
            } else {
                // Debounce สำหรับ text fields (รอ 500ms หลังจากหยุดพิมพ์)
                if (debounceTimerRef.current) {
                    clearTimeout(debounceTimerRef.current);
                }
                debounceTimerRef.current = setTimeout(() => {
                    saveSnapshot(newQuestions, newScoreTotal);
                }, 500);
            }
            
            return newQuestions;
        });
    };

    // Handler สำหรับการเพิ่ม Question - เรียก saveSnapshot
    const handleAddQuestion = () => {
        const newQuestion: QuestionSegment = {
            id: cuid(), // สร้าง ID ใหม่
            question: '',
            answer: '',
            solution: '',
            score: 10
        };
        
        setLocalQuestions(prev => {
            const newQuestions = [...prev, newQuestion];
            const newTotalScore = newQuestions.reduce((sum, q) => sum + q.score, 0);
            
            setTotalScore(newTotalScore);
            saveSnapshot(newQuestions, newTotalScore);
            return newQuestions;
        });
    };

    // Handler สำหรับการลบ Question - เรียก saveSnapshot
    const handleDeleteQuestion = (indexToDelete: number) => {
        if (!confirm(`Are you sure you want to delete Question #${indexToDelete + 1}?`)) return;
        
        setLocalQuestions(prev => {
            const newQuestions = prev.filter((_, index) => index !== indexToDelete);
            const newTotalScore = newQuestions.reduce((sum, q) => sum + q.score, 0);

            setTotalScore(newTotalScore);
            saveSnapshot(newQuestions, newTotalScore);
            return newQuestions;
        });
    };
    
    // ฟังก์ชัน Undo/Redo
    const handleUndo = () => {
        if (historyIndex > 0) {
            const newIndex = historyIndex - 1;
            setHistoryIndex(newIndex);
            const historicalData = history[newIndex];
            setLocalQuestions(historicalData);
            
            const totalScore = historicalData.reduce((sum, q) => sum + q.score, 0);
            setTotalScore(totalScore);
        }
    };

    const handleRedo = () => {
        if (historyIndex < history.length - 1) {
            const newIndex = historyIndex + 1;
            setHistoryIndex(newIndex);
            const historicalData = history[newIndex];
            setLocalQuestions(historicalData);
            
            const totalScore = historicalData.reduce((sum, q) => sum + q.score, 0);
            setTotalScore(totalScore);
        }
    };

    return (
        <div className="border border-purple-300 p-6 rounded-lg bg-purple-50 space-y-4">
            <h3 className="heading-h5 text-purple-800">Question Set Editor</h3>
            
            {/* ROW: Undo/Redo Controls */}
            <div className="flex justify-start space-x-2 bg-purple-100 p-2 rounded-md">
                <button
                    type="button"
                    onClick={handleUndo}
                    disabled={historyIndex <= 0}
                    className={`px-4 py-2 rounded-lg text-sm transition-colors ${historyIndex <= 0 ? 'bg-gray-400 text-gray-600 cursor-not-allowed' : 'bg-purple-600 text-white hover:bg-purple-700'}`}
                >
                    &larr; Undo
                </button>
                <button
                    type="button"
                    onClick={handleRedo}
                    disabled={historyIndex >= history.length - 1}
                    className={`px-4 py-2 rounded-lg text-sm transition-colors ${historyIndex >= history.length - 1 ? 'bg-gray-400 text-gray-600 cursor-not-allowed' : 'bg-purple-600 text-white hover:bg-purple-700'}`}
                >
                    Redo &rarr;
                </button>
                <span className="text-xs text-gray-600 self-center ml-2">
                    History: {historyIndex + 1} / {history.length}
                </span>
            </div>
            
            <div className="space-y-4 max-h-96 overflow-y-auto">
                {localQuestions.map((q, index) => (
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
    );
}