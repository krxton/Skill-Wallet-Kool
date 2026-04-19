import { NextRequest, NextResponse } from 'next/server';

/**
 * POST /api/tiktok-oembed
 * Proxy TikTok oEmbed API to avoid CORS issues from Flutter client.
 *
 * Body: { videoUrl: string }
 * Response: { thumbnailUrl, html, title, authorName }
 */
export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { videoUrl } = body;

    if (!videoUrl) {
      return NextResponse.json(
        { error: 'videoUrl is required' },
        { status: 400 }
      );
    }

    // Resolve short URLs (e.g. vt.tiktok.com/XXXXX/) by following redirects
    let resolvedUrl = videoUrl.split('?')[0];
    if (!resolvedUrl.includes('/video/')) {
      try {
        const headRes = await fetch(resolvedUrl, { method: 'HEAD', redirect: 'follow' });
        if (headRes.url && headRes.url.includes('/video/')) {
          resolvedUrl = headRes.url.split('?')[0];
        }
      } catch {
        // keep original if resolve fails
      }
    }

    const oEmbedUrl = `https://www.tiktok.com/oembed?url=${encodeURIComponent(resolvedUrl)}&maxwidth=600&maxheight=800`;

    const response = await fetch(oEmbedUrl);

    if (!response.ok) {
      return NextResponse.json(
        { error: `TikTok oEmbed returned ${response.status}` },
        { status: 502 }
      );
    }

    const data = await response.json();

    return NextResponse.json({
      thumbnailUrl: data.thumbnail_url || '',
      html: data.html || '',
      title: data.title || '',
      authorName: data.author_name || '',
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to fetch TikTok oEmbed', details: err.message },
      { status: 500 }
    );
  }
}
