'use client';

import { useEffect, useState, useRef } from 'react';
import Link from 'next/link';
import { Plus, Search, MoreVertical, Edit, Trash2, Globe, Lock } from 'lucide-react';
import UserProfile from '@/components/UserProfile';

interface Activity {
  activityId: string;
  nameActivity: string;
  category: string;
  descriptionActivity: string;
  createdAt: string;
  responses: number;
  isPublic: boolean;
}

export default function ActivitiesPage() {
  const [activities, setActivities] = useState<Activity[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [total, setTotal] = useState(0);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    fetchActivities();
  }, [page, searchQuery, categoryFilter]);

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

  const fetchActivities = async () => {
    try {
      setLoading(true);
      const params = new URLSearchParams({
        page: page.toString(),
        limit: '10',
        ...(searchQuery && { search: searchQuery }),
        ...(categoryFilter && { category: categoryFilter }),
      });
      
      const res = await fetch(`/api/activities?${params}`);
      const result = await res.json();
      
      if (result.success) {
        setActivities(result.data);
        setTotal(result.pagination.total);
        setTotalPages(result.pagination.totalPages);
      } else {
        console.error('API error:', result.error);
        setActivities([]);
      }
    } catch (error) {
      console.error('Failed to fetch activities:', error);
      setActivities([]);
    } finally {
      setLoading(false);
    }
  };

  const handleSelectAll = (checked: boolean) => {
    if (checked) {
      setSelectedIds(activities.map(a => a.activityId));
    } else {
      setSelectedIds([]);
    }
  };

  const handleSelectOne = (id: string, checked: boolean) => {
    if (checked) {
      setSelectedIds([...selectedIds, id]);
    } else {
      setSelectedIds(selectedIds.filter(i => i !== id));
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this activity?')) return;

    try {
      const res = await fetch(`/api/activities/${id}`, {
        method: 'DELETE',
      });
      
      if (res.ok) {
        fetchActivities();
        setOpenMenuId(null);
      } else {
        alert('Failed to delete activity');
      }
    } catch (error) {
      console.error('Failed to delete activity:', error);
      alert('Failed to delete activity');
    }
  };

  const handleBulkDelete = async () => {
    if (!confirm(`Delete ${selectedIds.length} activities?`)) return;

    try {
      await Promise.all(
        selectedIds.map(id =>
          fetch(`/api/activities/${id}`, { method: 'DELETE' })
        )
      );
      setSelectedIds([]);
      fetchActivities();
    } catch (error) {
      console.error('Failed to delete activities:', error);
    }
  };

  const handleTogglePublic = async (id: string, currentValue: boolean) => {
    const action = currentValue ? 'private' : 'public';
    if (!confirm(`Change this activity to ${action}?`)) return;

    try {
      const res = await fetch(`/api/activities/${id}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ isPublic: !currentValue }),
      });

      if (res.ok) {
        setActivities(prev =>
          prev.map(a =>
            a.activityId === id ? { ...a, isPublic: !currentValue } : a
          )
        );
      } else {
        alert('Failed to update visibility');
      }
    } catch (error) {
      console.error('Failed to toggle public:', error);
      alert('Failed to update visibility');
    }
  };

  const handleSearch = (value: string) => {
    setSearchQuery(value);
    setPage(1);
  };

  const toggleMenu = (id: string) => {
    setOpenMenuId(openMenuId === id ? null : id);
  };

  const getCategoryBadge = (category: string) => {
    const config: Record<string, { bg: string; text: string; label: string }> = {
      'ด้านภาษา': { bg: 'bg-yellow--light3', text: 'text-dark', label: 'Language' },
      'ด้านร่างกาย': { bg: 'bg-green--light6', text: 'text-green--dark', label: 'Physical' },
      'ด้านคำนวณ': { bg: 'bg-purple--light4', text: 'text-purple--dark', label: 'Calculate' },
    };
    const c = config[category] || { bg: 'bg-gray3', text: 'text-secondary--text', label: category };
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium whitespace-nowrap ${c.bg} ${c.text}`}>
        {c.label}
      </span>
    );
  };

  if (loading && activities.length === 0) {
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
            Activities &gt; Activity List
          </div>
          <h1 className="heading-h3">ACTIVITIES</h1>
        </div>
        <div className="flex items-center gap-4">
          <UserProfile />
          <Link href="/admin/activities/new">
            <button className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2">
              <Plus size={20} />
              Create
            </button>
          </Link>
        </div>
      </div>

      {/* Search & Filters */}
      <div className="mb-6 flex flex-wrap gap-4">
        <div className="relative flex-1 min-w-[250px] max-w-md">
          <Search
            className="absolute left-3 top-1/2 transform -translate-y-1/2 text-secondary--text"
            size={20}
          />
          <input
            type="text"
            placeholder="Search activities..."
            value={searchQuery}
            onChange={(e) => handleSearch(e.target.value)}
            className="w-full pl-10 pr-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        </div>

        <select
          value={categoryFilter}
          onChange={(e) => { setCategoryFilter(e.target.value); setPage(1); }}
          className="px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
        >
          <option value="">All Categories</option>
          <option value="ด้านภาษา">Language</option>
          <option value="ด้านร่างกาย">Physical</option>
          <option value="ด้านคำนวณ">Calculate</option>
        </select>
      </div>

      {/* Bulk Actions */}
      {selectedIds.length > 0 && (
        <div className="mb-4 flex items-center gap-4 bg-purple--light5 px-4 py-2 rounded-lg">
          <span className="body-medium-medium">{selectedIds.length} selected</span>
          <button
            onClick={handleBulkDelete}
            className="text-red hover:text-red--dark"
          >
            <Trash2 size={20} />
          </button>
        </div>
      )}

      {/* Table */}
      <div className="bg-white rounded-lg shadow overflow-x-auto">
        <table className="w-full min-w-[800px]">
          <thead className="bg-gray--light1 border-b border-gray4">
            <tr>
              <th className="w-10 px-3 py-3">
                <input
                  type="checkbox"
                  checked={selectedIds.length === activities.length && activities.length > 0}
                  onChange={(e) => handleSelectAll(e.target.checked)}
                  className="rounded"
                />
              </th>
              <th className="w-12 px-3 py-3 text-left body-small-medium text-secondary--text">No.</th>
              <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Activity Title</th>
              <th className="w-28 px-4 py-3 text-left body-small-medium text-secondary--text">Category</th>
              <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Description</th>
              <th className="w-28 px-4 py-3 text-left body-small-medium text-secondary--text whitespace-nowrap">Date Created</th>
              <th className="w-24 px-4 py-3 text-center body-small-medium text-secondary--text">Responses</th>
              <th className="w-24 px-4 py-3 text-center body-small-medium text-secondary--text">Public</th>
              <th className="w-12 px-3 py-3"></th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray4">
            {activities.length === 0 ? (
              <tr>
                <td colSpan={9} className="px-4 py-8 text-center body-medium-regular text-secondary--text">
                  No activities found
                </td>
              </tr>
            ) : (
              activities.map((activity, index) => (
                <tr
                  key={activity.activityId}
                  className={`hover:bg-gray--light1 ${
                    selectedIds.includes(activity.activityId) ? 'bg-purple--light5' : ''
                  }`}
                >
                  <td className="px-4 py-3">
                    <input
                      type="checkbox"
                      checked={selectedIds.includes(activity.activityId)}
                      onChange={(e) => handleSelectOne(activity.activityId, e.target.checked)}
                      className="rounded"
                    />
                  </td>
                  <td className="px-4 py-3 body-medium-regular">{(page - 1) * 10 + index + 1}</td>
                  <td className="px-4 py-3 body-medium-medium">{activity.nameActivity}</td>
                  <td className="px-4 py-3">
                    {getCategoryBadge(activity.category)}
                  </td>
                  <td className="px-4 py-3 body-medium-regular text-secondary--text max-w-[200px] truncate">
                    {activity.descriptionActivity || '-'}
                  </td>
                  <td className="px-4 py-3 body-medium-regular whitespace-nowrap">
                    {new Date(activity.createdAt).toLocaleDateString('en-US', {
                      day: 'numeric',
                      month: 'short',
                      year: 'numeric'
                    })}
                  </td>
                  <td className="px-4 py-3 body-medium-regular text-center">
                    {activity.responses || '-'}
                  </td>
                  <td className="px-4 py-3 text-center">
                    <button
                      onClick={() => handleTogglePublic(activity.activityId, activity.isPublic)}
                      className={`inline-flex items-center gap-1 px-2 py-1 rounded-full body-xs-medium transition-colors ${
                        activity.isPublic
                          ? 'bg-green--light6 text-green--dark hover:bg-green--light5'
                          : 'bg-gray3 text-secondary--text hover:bg-gray4'
                      }`}
                      title={activity.isPublic ? 'Click to make private' : 'Click to make public'}
                    >
                      {activity.isPublic ? <Globe size={14} /> : <Lock size={14} />}
                      {activity.isPublic ? 'Public' : 'Private'}
                    </button>
                  </td>
                  <td className="px-4 py-3">
                    <div className="relative" ref={openMenuId === activity.activityId ? menuRef : null}>
                      <button 
                        onClick={() => toggleMenu(activity.activityId)}
                        className="p-1 hover:bg-gray--light1 rounded"
                      >
                        <MoreVertical size={16} className="text-secondary--text" />
                      </button>
                      {openMenuId === activity.activityId && (
                        <div className="absolute right-0 top-full mt-1 bg-white border border-gray4 rounded-lg shadow-lg py-2 z-10">
                          <Link
                            href={`/admin/activities/${activity.activityId}`}
                            className="flex items-center gap-2 px-4 py-2 hover:bg-gray--light1 body-small-medium whitespace-nowrap"
                            onClick={() => setOpenMenuId(null)}
                          >
                            <Edit size={16} />
                            Edit
                          </Link>
                          <button
                            onClick={() => handleDelete(activity.activityId)}
                            className="flex items-center gap-2 px-4 py-2 hover:bg-gray--light1 body-small-medium text-red w-full text-left whitespace-nowrap"
                          >
                            <Trash2 size={16} />
                            Delete
                          </button>
                        </div>
                      )}
                    </div>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>

        {/* Pagination */}
        <div className="flex items-center justify-between px-6 py-4 border-t border-gray4">
          <div className="body-small-regular text-secondary--text">
            Showing {activities.length > 0 ? (page - 1) * 10 + 1 : 0} to {(page - 1) * 10 + activities.length} of {total} results
          </div>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Previous
            </button>
            {[...Array(Math.min(5, totalPages))].map((_, i) => {
              const pageNum = i + 1;
              return (
                <button
                  key={pageNum}
                  onClick={() => setPage(pageNum)}
                  className={`px-3 py-1 body-small-medium rounded ${
                    page === pageNum
                      ? 'bg-purple text-white'
                      : 'text-secondary--text hover:bg-gray--light1'
                  }`}
                >
                  {pageNum}
                </button>
              );
            })}
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-3 py-1 body-small-medium text-secondary--text hover:bg-gray--light1 rounded disabled:opacity-50 disabled:cursor-not-allowed"
            >
              Next
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}