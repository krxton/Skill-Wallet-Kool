// app/admin/activities/new/page.tsx
'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Save, Send } from 'lucide-react';

// Types
interface Segment {
  id: string;
  start: number;
  end: number;
  text: string;
}

interface ActivityFormData {
  name: string;
  category: string;
  content: string;
  difficulty: string;
  maxScore: number;
  description: string;
  videoUrl: string;
  segments: Segment[] | null;
  parentId: string; // Required by API
}

export default function NewActivityPage() {
  const router = useRouter();
  const [formData, setFormData] = useState<ActivityFormData>({
    name: '',
    category: 'Language',
    content: '',
    difficulty: 'easy',
    maxScore: 100,
    description: '',
    videoUrl: '',
    segments: null,
    parentId: '', // TODO: Get from session/auth
  });
  const [videoId, setVideoId] = useState<string | null>(null);
  const [isFetching, setIsFetching] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Extract video ID from URL
  const extractVideoId = (url: string): string | null => {
    // YouTube
    const youtubeRegex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const youtubeMatch = url.match(youtubeRegex);
    if (youtubeMatch) return youtubeMatch[1];

    // TikTok
    const tiktokRegex = /(?:tiktok\.com\/(?:@[\w.]+\/video\/|v\/|t\/)|vt\.tiktok\.com\/.*\/)(\d+)/i;
    const tiktokMatch = url.match(tiktokRegex);
    if (tiktokMatch) return tiktokMatch[1];

    return null;
  };

  // Handle input changes
  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>
  ) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: name === 'maxScore' ? parseInt(value) || 0 : value
    }));

    if (name === 'videoUrl') {
      const id = extractVideoId(value);
      setVideoId(id);
    }
  };

  // Fetch video data (for Language activities with subtitles)
  const handleFetch = async () => {
    if (!formData.videoUrl) {
      alert('Please enter a video URL first');
      return;
    }

    const id = extractVideoId(formData.videoUrl);
    if (!id) {
      alert('Invalid video URL. Please provide a valid YouTube or TikTok link.');
      return;
    }

    setIsFetching(true);

    try {
      const response = await fetch('/api/fetch-video-data', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ videoUrl: formData.videoUrl })
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to fetch video data');
      }

      const data = await response.json();

      // Add unique IDs to segments
      const segmentsWithIds = data.segments?.map((seg: any, idx: number) => ({
        id: `seg_${Date.now()}_${idx}`,
        start: seg.start,
        end: seg.end,
        text: seg.text
      })) || [];

      setFormData(prev => ({
        ...prev,
        name: data.title || prev.name,
        description: data.description || prev.description,
        segments: segmentsWithIds.length > 0 ? segmentsWithIds : null,
        content: data.videoId ? `Video Source: YouTube ID ${data.videoId}` : prev.content
      }));

      alert('Video data fetched successfully!');
    } catch (error) {
      console.error('Fetch error:', error);
      alert(`Error: ${error instanceof Error ? error.message : 'Failed to fetch video data'}`);
    } finally {
      setIsFetching(false);
    }
  };

  // Save as draft
  const handleSaveDraft = async () => {
    // TODO: Implement save draft functionality
    alert('Save Draft functionality coming soon!');
  };

  // Publish activity
  const handlePublish = async (e: React.FormEvent) => {
    e.preventDefault();

    // Validation
    if (!formData.name.trim()) {
      alert('Please enter an activity title');
      return;
    }

    if (!formData.description.trim()) {
      alert('Please enter an activity description');
      return;
    }

    if (!formData.parentId) {
      // TODO: Get from session
      alert('Parent ID is required. Please ensure you are logged in.');
      return;
    }

    setIsSubmitting(true);

    try {
      const response = await fetch('/api/activities', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create activity');
      }

      alert('Activity created successfully!');
      router.push('/admin/activities');
    } catch (error) {
      console.error('Submit error:', error);
      alert(`Error: ${error instanceof Error ? error.message : 'Failed to create activity'}`);
    } finally {
      setIsSubmitting(false);
    }
  };

  // Format segments for display
  const getSegmentsText = () => {
    if (!formData.segments || formData.segments.length === 0) {
      return '';
    }
    return formData.segments
      .map(seg => `[${seg.start}s - ${seg.end}s] ${seg.text}`)
      .join('\n');
  };

  return (
    <div className="p-8 max-w-4xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <div className="body-small-regular text-secondary--text mb-1">
            Activities &gt; Activities List &gt; Create
          </div>
          <h1 className="heading-h3">Create New Activity</h1>
        </div>
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={handleSaveDraft}
            className="flex items-center gap-2 px-4 py-2 border border-gray6 rounded-lg body-medium-medium text-secondary--text hover:bg-gray--light1"
          >
            <Save size={20} />
            Save Draft
          </button>
          <button
            type="button"
            onClick={handlePublish}
            disabled={isSubmitting}
            className="flex items-center gap-2 px-4 py-2 bg-purple text-white rounded-lg body-medium-medium hover:bg-purple--dark disabled:bg-gray6"
          >
            <Send size={20} />
            {isSubmitting ? 'Publishing...' : 'Publish'}
          </button>
        </div>
      </div>

      {/* Form */}
      <form onSubmit={handlePublish} className="space-y-6">
        {/* Video Information */}
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <h3 className="body-large-semibold text-gray-800">Video Information <span className="text-red">*</span></h3>
          <p className="body-small-regular text-secondary--text">
            To begin, please provide a link to a YouTube or TikTok video. The system will automatically fetch basic video details or transcripts.
          </p>
          
          <div className="flex gap-3">
            <input
              type="text"
              name="videoUrl"
              value={formData.videoUrl}
              onChange={handleChange}
              placeholder="Paste your video link here..."
              className="flex-1 px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
            />
            <button
              type="button"
              onClick={handleFetch}
              disabled={isFetching || !videoId}
              className="px-6 py-2 bg-gray--light1 text-secondary--text rounded-lg body-medium-medium hover:bg-gray3 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isFetching ? 'Fetching...' : 'Fetch'}
            </button>
          </div>
        </div>

        {/* Activity Title */}
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <label className="body-large-semibold text-gray-800">
            Activity Title <span className="text-red">*</span>
          </label>
          <p className="body-small-regular text-secondary--text">
            Activity title is the title that users will actually see when they choose an activities.
          </p>
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleChange}
            placeholder="Activity Title"
            required
            className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          />
        </div>

        {/* Activities Description */}
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <label className="body-large-semibold text-gray-800">
            Activities Description
          </label>
          <p className="body-small-regular text-secondary--text">
            A description should have minimum of 255 words.
          </p>
          <textarea
            name="description"
            value={formData.description}
            onChange={handleChange}
            placeholder="Activities Description"
            rows={5}
            className="w-full px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple resize-none"
          />
        </div>

        {/* Category and Video Preview */}
        <div className="bg-white rounded-lg shadow p-6 space-y-4">
          <label className="body-large-semibold text-gray-800">Category</label>
          
          <select
            name="category"
            value={formData.category}
            onChange={handleChange}
            className="w-full max-w-xs px-4 py-2 border border-gray6 rounded-lg body-medium-regular focus:outline-none focus:ring-2 focus:ring-purple"
          >
            <option value="Language">Language</option>
            <option value="Physical">Physical</option>
            <option value="Analytical">Analytical</option>
          </select>

          {/* Video Preview */}
          {videoId && (
            <div className="mt-4 bg-gray--light1 rounded-lg p-4">
              <div className="aspect-video w-full max-w-2xl mx-auto bg-black rounded-lg overflow-hidden">
                <iframe
                  width="100%"
                  height="100%"
                  src={`https://www.youtube.com/embed/${videoId}`}
                  allowFullScreen
                  title="Video Preview"
                  className="w-full h-full"
                />
              </div>
            </div>
          )}
        </div>

        {/* Segment Subtitle */}
        {formData.segments && formData.segments.length > 0 && (
          <div className="bg-white rounded-lg shadow p-6 space-y-4">
            <label className="body-large-semibold text-gray-800">
              Segment Subtitle
            </label>
            <p className="body-small-regular text-secondary--text">
              Fetched {formData.segments.length} subtitle segments from video.
            </p>
            <textarea
              value={getSegmentsText()}
              readOnly
              rows={8}
              className="w-full px-4 py-2 border border-gray6 rounded-lg body-small-regular bg-gray--light1 resize-none"
            />
          </div>
        )}

        {/* Additional Fields (Hidden but included in submission) */}
        <input type="hidden" name="content" value={formData.content} />
        <input type="hidden" name="difficulty" value={formData.difficulty} />
        <input type="hidden" name="maxScore" value={formData.maxScore} />
        <input type="hidden" name="parentId" value={formData.parentId} />
      </form>
    </div>
  );
}