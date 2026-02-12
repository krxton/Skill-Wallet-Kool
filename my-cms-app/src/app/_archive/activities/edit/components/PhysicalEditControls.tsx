'use client';

import React from 'react';

// =======================================================
// INTERFACES & UTILITIES
// =======================================================

interface PhysicalControlsProps {
  // รับ videoUrl (ฉบับเต็ม) มาจาก EditForm
  videoUrl: string | null | undefined;
}

// Utility: ดึง Video ID และ Type (รองรับ YouTube และ TikTok)
const extractVideoInfo = (url: string | null | undefined) => {
  if (!url) {
    return { id: null, type: null };
  }

  // 1. YouTube ID extraction
  const youtubeRegex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
  const youtubeMatch = url.match(youtubeRegex);
  if (youtubeMatch) {
    return { id: youtubeMatch[1], type: 'youtube' };
  }

  // 2. TikTok ID extraction
  const tiktokRegex = /(?:tiktok\.com\/.*\/video\/|tiktok\.com\/v\/|vt\.tiktok\.com\/.*\/)(\d+)/i;
  const tiktokMatch = url.match(tiktokRegex);
  if (tiktokMatch) {
    return { id: tiktokMatch[1], type: 'tiktok' }; // ID TikTok (ตัวเลข)
  }

  return { id: null, type: null };
};


// =======================================================
// MAIN COMPONENT
// =======================================================

export default function PhysicalEditControls({ videoUrl }: PhysicalControlsProps) {

  // RENDER UTILITY: แสดงผลวิดีโอ (ย้ายมาจาก EditForm)
  const renderEmbeddedVideo = () => {
    const videoInfo = extractVideoInfo(videoUrl);

    if (!videoInfo.id) {
      return (
        <div className="text-center p-4 bg-gray-100 rounded-md">
          <p className="body-medium-regular text-gray-500">No valid YouTube or TikTok URL found for preview.</p>
        </div>
      );
    }

    const containerStyle = "max-w-md mx-auto border border-gray-300 rounded-lg overflow-hidden";

    if (videoInfo.type === 'tiktok') {
      // TikTok: 3:4 Vertical
      const verticalStyle = "relative w-full pb-[133.33%]";
      const embedUrl = `https://www.tiktok.com/embed/v2/${videoInfo.id}`;

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
            src={`https://www.youtube.com/embed/${videoInfo.id}`}
            allowFullScreen
            title="Embedded YouTube Video"
          />
        </div>
      );
    }
  };

  return (
    // นี่คือ JSX ที่ย้ายมาจาก EditForm (Video Information)
    <div className="border border-gray-300 p-6 rounded-lg bg-gray-50 space-y-4">
      <h3 className="heading-h5 mb-4 text-gray-700">Video Information (Physical)</h3>

      <label className="body-medium-semibold text-gray-700 block">YouTube/TikTok URL</label>
      <input
        type="url"
        name="videoUrl"
        value={videoUrl || ''}
        // Input นี้ disabled เสมอในหน้า Edit (เพราะ URL มาจากหน้า Create)
        className="input w-full bg-gray-200"
        disabled 
      />

      {/* Embedded Video Preview */}
      <div className='mt-4'>
        {renderEmbeddedVideo()}
      </div>
    </div>
  );
}

