// src/app/api/fetch-video-data/route.ts

import { NextResponse } from 'next/server';
import { spawn, SpawnOptionsWithoutStdio } from 'child_process'; 

// Utility: ดึง Video ID จาก URL ของ YouTube
const extractYoutubeId = (url: string): string | null => {
    const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const match = url.match(regex);
    return match ? match[1] : null;
};

// ฟังก์ชันหลักสำหรับรัน Python Script และรอผลลัพธ์
function runPythonScript(videoUrl: string): Promise<string> {
  return new Promise((resolve, reject) => {
    
    const options: SpawnOptionsWithoutStdio = {
      stdio: 'pipe', 
    };
    
    const pythonProcess = spawn('python', ['./scripts/fetch_subtitle.py', videoUrl], options);
    
    let result = '';
    let errorOutput = '';

    pythonProcess.stdout.on('data', (data: Buffer) => {
      result += data.toString('utf8'); 
    });

    pythonProcess.stderr.on('data', (data: Buffer) => {
      errorOutput += data.toString('utf8');
    });
    
    pythonProcess.on('close', (code: number) => {
      if (code !== 0) {
        return reject(new Error(`Python script exited with code ${code}. Error details: ${errorOutput || result}`));
      }
      resolve(result);
    });

    pythonProcess.on('error', (err: Error) => {
      reject(new Error(`Failed to start python process. Check if 'python' is in your PATH. (${err.message})`));
    });
  });
}

