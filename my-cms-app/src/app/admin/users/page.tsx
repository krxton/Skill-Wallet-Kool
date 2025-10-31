"use client";

import { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { User, Search, ChevronLeft, ChevronRight, MoreVertical, Edit, Trash2 } from 'lucide-react';

// Interfaces (ตรงกับ API)
interface ParentData {
    id: string;
    fullName: string;
    email: string;
    createdAt: string;
    status: string;
    verification: string;
    _count: {
        children: number;
    };
}

interface PaginationInfo {
    totalItems: number;
    totalPages: number;
    currentPage: number;
    itemsPerPage: number;
}

// Helper: Component Badge (ป้ายสถานะ)
const StatusBadge = ({ status }: { status: string }) => {
    const color = status === 'Active' ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-800';
    return <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${color}`}>{status}</span>;
};
const VerificationBadge = ({ status }: { status: string }) => {
    const color = status === 'Verified' ? 'bg-blue-100 text-blue-800' : 'bg-red-100 text-red-800';
    return <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${color}`}>{status}</span>;
};

// Helper: Format Date แบบไทย
const formatThaiDate = (dateString: string) => {
    try {
        const date = new Date(dateString);
        // แสดงแบบ: 26/10/2025 หรือ 26 ต.ค. 2025
        return date.toLocaleDateString('th-TH', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
        });
    } catch (error) {
        return 'Invalid Date';
    }
};

// Helper: Shorten ID with tooltip support
const ShortId = ({ id }: { id: string }) => (
    <span title={id} className="cursor-help">
        {id.substring(0, 8)}...
    </span>
);

