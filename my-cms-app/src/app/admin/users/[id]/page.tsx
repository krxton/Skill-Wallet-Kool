"use client";

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation'; // ใช้ useParams/useRouter
import { ArrowLeft, Mail, User, Shield, Users, Calendar, Hash } from 'lucide-react';

// Interfaces
interface ChildData {
    id: string;
    fullName: string;
    dob: string; // ISO String
    score: number;
}

interface ParentDetailData {
    id: string;
    fullName: string;
    email: string;
    createdAt: string;
    status: string;
    verification: string;
    children: {
        relationship: string;
        child: ChildData;
    }[];
}

// Helper: Component Badge (ป้ายสถานะ)
const StatusBadge = ({ status }: { status: string }) => {
    const color = status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800';
    return <span className={`px-2 py-1 rounded-full text-sm font-medium ${color}`}>{status}</span>;
};
const VerificationBadge = ({ status }: { status: string }) => {
    const color = status === 'Verified' ? 'bg-blue-100 text-blue-800' : 'bg-red-100 text-red-800';
    return <span className={`px-2 py-1 rounded-full text-sm font-medium ${color}`}>{status}</span>;
};

// ===========================================
// Main Component
// ===========================================
export default function UserDetailPage() {
    const router = useRouter();
    const params = useParams(); // ดึง [id] จาก URL
    const userId = params?.id as string; // ค่า id ที่ได้

    const [user, setUser] = useState<ParentDetailData | null>(null);
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    // 1. Fetch Data
    useEffect(() => {
        if (!userId) return; // ถ้ายังไม่มี ID, ไม่ต้องทำอะไร

        const fetchUserDetail = async () => {
            setIsLoading(true);
            setError(null);
            try {
                const response = await fetch(`/api/admin/users/${userId}`);
                if (!response.ok) {
                    const errorData = await response.json();
                    throw new Error(errorData.error || 'Failed to fetch user details');
                }
                const data = await response.json();
                setUser(data);
            } catch (err: any) {
                console.error(err);
                setError(err.message);
            } finally {
                setIsLoading(false);
            }
        };

        fetchUserDetail();
    }, [userId]); // ดึงข้อมูลใหม่เมื่อ userId เปลี่ยน

    // Helper: คำนวณอายุ
    const getAge = (dob: string) => {
        if (!dob) return 'N/A';
        const age = new Date().getFullYear() - new Date(dob).getFullYear();
        return age;
    };

    // ===========================================
    // JSX (ส่วนแสดงผล)
    // ===========================================

    if (isLoading) {
        return <div className="p-8 text-center text-gray-500">Loading user details...</div>;
    }

    if (error) {
        return <div className="p-8 text-center text-red-600">Error: {error}</div>;
    }

    if (!user) {
        return <div className="p-8 text-center text-gray-500">User not found.</div>;
    }

    // เมื่อมีข้อมูล
    return (
        <div className="p-4 md:p-8 bg-gray-50 min-h-screen">
            {/* Back Button */}
            <button
                onClick={() => router.back()} // <-- ใช้ router.back()
                className="flex items-center gap-2 text-sm text-blue-600 hover:underline mb-6"
            >
                <ArrowLeft size={16} />
                Back to User List
            </button>

            {/* Parent Info Card */}
            <div className="bg-white p-6 rounded-lg shadow-lg mb-8">
                <h1 className="text-2xl font-bold text-gray-900 mb-6">{user.fullName}</h1>
                
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div className="flex items-center gap-3">
                        <Mail size={18} className="text-gray-500" />
                        <span className="text-sm text-gray-700">{user.email}</span>
                    </div>
                    <div className="flex items-center gap-3">
                        <Calendar size={18} className="text-gray-500" />
                        <span className="text-sm text-gray-700">Joined: {new Date(user.createdAt).toLocaleDateString()}</span>
                    </div>
                    <div className="flex items-center gap-3">
                        <Hash size={18} className="text-gray-500" />
                        <span className="text-sm text-gray-700">ID: {user.id}</span>
                    </div>
                    <div className="flex items-center gap-3">
                        <Shield size={18} className="text-gray-500" />
                        <StatusBadge status={user.status} />
                    </div>
                    <div className="flex items-center gap-3">
                        <Shield size={18} className="text-gray-500" />
                        <VerificationBadge status={user.verification} />
                    </div>
                </div>
            </div>

            {/* Children List Card */}
            <div className="bg-white p-6 rounded-lg shadow-lg">
                <h2 className="text-xl font-semibold text-gray-900 mb-4 flex items-center gap-2">
                    <Users size={20} />
                    Linked Children ({user.children.length})
                </h2>

                <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                        <thead className="bg-gray-50">
                            <tr>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Full Name</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Relationship</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Age (Approx.)</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Total Score</th>
                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Child ID</th>
                            </tr>
                        </thead>
                        <tbody className="bg-white divide-y divide-gray-200">
                            {user.children.length > 0 ? (
                                user.children.map(item => (
                                    <tr key={item.child.id}>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">{item.child.fullName}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.relationship}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{getAge(item.child.dob)}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900 font-semibold">{item.child.score.toLocaleString()}</td>
                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{item.child.id}</td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan={5} className="text-center py-6 text-gray-500">No linked children found.</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    );
}