/**
 * @swagger
 * /api/fetch-video-data:
 *   post:
 *     tags:
 *       - Activities
 *     summary: ดึงข้อมูลวิดีโอและ Subtitle จาก YouTube
 *     description: |
 *       ดึงข้อมูลวิดีโอจาก YouTube พร้อม subtitle/transcript
 *       
 *       **Features:**
 *       - ดึง Video Title, Description, Duration
 *       - ดึง Subtitle/Transcript (ภาษาไทยหรืออังกฤษ)
 *       - รองรับทั้ง Auto-generated และ Manual subtitles
 *       - ใช้ Python script (youtube-transcript-api)
 *       
 *       **Supported URL Formats:**
 *       - `https://www.youtube.com/watch?v=VIDEO_ID`
 *       - `https://youtu.be/VIDEO_ID`
 *       - `https://www.youtube.com/embed/VIDEO_ID`
 *       
 *       **Requirements:**
 *       - Python ต้องติดตั้งในระบบ
 *       - Python script: `./scripts/fetch_subtitle.py`
 *       - Package: `youtube-transcript-api`
 *       
 *       **Use Case:**
 *       - สร้างกิจกรรมจากวิดีโอ YouTube
 *       - ดึง transcript มาสร้างคำถาม
 *       - แสดงข้อมูลวิดีโอในระบบ
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - videoUrl
 *             properties:
 *               videoUrl:
 *                 type: string
 *                 description: YouTube Video URL
 *                 example: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
 *           examples:
 *             standardUrl:
 *               summary: YouTube URL มาตรฐาน
 *               value:
 *                 videoUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
 *             shortUrl:
 *               summary: YouTube Short URL
 *               value:
 *                 videoUrl: "https://youtu.be/dQw4w9WgXcQ"
 *             embedUrl:
 *               summary: YouTube Embed URL
 *               value:
 *                 videoUrl: "https://www.youtube.com/embed/dQw4w9WgXcQ"
 *     responses:
 *       200:
 *         description: ดึงข้อมูลสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 videoId:
 *                   type: string
 *                   description: YouTube Video ID
 *                   example: "dQw4w9WgXcQ"
 *                 title:
 *                   type: string
 *                   description: ชื่อวิดีโอ
 *                   example: "Rick Astley - Never Gonna Give You Up"
 *                 description:
 *                   type: string
 *                   description: คำอธิบายวิดีโอ
 *                   example: "Official music video for Never Gonna Give You Up..."
 *                 duration:
 *                   type: string
 *                   description: ความยาววิดีโอ (รูปแบบ MM:SS หรือ HH:MM:SS)
 *                   example: "3:32"
 *                 thumbnailUrl:
 *                   type: string
 *                   description: URL รูปภาพ thumbnail
 *                   example: "https://i.ytimg.com/vi/dQw4w9WgXcQ/maxresdefault.jpg"
 *                 channelName:
 *                   type: string
 *                   description: ชื่อช่อง YouTube
 *                   example: "Rick Astley"
 *                 viewCount:
 *                   type: integer
 *                   description: จำนวนการดู
 *                   example: 1234567890
 *                 publishedAt:
 *                   type: string
 *                   format: date-time
 *                   description: วันที่เผยแพร่วิดีโอ
 *                   example: "2009-10-25T06:57:33Z"
 *                 transcript:
 *                   type: array
 *                   description: รายการ subtitle/transcript
 *                   items:
 *                     type: object
 *                     properties:
 *                       text:
 *                         type: string
 *                         description: ข้อความ subtitle
 *                         example: "Never gonna give you up"
 *                       start:
 *                         type: number
 *                         description: เวลาเริ่มต้น (วินาที)
 *                         example: 0.5
 *                       duration:
 *                         type: number
 *                         description: ระยะเวลาที่แสดง (วินาที)
 *                         example: 2.3
 *                 transcriptLanguage:
 *                   type: string
 *                   description: ภาษาของ transcript
 *                   example: "en"
 *                 fullTranscriptText:
 *                   type: string
 *                   description: ข้อความ transcript เต็ม (รวมกันทั้งหมด)
 *                   example: "Never gonna give you up Never gonna let you down..."
 *             examples:
 *               withThaiSubtitle:
 *                 summary: วิดีโอที่มี Subtitle ภาษาไทย
 *                 value:
 *                   videoId: "abc123xyz"
 *                   title: "เรียนรู้ตัวเลข 1-10"
 *                   description: "วิดีโอสอนนับเลขสำหรับเด็กเล็ก"
 *                   duration: "5:30"
 *                   thumbnailUrl: "https://i.ytimg.com/vi/abc123xyz/maxresdefault.jpg"
 *                   channelName: "เรียนรู้สนุก"
 *                   viewCount: 50000
 *                   publishedAt: "2023-01-15T10:00:00Z"
 *                   transcript:
 *                     - text: "หนึ่ง สอง สาม"
 *                       start: 0.5
 *                       duration: 2.0
 *                     - text: "สี่ ห้า หก"
 *                       start: 2.5
 *                       duration: 2.0
 *                   transcriptLanguage: "th"
 *                   fullTranscriptText: "หนึ่ง สอง สาม สี่ ห้า หก..."
 *               withEnglishSubtitle:
 *                 summary: วิดีโอที่มี Subtitle อังกฤษ
 *                 value:
 *                   videoId: "xyz789abc"
 *                   title: "Learn Numbers 1-10"
 *                   description: "Educational video for counting numbers"
 *                   duration: "4:15"
 *                   thumbnailUrl: "https://i.ytimg.com/vi/xyz789abc/maxresdefault.jpg"
 *                   channelName: "Kids Learning"
 *                   viewCount: 100000
 *                   publishedAt: "2023-02-20T14:30:00Z"
 *                   transcript:
 *                     - text: "One, two, three"
 *                       start: 1.0
 *                       duration: 1.5
 *                     - text: "Four, five, six"
 *                       start: 2.5
 *                       duration: 1.5
 *                   transcriptLanguage: "en"
 *                   fullTranscriptText: "One, two, three. Four, five, six..."
 *       400:
 *         description: Bad Request - URL ไม่ถูกต้องหรือไม่พบ Video ID
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               invalidUrl:
 *                 summary: URL ไม่ถูกต้อง
 *                 value:
 *                   error: "Invalid YouTube URL or Video ID not found."
 *               noSubtitles:
 *                 summary: วิดีโอไม่มี Subtitle
 *                 value:
 *                   error: "No subtitles available for this video."
 *               videoNotFound:
 *                 summary: ไม่พบวิดีโอ
 *                 value:
 *                   error: "Video not found or unavailable."
 *               privateVideo:
 *                 summary: วิดีโอเป็น Private
 *                 value:
 *                   error: "Video is private or restricted."
 *       500:
 *         description: Internal Server Error
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               pythonNotFound:
 *                 summary: ไม่พบ Python
 *                 value:
 *                   error: "Fetch Error: Failed to start python process. Check if 'python' is in your PATH."
 *               scriptError:
 *                 summary: Python script error
 *                 value:
 *                   error: "Fetch Error: Python script exited with code 1. Error details: ModuleNotFoundError: No module named 'youtube_transcript_api'"
 *               jsonParseError:
 *                 summary: JSON parsing error
 *                 value:
 *                   error: "Fetch Error: Unexpected token in JSON at position 0"
 *               networkError:
 *                 summary: Network error
 *                 value:
 *                   error: "Fetch Error: Network connection failed"
 */
export async function POST(request: Request) {
    try {
        const { videoUrl } = await request.json();

        const videoId = extractYoutubeId(videoUrl);
        
        if (!videoUrl || !videoId) {
            return NextResponse.json({ error: 'Invalid YouTube URL or Video ID not found.' }, { status: 400 });
        }

        const jsonString = await runPythonScript(videoUrl);
        const data = JSON.parse(jsonString);

        if (data.error) {
            return NextResponse.json({ error: data.error }, { status: 400 });
        }

        return NextResponse.json(data);

    } catch (error) {
        console.error('Error in fetching video data:', error);
        return NextResponse.json({ error: `Fetch Error: ${error instanceof Error ? error.message : String(error)}` }, { status: 500 });
    }
}