// ===========================================
// Main Component
// ===========================================
export default function UsersPage() {
    const router = useRouter();
    const [users, setUsers] = useState<ParentData[]>([]);
    const [pagination, setPagination] = useState<PaginationInfo | null>(null);
    const [currentPage, setCurrentPage] = useState(1);
    const [searchTerm, setSearchTerm] = useState('');
    const [isLoading, setIsLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);
    
    const limit = 6; // จำนวนที่แสดงต่อหน้า (ตรงกับ Wireframe)

    // 1. ฟังก์ชันดึงข้อมูล (ใช้ useEffect)
    useEffect(() => {
        const fetchUsers = async () => {
            setIsLoading(true);
            setError(null);
            try {
                // สร้าง URLSearchParams
                const params = new URLSearchParams();
                params.append('page', currentPage.toString());
                params.append('limit', limit.toString());
                if (searchTerm.trim()) {
                    params.append('search', searchTerm.trim());
                }

                const response = await fetch(`/api/admin/users?${params.toString()}`);
                
                if (!response.ok) {
                    // ถ้า Server ตอบกลับมาไม่ 200 OK
                    const errorData = await response.json();
                    throw new Error(errorData.error || `Failed to fetch: ${response.statusText}`);
                }
                
                const data = await response.json();
                setUsers(data.data || []); // ✅ เพิ่ม fallback
                setPagination(data.pagination);
                
            } catch (err: any) {
                console.error('Fetch error:', err);
                setError(err.message || 'Failed to fetch data. Check API connection.');
                setUsers([]); // ✅ Clear users on error
            } finally {
                setIsLoading(false);
            }
        };

        fetchUsers();
    }, [currentPage, searchTerm]); // ดึงข้อมูลใหม่เมื่อ 'หน้า' หรือ 'คำค้นหา' เปลี่ยน

    // 2. Handlers สำหรับ Pagination
    const handleNextPage = () => {
        if (pagination && currentPage < pagination.totalPages) {
            setCurrentPage(currentPage + 1);
        }
    };

    const handlePrevPage = () => {
        if (currentPage > 1) {
            setCurrentPage(currentPage - 1);
        }
    };
    
    // 3. Handler สำหรับการค้นหา (Debounced)
    const handleSearchSubmit = (e: React.FormEvent<HTMLFormElement>) => {
        e.preventDefault();
        setCurrentPage(1); // กลับไปหน้า 1 เมื่อค้นหา
    };
    
    // 4. Handler สำหรับการคลิกที่แถว
    const handleRowClick = (userId: string) => {
        router.push(`/admin/users/${userId}`);
    };
    
    // 5. Handler สำหรับการลบผู้ใช้
    const handleDeleteUser = async (userId: string, userName: string) => {
        if (!confirm(`Are you sure you want to delete user "${userName}"?\n\nThis action cannot be undone and will also delete:\n- All associated children\n- All progress data\n- All related records`)) {
            return;
        }
        
        // Double confirmation for safety
        if (!confirm('This is your last warning. Type "DELETE" in your mind and click OK to proceed.')) {
            return;
        }
        
        setIsLoading(true);
        setError(null);
        
        try {
            const response = await fetch(`/api/admin/users/${userId}`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json',
                },
            });
            
            // ✅ จัดการกรณี 204 No Content (ไม่มี response body)
            if (response.status === 204) {
                alert(`User "${userName}" has been successfully deleted.`);
                
                // Refresh data
                if (users.length === 1 && currentPage > 1) {
                    setCurrentPage(currentPage - 1);
                } else {
                    // Re-fetch current page
                    const params = new URLSearchParams();
                    params.append('page', currentPage.toString());
                    params.append('limit', limit.toString());
                    if (searchTerm.trim()) {
                        params.append('search', searchTerm.trim());
                    }
                    
                    const refreshResponse = await fetch(`/api/admin/users?${params.toString()}`);
                    if (refreshResponse.ok) {
                        const data = await refreshResponse.json();
                        setUsers(data.data || []);
                        setPagination(data.pagination);
                    }
                }
                
                setIsLoading(false);
                return;
            }
            
            // ✅ จัดการกรณีที่มี response body
            if (!response.ok) {
                // ตรวจสอบว่ามี content ใน response หรือไม่
                const contentType = response.headers.get('content-type');
                let errorMessage = 'Failed to delete user';
                
                if (contentType && contentType.includes('application/json')) {
                    try {
                        const errorData = await response.json();
                        errorMessage = errorData.error || errorMessage;
                    } catch (e) {
                        // ถ้า parse JSON ไม่ได้ ใช้ status text
                        errorMessage = response.statusText || errorMessage;
                    }
                } else {
                    errorMessage = response.statusText || errorMessage;
                }
                
                // ✅ กรณี 405 Method Not Allowed
                if (response.status === 405) {
                    errorMessage = 'Delete operation is not supported by the API. Please contact the administrator.';
                }
                
                throw new Error(errorMessage);
            }
            
            // กรณี success แบบปกติ (200 OK with body)
            const contentType = response.headers.get('content-type');
            if (contentType && contentType.includes('application/json')) {
                const data = await response.json();
                alert(data.message || `User "${userName}" has been successfully deleted.`);
            } else {
                alert(`User "${userName}" has been successfully deleted.`);
            }
            
            // Refresh data
            if (users.length === 1 && currentPage > 1) {
                setCurrentPage(currentPage - 1);
            } else {
                const params = new URLSearchParams();
                params.append('page', currentPage.toString());
                params.append('limit', limit.toString());
                if (searchTerm.trim()) {
                    params.append('search', searchTerm.trim());
                }
                
                const refreshResponse = await fetch(`/api/admin/users?${params.toString()}`);
                if (refreshResponse.ok) {
                    const data = await refreshResponse.json();
                    setUsers(data.data || []);
                    setPagination(data.pagination);
                }
            }
            
        } catch (err: any) {
            console.error('Delete error:', err);
            const errorMessage = err.message || 'Failed to delete user. Please try again.';
            setError(errorMessage);
            alert(`Error: ${errorMessage}`);
        } finally {
            setIsLoading(false);
        }
    };

    // 5. Memoization สำหรับ Pagination Text (แก้ไขการคำนวณ)
    const paginationText = useMemo(() => {
        if (!pagination || pagination.totalItems === 0) {
            return 'Showing 0 of 0 results';
        }
        
        // ✅ ใช้ข้อมูลจาก pagination ที่ได้จาก API โดยตรง
        const start = (pagination.currentPage - 1) * pagination.itemsPerPage + 1;
        const end = Math.min(pagination.currentPage * pagination.itemsPerPage, pagination.totalItems);
        
        return `Showing ${start} to ${end} of ${pagination.totalItems} results`;
    }, [pagination]);


    // ===========================================
    // JSX (ส่วนแสดงผล)
    // ===========================================
    return (
        <div className="p-4 md:p-8 bg-gray-50 min-h-screen">
            <h1 className="text-2xl font-semibold text-gray-900 mb-6">User List</h1>

            {/* Search Bar */}
            <form onSubmit={handleSearchSubmit} className="mb-4">
                <div className="relative">
                    <input
                        type="text"
                        placeholder="Search by Full Name or Email"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        className="w-full pl-10 pr-4 py-2 border rounded-lg shadow-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" size={20} />
                </div>
            </form>

            {/* Error Message */}
            {error && (
                <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded relative mb-4" role="alert">
                    <strong className="font-bold">Error: </strong>
                    <span className="block sm:inline">{error}</span>
                </div>
            )}

            {/* Table */}
            <div className="bg-white shadow rounded-lg overflow-x-auto">
                <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                        <tr>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                <input type="checkbox" className="rounded" />
                            </th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">ID</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Full Name</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Email</th>
                            <th scope="col" className="px-6 py-3 text-center text-xs font-medium text-gray-500 uppercase tracking-wider">Children</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date Created</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
                            <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Verification</th>
                            <th scope="col" className="relative px-6 py-3"><span className="sr-only">Actions</span></th>
                        </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                        {isLoading ? (
                            <tr><td colSpan={9} className="text-center py-8 text-gray-500">Loading...</td></tr>
                        ) : users.length > 0 ? (
                            users.map((user) => (
                                <tr 
                                    key={user.id} 
                                    className="hover:bg-gray-50 cursor-pointer transition-colors"
                                    onClick={() => handleRowClick(user.id)}
                                >
                                    <td className="px-6 py-4 whitespace-nowrap" onClick={(e) => e.stopPropagation()}>
                                        <input type="checkbox" className="rounded" />
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 font-mono">
                                        <ShortId id={user.id} />
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                                        {user.fullName || 'N/A'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {user.email || 'N/A'}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500 text-center">
                                        {/* ✅ เพิ่ม fallback สำหรับ children count */}
                                        <span className="inline-flex items-center justify-center w-8 h-8 rounded-full bg-blue-100 text-blue-800 font-semibold">
                                            {user._count?.children ?? 0}
                                        </span>
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                                        {/* ✅ ใช้ formatThaiDate */}
                                        {formatThaiDate(user.createdAt)}
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                                        <StatusBadge status={user.status || 'Unknown'} />
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-sm">
                                        <VerificationBadge status={user.verification || 'Unknown'} />
                                    </td>
                                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                        <button 
                                            onClick={(e) => { 
                                                e.stopPropagation(); 
                                                router.push(`/admin/users/${user.id}/edit`);
                                            }} 
                                            className="text-indigo-600 hover:text-indigo-900 mr-3"
                                            title="Edit user"
                                        >
                                            <Edit size={16}/>
                                        </button>
                                        <button 
                                            onClick={(e) => { 
                                                e.stopPropagation(); 
                                                handleDeleteUser(user.id, user.fullName);
                                            }} 
                                            className="text-red-600 hover:text-red-900 disabled:opacity-50 disabled:cursor-not-allowed"
                                            title="Delete user"
                                            disabled={isLoading}
                                        >
                                            <Trash2 size={16}/>
                                        </button>
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <tr><td colSpan={9} className="text-center py-8 text-gray-500">
                                {searchTerm ? `No users found matching "${searchTerm}"` : 'No users found.'}
                            </td></tr>
                        )}
                    </tbody>
                </table>
            </div>

            {/* Pagination Controls */}
            {pagination && pagination.totalItems > 0 && (
                <div className="flex items-center justify-between mt-4">
                    <span className="text-sm text-gray-700">{paginationText}</span>
                    <div className="flex gap-2 items-center">
                        <span className="text-sm text-gray-600 mr-2">
                            Page {pagination.currentPage} of {pagination.totalPages}
                        </span>
                        <button
                            onClick={handlePrevPage}
                            disabled={currentPage === 1}
                            className="px-3 py-1 border rounded-lg text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 flex items-center gap-1 transition-colors"
                        >
                            <ChevronLeft size={16} /> Previous
                        </button>
                        <button
                            onClick={handleNextPage}
                            disabled={!pagination || currentPage === pagination.totalPages}
                            className="px-3 py-1 border rounded-lg text-sm disabled:opacity-50 disabled:cursor-not-allowed hover:bg-gray-50 flex items-center gap-1 transition-colors"
                        >
                            Next <ChevronRight size={16} />
                        </button>
                    </div>
                </div>
            )}
        </div>
    );
}