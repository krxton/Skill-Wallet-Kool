// app/admin/activities/[id]/page.tsx
'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { ArrowLeft, Edit2, Save, X, Video, FileText, BarChart3, Users, Calendar, Award } from 'lucide-react';

interface ActivityRecord {
  id: string;
  childName: string;
  scoreEarned: number;
  dateCompleted: string;
  status: string;
}

interface ActivityDetail {
  activityId: string;
  nameActivity: string;
  category: string;
  descriptionActivity: string;
  difficulty: string;
  maxScore: number;
  videoUrl?: string;
  content: string;
  segments?: any;
  createdAt: string;
  updatedAt: string;
  responses: number;
  recentRecords?: ActivityRecord[];
}

export default function ActivityDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [activity, setActivity] = useState<ActivityDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editForm, setEditForm] = useState<Partial<ActivityDetail>>({});
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (params.id) {
      fetchActivityDetail();
    }
  }, [params.id]);

  const fetchActivityDetail = async () => {
    try {
      const res = await fetch(`/api/activities/${params.id}`);
      if (res.ok) {
        const data = await res.json();
        setActivity(data);
        setEditForm(data);
      } else {
        console.error('Activity not found');
      }
    } catch (error) {
      console.error('Failed to fetch activity:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = () => {
    setIsEditing(true);
  };

  const handleCancel = () => {
    setIsEditing(false);
    setEditForm(activity || {});
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const res = await fetch(`/api/activities/${params.id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          name: editForm.nameActivity,
          category: editForm.category,
          description: editForm.descriptionActivity,
          difficulty: editForm.difficulty,
          maxScore: editForm.maxScore,
          videoUrl: editForm.videoUrl,
          content: editForm.content,
        }),
      });

      if (res.ok) {
        const data = await res.json();
        setActivity(data);
        setIsEditing(false);
        alert('Activity updated successfully!');
      } else {
        alert('Failed to update activity');
      }
    } catch (error) {
      console.error('Failed to update activity:', error);
      alert('Failed to update activity');
    } finally {
      setSaving(false);
    }
  };

  const getDifficultyBadge = (difficulty: string) => {
    const colors: { [key: string]: string } = {
      'Easy': 'bg-green--light6 text-green--dark',
      'Medium': 'bg-yellow--light3 text-dark',
      'Hard': 'bg-red--light6 text-red--dark',
    };
    return (
      <span className={`inline-flex items-center px-3 py-1 rounded-full body-small-medium ${colors[difficulty] || 'bg-gray3 text-secondary--text'}`}>
        {difficulty}
      </span>
    );
  };

  const getStatusBadge = (status: string) => {
    const colors: { [key: string]: string } = {
      'Completed': 'bg-green--light6 text-green--dark',
      'Pending': 'bg-yellow--light3 text-dark',
      'Failed': 'bg-red--light6 text-red--dark',
    };
    return (
      <span className={`inline-flex items-center px-2 py-1 rounded-full body-xs-medium ${colors[status] || 'bg-gray3 text-secondary--text'}`}>
        {status}
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

  if (!activity) {
    return (
      <div className="p-8">
        <div className="bg-white rounded-lg shadow p-12 text-center">
          <div className="body-large-medium text-secondary--text mb-2">
            Activity not found
          </div>
          <button 
            onClick={() => router.push('/admin/activities')}
            className="btn-primary px-4 py-2 rounded-lg mt-4"
          >
            Back to Activities
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="p-8">
      {/* Header */}
      <div className="mb-6">
        <button 
          onClick={() => router.push('/admin/activities')}
          className="flex items-center gap-2 body-medium-medium text-purple hover:text-purple--dark mb-4"
        >
          <ArrowLeft size={20} />
          Back to Activities
        </button>
        <div className="flex items-center justify-between">
          <div>
            <div className="body-small-regular text-secondary--text mb-1">
              Activities &gt; Activity Detail
            </div>
            <h1 className="heading-h3">ACTIVITY DETAIL</h1>
          </div>
          <div className="flex items-center gap-3">
            {!isEditing ? (
              <button 
                onClick={handleEdit}
                className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2"
              >
                <Edit2 size={20} />
                Edit
              </button>
            ) : (
              <>
                <button 
                  onClick={handleCancel}
                  className="btn-white px-4 py-2 rounded-lg flex items-center gap-2"
                  disabled={saving}
                >
                  <X size={20} />
                  Cancel
                </button>
                <button 
                  onClick={handleSave}
                  className="btn-primary px-4 py-2 rounded-lg flex items-center gap-2"
                  disabled={saving}
                >
                  <Save size={20} />
                  {saving ? 'Saving...' : 'Save'}
                </button>
              </>
            )}
          </div>
        </div>
      </div>

      {/* Main Info Card */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-6">
          {/* Statistics */}
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-purple--light5 flex items-center justify-center">
              <Users size={24} className="text-purple" />
            </div>
            <div>
              <div className="body-xs-regular text-secondary--text">Total Responses</div>
              <div className="heading-h5">{activity.responses}</div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-yellow--light3 flex items-center justify-center">
              <Award size={24} className="text-dark" />
            </div>
            <div>
              <div className="body-xs-regular text-secondary--text">Max Score</div>
              <div className="heading-h5">{activity.maxScore}</div>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-lg bg-cyan--light3 flex items-center justify-center">
              <Calendar size={24} className="text-purple--dark" />
            </div>
            <div>
              <div className="body-xs-regular text-secondary--text">Created</div>
              <div className="body-medium-medium">
                {new Date(activity.createdAt).toLocaleDateString('en-US', {
                  day: 'numeric',
                  month: 'short',
                  year: 'numeric'
                })}
              </div>
            </div>
          </div>
        </div>

        {/* Activity Details */}
        <div className="space-y-4">
          {/* Activity Name */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Activity Name</label>
            {isEditing ? (
              <input
                type="text"
                value={editForm.nameActivity || ''}
                onChange={(e) => setEditForm({ ...editForm, nameActivity: e.target.value })}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              <div className="heading-h5">{activity.nameActivity}</div>
            )}
          </div>

          {/* Category and Difficulty */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="body-small-medium text-secondary--text mb-2 block">Category</label>
              {isEditing ? (
                <input
                  type="text"
                  value={editForm.category || ''}
                  onChange={(e) => setEditForm({ ...editForm, category: e.target.value })}
                  className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                />
              ) : (
                <div className="body-medium-medium">{activity.category}</div>
              )}
            </div>

            <div>
              <label className="body-small-medium text-secondary--text mb-2 block">Difficulty</label>
              {isEditing ? (
                <select
                  value={editForm.difficulty || ''}
                  onChange={(e) => setEditForm({ ...editForm, difficulty: e.target.value })}
                  className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
                >
                  <option value="Easy">Easy</option>
                  <option value="Medium">Medium</option>
                  <option value="Hard">Hard</option>
                </select>
              ) : (
                getDifficultyBadge(activity.difficulty)
              )}
            </div>
          </div>

          {/* Max Score */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Max Score</label>
            {isEditing ? (
              <input
                type="number"
                value={editForm.maxScore || 0}
                onChange={(e) => setEditForm({ ...editForm, maxScore: parseInt(e.target.value) })}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              <div className="body-medium-medium">{activity.maxScore} points</div>
            )}
          </div>

          {/* Description */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Description</label>
            {isEditing ? (
              <textarea
                value={editForm.descriptionActivity || ''}
                onChange={(e) => setEditForm({ ...editForm, descriptionActivity: e.target.value })}
                rows={4}
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              <div className="body-medium-regular text-secondary--text">{activity.descriptionActivity}</div>
            )}
          </div>

          {/* Video URL */}
          <div>
            <label className="body-small-medium text-secondary--text mb-2 block">Video URL</label>
            {isEditing ? (
              <input
                type="url"
                value={editForm.videoUrl || ''}
                onChange={(e) => setEditForm({ ...editForm, videoUrl: e.target.value })}
                placeholder="https://..."
                className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
              />
            ) : (
              activity.videoUrl ? (
                <a href={activity.videoUrl} target="_blank" rel="noopener noreferrer" className="flex items-center gap-2 text-purple hover:text-purple--dark body-medium-medium">
                  <Video size={16} />
                  {activity.videoUrl}
                </a>
              ) : (
                <div className="body-medium-regular text-secondary--text">No video URL</div>
              )
            )}
          </div>
        </div>
      </div>

      {/* Content Section */}
      <div className="bg-white rounded-lg shadow p-6 mb-6">
        <div className="flex items-center gap-2 mb-4">
          <FileText size={24} className="text-purple" />
          <h3 className="heading-h5">Content</h3>
        </div>
        {isEditing ? (
          <textarea
            value={editForm.content || ''}
            onChange={(e) => setEditForm({ ...editForm, content: e.target.value })}
            rows={8}
            className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        ) : (
          <div className="body-medium-regular whitespace-pre-wrap">{activity.content}</div>
        )}
      </div>

      {/* Recent Records Section */}
      {activity.recentRecords && activity.recentRecords.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6">
          <div className="flex items-center gap-2 mb-4">
            <BarChart3 size={24} className="text-purple" />
            <h3 className="heading-h5">Recent Activity Records</h3>
          </div>
          
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray--light1 border-b border-gray4">
                <tr>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">No.</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Child Name</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Score Earned</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Date Completed</th>
                  <th className="px-4 py-3 text-left body-small-medium text-secondary--text">Status</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray4">
                {activity.recentRecords.map((record, index) => (
                  <tr key={record.id} className="hover:bg-gray--light1">
                    <td className="px-4 py-3 body-medium-regular">{index + 1}</td>
                    <td className="px-4 py-3 body-medium-medium">{record.childName}</td>
                    <td className="px-4 py-3 body-medium-bold text-purple">{record.scoreEarned}/{activity.maxScore}</td>
                    <td className="px-4 py-3 body-medium-regular">
                      {new Date(record.dateCompleted).toLocaleDateString('en-US', {
                        day: 'numeric',
                        month: 'short',
                        year: 'numeric'
                      })}
                    </td>
                    <td className="px-4 py-3">{getStatusBadge(record.status)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}