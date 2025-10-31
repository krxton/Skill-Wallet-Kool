// src\app\activities\edit\components\LanguageEditControls.tsx
'use client';

import React, { useState, useRef } from 'react';
import cuid from 'cuid';

interface Segment {
  id: string;
  start: number;
  end: number;
  text: string;
}

interface LanguageControlsProps {
    localSegments: Segment[];
    setLocalSegments: React.Dispatch<React.SetStateAction<Segment[]>>;
    history: Segment[][];
    historyIndex: number;
    setHistoryIndex: React.Dispatch<React.SetStateAction<number>>;
    saveSnapshot: (data: Segment[], currentScore: number) => void; // ✅ เพิ่ม currentScore parameter
    maxScore: number; // ✅ เพิ่ม prop สำหรับคะแนนปัจจุบัน
}

export default function LanguageEditControls({
    localSegments,
    setLocalSegments,
    history,
    historyIndex,
    setHistoryIndex,
    saveSnapshot,
    maxScore, // ✅ รับค่า currentScore
}: LanguageControlsProps) {
    
    const [selectedIndices, setSelectedIndices] = useState<number[]>([]);
    
    // Debounce timer สำหรับ text/time changes
    const debounceTimerRef = useRef<NodeJS.Timeout | null>(null);

    // Handler สำหรับการแก้ไข Segment แต่ละตัว (Update)
    const handleSegmentChange = (index: number, field: 'start' | 'end' | 'text', value: string | number) => {
        const newSegments = localSegments.map((segment, i) => {
            if (i === index) {
                if (field === 'start' || field === 'end') {
                    return { ...segment, [field]: parseFloat(value as string) || 0 };
                } else {
                    return { ...segment, [field]: value as string };
                }
            }
            return segment;
        });
        setLocalSegments(newSegments);
        
        // *** Debounce สำหรับ text field, Immediate save สำหรับ time ***
        if (field === 'text') {
            // Debounce 500ms สำหรับการพิมพ์ข้อความ
            if (debounceTimerRef.current) {
                clearTimeout(debounceTimerRef.current);
            }
            debounceTimerRef.current = setTimeout(() => {
                saveSnapshot(newSegments, maxScore);
            }, 500);
        } else {
            // บันทึกทันทีสำหรับการเปลี่ยน start/end time
            saveSnapshot(newSegments, maxScore);
        }
    };

    // Handler สำหรับการเลือก/ยกเลิกการเลือก Segment
    const handleSelectSegment = (index: number, isSelected: boolean) => {
        setSelectedIndices(prev => {
            if (isSelected) {
                const newSelection = [...prev, index];
                return newSelection.sort((a, b) => a - b);
            } else {
                return prev.filter(i => i !== index);
            }
        });
    };

    // Handler สำหรับการลบ Segment แต่ละตัว
    const handleDeleteSegment = (indexToDelete: number) => {
        if (!confirm(`Are you sure you want to delete segment ${indexToDelete + 1}?`)) return;
        
        const newSegments = localSegments.filter((_, index) => index !== indexToDelete);
        setLocalSegments(newSegments);
        saveSnapshot(newSegments, maxScore); // ✅ ส่ง currentScore
        setSelectedIndices([]); 
    };
    
    // Handler สำหรับการรวม Segment ที่ถูกเลือก
    const handleMergeSegments = () => {
        if (selectedIndices.length < 2) {
            alert("Please select at least two segments to merge.");
            return;
        }

        if (!confirm(`Are you sure you want to merge ${selectedIndices.length} segments?`)) return;

        const sortedIndices = selectedIndices; 
        const segmentsToMerge = sortedIndices.map(i => localSegments[i]);

        const mergedText = segmentsToMerge.map(s => s.text).join(' '); 
        const earliestStart = segmentsToMerge[0].start; 
        const latestEnd = segmentsToMerge[segmentsToMerge.length - 1].end; 

        const newSegment: Segment = {
            id: cuid(), // ต้องสร้าง ID ใหม่สำหรับการ Merge
            start: earliestStart,
            end: latestEnd,
            text: mergedText,
        };

        const newSegments: Segment[] = [];
        let firstSegmentIndex = sortedIndices[0];

        localSegments.forEach((segment, index) => {
            if (index === firstSegmentIndex) {
                newSegments.push(newSegment);
            } else if (!sortedIndices.includes(index)) {
                newSegments.push(segment);
            }
        });

        setLocalSegments(newSegments);
        setSelectedIndices([]); 
        saveSnapshot(newSegments, maxScore); // ✅ ส่ง currentScore
        alert("Segments merged successfully!");
    };
    
    // ฟังก์ชัน Undo/Redo (เรียกใช้ Logic ใน History Stack)
    const handleUndo = () => {
        if (historyIndex > 0) {
            const newIndex = historyIndex - 1;
            setHistoryIndex(newIndex);
            setLocalSegments(history[newIndex]);
            setSelectedIndices([]);
        }
    };

    const handleRedo = () => {
        if (historyIndex < history.length - 1) {
            const newIndex = historyIndex + 1;
            setHistoryIndex(newIndex);
            setLocalSegments(history[newIndex]);
            setSelectedIndices([]);
        }
    };


    return (
        <div className="border border-purple-300 p-6 rounded-lg bg-purple-50 space-y-4">
            <h3 className="heading-h5 text-purple-800">Subtitle Segments (Editor)</h3>
            
            {/* ปุ่ม Undo/Redo & Merge Controls */}
            <div className="flex justify-between items-center bg-purple-100 p-2 rounded-md">
                <div className="space-x-2">
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

                <button
                    type="button"
                    onClick={handleMergeSegments}
                    disabled={selectedIndices.length < 2}
                    className={`px-4 py-2 rounded-lg text-white font-semibold text-sm transition-colors ${
                        selectedIndices.length < 2 ? 'bg-gray-400 cursor-not-allowed' : 'bg-green-600 hover:bg-green-700'
                    }`}
                >
                    Merge Selected ({selectedIndices.length})
                </button>
            </div>

            <div className="space-y-3 max-h-96 overflow-y-auto border p-2 bg-white rounded-md">
                {localSegments.length === 0 ? (
                     <p className="text-gray-500 text-center py-4">No segments data found.</p>
                ) : (
                    localSegments.map((segment, index) => (
                        <div 
                            key={segment.id} // ใช้ ID เป็น key
                            className={`flex space-x-3 items-center p-3 border rounded-md shadow-sm transition-all ${
                                selectedIndices.includes(index) ? 'border-purple-500 bg-purple-100' : 'border-gray-200 bg-white'
                            }`}
                        >
                            {/* Checkbox สำหรับการรวม */}
                            <input 
                                type="checkbox" 
                                checked={selectedIndices.includes(index)}
                                onChange={(e) => handleSelectSegment(index, e.target.checked)}
                                className="h-5 w-5 text-purple-600 focus:ring-purple-500 border-gray-300 rounded"
                            />

                            <div className="body-medium-semibold text-purple-600 w-8">{index + 1}.</div>
                            
                            {/* Start Time */}
                            <input
                                type="number"
                                value={segment.start}
                                onChange={(e) => handleSegmentChange(index, 'start', e.target.value)}
                                className="input w-24 text-center text-sm"
                                step="0.1"
                                min="0"
                            />
                            <span className="text-gray-500">-</span>
                            {/* End Time */}
                             <input
                                type="number"
                                value={segment.end}
                                onChange={(e) => handleSegmentChange(index, 'end', e.target.value)}
                                className="input w-24 text-center text-sm"
                                step="0.1"
                                min="0"
                            />

                            {/* Input Sentence Text */}
                            <input
                                type="text"
                                value={segment.text}
                                onChange={(e) => handleSegmentChange(index, 'text', e.target.value)}
                                className="input w-full text-sm flex-1"
                                required
                            />
                            
                            {/* ปุ่ม Delete Segment */}
                            <button
                                type="button"
                                onClick={() => handleDeleteSegment(index)}
                                className="bg-red-500 text-white px-3 py-1 text-xs rounded-md hover:bg-red-600 ml-2"
                                title="Delete this segment"
                            >
                                Delete
                            </button>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}