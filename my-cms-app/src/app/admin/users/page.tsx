// app/admin/users/page.tsx
'use client';

import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { Search, MoreVertical, Eye, UserCheck, UserX, ShieldCheck, Shield, Trash2 } from 'lucide-react';
import UserProfile from '@/components/UserProfile';

interface User {
  id: string;
  fullName: string;
  email: string;
  role: string;
  status: string;
  verification: string;
  photoUrl?: string;
  createdAt: string;
  childrenCount: number;
  activityRecordCount: number;
}

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [verificationFilter, setVerificationFilter] = useState('');
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const [confirmDeleteId, setConfirmDeleteId] = useState<string | null>(null);
  const [deleting, setDeleting] = useState(false);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchUsers();
  }, [searchQuery, statusFilter, verificationFilter, currentPage]);

  // Click outside to close menu
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setOpenMenuId(null);
      }
    };

    document.addEventListener('mousedown', handleClickOutside);
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, []);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        page: currentPage.toString(),
        limit: '10',
      });
      
      if (searchQuery) params.append('search', searchQuery);
      if (statusFilter) params.append('status', statusFilter);
      if (verificationFilter) params.append('verification', verificationFilter);

      const res = await fetch(`/api/users?${params}`);
      const data = await res.json();
      
      setUsers(data.users || []);
      setTotalPages(data.pagination?.totalPages || 1);
    } catch (error) {
      console.error('Failed to fetch users:', error);
      setUsers([]);
    } finally {
      setLoading(false);
    }
  };

  const toggleMenu = (id: string) => {
    setOpenMenuId(openMenuId === id ? null : id);
  };

  const handleDeleteUser = async () => {
    if (!confirmDeleteId) return;
    setDeleting(true);
    try {
      const res = await fetch(`/api/users/${confirmDeleteId}`, { method: 'DELETE' });
      if (!res.ok) throw new Error('Delete failed');
      setConfirmDeleteId(null);
      fetchUsers();
    } catch (error) {
      console.error('Failed to delete user:', error);
    } finally {
      setDeleting(false);
    }
  };

  const getStatusBadge = (status: string) => {
    const isActive = status === 'Active';
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full body-xs-medium ${
        isActive 
          ? 'bg-green--light6 text-green--dark' 
          : 'bg-red--light6 text-red--dark'
      }`}>
        {isActive ? <UserCheck size={12} /> : <UserX size={12} />}
        {status}
      </span>
    );
  };

  const getRoleBadge = (role: string) => {
    const isAdmin = role === 'admin';
    return (
      <span className={`inline-flex items-center gap-1 px-2 py-1 rounded-full body-xs-medium ${
        isAdmin
          ? 'bg-purple--light4 text-purple--dark'
          : 'bg-gray3 text-secondary--text'
      }`}>
        {isAdmin ? <ShieldCheck size={12} /> : <Shield size={12} />}
        {isAdmin ? 'Admin' : 'User'}
      </span>
    );
  };

  const getVerificationBadge = (verification: string) => {
    const isVerified = verification === 'Verified';
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium ${
        isVerified 
          ? 'bg-cyan--light3 text-purple--dark' 
          : 'bg-yellow--light3 text-dark'
      }`}>
        {verification}
      </span>
    );
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-full">
        <div className="body-large-medium text-secondary--text">Loading...</div>
      </div>
    );
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="body-small-regular text-secondary--text mb-1">
            Users &gt; User List
          </div>
          <h1 className="heading-h3">USERS</h1>
        </div>
        <div className="flex items-center gap-4">
          <UserProfile />
        </div>
      </div>

      {/* Search and Filters */}
      <div className="mb-6 flex flex-wrap gap-4">
        <div className="relative flex-1 min-w-[250px] max-w-md">
          <Search
            className="absolute left-3 top-1/2 transform -translate-y-1/2 text-secondary--text"
            size={20}
          />
          <input
            type="text"
            placeholder="Search by name or email"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        </div>
        
        {/* <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
        >
          <option value="">All Status</option>
          <option value="Active">Active</option>
          <option value="Inactive">Inactive</option>
        </select>

        <select
          value={verificationFilter}
          onChange={(e) => setVerificationFilter(e.target.value)}
          className="px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
        >
          <option value="">All Verification</option>
          <option value="Verified">Verified</option>
          <option value="Pending">Pending</option>
          <option value="Unverified">Unverified</option>
        </select> */}
      </div>

      {/* Table */}
      <div className="bg-white rounded-lg shadow">
        <div className="overflow-x-auto">
        <table className="w-full min-w-[900px]">
          <thead className="bg-gray--light1 border-b border-gray4">
            <tr>
              <th className="w-12 px-3 py-3 text-left body-small-medium text-secondary--text">No.</th>
              <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Full Name</th>
              <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Email</th>
              <th className="w-20 px-3 py-3 text-center body-small-medium text-secondary--text">Role</th>
              <th className="w-20 px-3 py-3 text-center body-small-medium text-secondary--text">Status</th>
              <th className="w-24 px-3 py-3 text-center body-small-medium text-secondary--text">Verification</th>
              <th className="w-16 px-3 py-3 text-center body-small-medium text-secondary--text">Children</th>
              <th className="w-16 px-3 py-3 text-center body-small-medium text-secondary--text">Activities</th>
              <th className="w-28 px-3 py-3 text-left body-small-medium text-secondary--text whitespace-nowrap">Date Created</th>
              <th className="w-12 px-3 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray4">
            {users.map((user, index) => (
              <tr
                key={user.id}
                className="hover:bg-gray--light1"
              >
                <td className="px-3 py-3 body-medium-regular">
                  {(currentPage - 1) * 10 + index + 1}
                </td>
                <td className="px-4 py-3 max-w-[160px]">
                  <div className="flex items-center gap-3 min-w-0">
                    {user.photoUrl ? (
                      <img
                        src={user.photoUrl}
                        alt={user.fullName}
                        className="w-8 h-8 rounded-full object-cover flex-shrink-0"
                      />
                    ) : (
                      <div className="w-8 h-8 rounded-full bg-purple--light4 flex items-center justify-center body-small-medium text-purple flex-shrink-0">
                        {user.fullName.charAt(0).toUpperCase()}
                      </div>
                    )}
                    <span className="body-medium-medium truncate" title={user.fullName}>{user.fullName}</span>
                  </div>
                </td>
                <td className="px-4 py-3 body-medium-regular max-w-[180px]">
                  <span className="truncate block" title={user.email}>{user.email}</span>
                </td>
                <td className="px-3 py-3 text-center">
                  {getRoleBadge(user.role)}
                </td>
                <td className="px-3 py-3 text-center">
                  {getStatusBadge(user.status)}
                </td>
                <td className="px-3 py-3 text-center">
                  {getVerificationBadge(user.verification)}
                </td>
                <td className="px-3 py-3 body-medium-regular text-center">
                  {user.childrenCount}
                </td>
                <td className="px-3 py-3 body-medium-regular text-center">
                  {user.activityRecordCount}
                </td>
                <td className="px-3 py-3 body-medium-regular whitespace-nowrap">
                  {new Date(user.createdAt).toLocaleDateString('en-US', {
                    day: 'numeric',
                    month: 'short',
                    year: 'numeric'
                  })}
                </td>
                <td className="px-4 py-3">
                  <div className="relative" ref={openMenuId === user.id ? menuRef : null}>
                    <button 
                      onClick={() => toggleMenu(user.id)}
                      className="p-1 hover:bg-gray--light1 rounded"
                    >
                      <MoreVertical size={16} className="text-secondary--text" />
                    </button>
                    {openMenuId === user.id && (
                      <div className="absolute right-0 top-full mt-1 bg-white border border-gray4 rounded-lg shadow-lg py-2 z-10 min-w-[140px]">
                        <Link
                          href={`/admin/users/${user.id}`}
                          className="flex items-center gap-2 px-4 py-2 hover:bg-gray--light1 body-small-medium whitespace-nowrap"
                          onClick={() => setOpenMenuId(null)}
                        >
                          <Eye size={16} />
                          View Detail
                        </Link>
                        <button
                          className="w-full flex items-center gap-2 px-4 py-2 hover:bg-red--light6 body-small-medium whitespace-nowrap text-red--dark"
                          onClick={() => { setOpenMenuId(null); setConfirmDeleteId(user.id); }}
                        >
                          <Trash2 size={16} />
                          Delete User
                        </button>
                      </div>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        </div>

        {/* Pagination */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray4">
          <div className="body-small-regular text-secondary--text">
            Showing {users.length > 0 ? (currentPage - 1) * 10 + 1 : 0} to {(currentPage - 1) * 10 + users.length} of total results
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
              disabled={currentPage === 1}
              className={`px-3 py-1 body-small-medium rounded ${
                currentPage === 1
                  ? 'text-gray6 cursor-not-allowed'
                  : 'text-secondary--text hover:bg-gray--light1'
              }`}
            >
              Previous
            </button>
            
            {currentPage > 2 && (
              <button
                onClick={() => setCurrentPage(1)}
                className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded"
              >
                1
              </button>
            )}
            
            {currentPage > 3 && (
              <span className="px-2 body-small-medium text-secondary--text">...</span>
            )}
            
            {currentPage > 1 && (
              <button
                onClick={() => setCurrentPage(currentPage - 1)}
                className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded"
              >
                {currentPage - 1}
              </button>
            )}
            
            <button className="px-3 py-1 body-small-medium bg-purple text-white rounded">
              {currentPage}
            </button>
            
            {currentPage < totalPages && (
              <button
                onClick={() => setCurrentPage(currentPage + 1)}
                className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded"
              >
                {currentPage + 1}
              </button>
            )}
            
            {currentPage < totalPages - 2 && (
              <span className="px-2 body-small-medium text-secondary--text">...</span>
            )}
            
            {currentPage < totalPages - 1 && (
              <button
                onClick={() => setCurrentPage(totalPages)}
                className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded"
              >
                {totalPages}
              </button>
            )}
            
            <button
              onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
              disabled={currentPage === totalPages}
              className={`px-3 py-1 body-small-medium rounded ${
                currentPage === totalPages
                  ? 'text-gray6 cursor-not-allowed'
                  : 'text-secondary--text hover:bg-gray--light1'
              }`}
            >
              Next
            </button>
          </div>
        </div>
      </div>

      {/* Empty State */}
      {users.length === 0 && !loading && (
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <div className="body-large-medium text-secondary--text mb-2">
            No users found
          </div>
          <div className="body-medium-regular text-secondary--text">
            Try adjusting your search or filters
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {confirmDeleteId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
          <div className="bg-white rounded-xl shadow-xl p-6 w-full max-w-sm mx-4">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-full bg-red--light6 flex items-center justify-center flex-shrink-0">
                <Trash2 size={20} className="text-red--dark" />
              </div>
              <h2 className="body-large-medium">Delete User</h2>
            </div>
            <p className="body-medium-regular text-secondary--text mb-6">
              This action cannot be undone. The user account and all associated data will be permanently deleted.
            </p>
            <div className="flex gap-3 justify-end">
              <button
                onClick={() => setConfirmDeleteId(null)}
                disabled={deleting}
                className="px-4 py-2 body-small-medium border border-gray4 rounded-lg hover:bg-gray--light1 disabled:opacity-50"
              >
                Cancel
              </button>
              <button
                onClick={handleDeleteUser}
                disabled={deleting}
                className="px-4 py-2 body-small-medium bg-red--dark text-white rounded-lg hover:opacity-90 disabled:opacity-50"
              >
                {deleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}