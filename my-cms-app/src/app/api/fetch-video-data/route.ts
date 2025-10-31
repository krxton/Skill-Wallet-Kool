// src/app/api/fetch-video-data/route.ts

import { NextResponse } from 'next/server';
import { spawn, SpawnOptionsWithoutStdio } from 'child_process'; 

// Utility: ดึง Video ID จาก URL ของ YouTube (นำมาจาก frontend)
const extractYoutubeId = (url: string): string | null => {
    const regex = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})/i;
    const match = url.match(regex);
    return match ? match[1] : null;
};

// ฟังก์ชันหลักสำหรับรัน Python Script และรอผลลัพธ์
function runPythonScript(videoUrl: string): Promise<string> {
  return new Promise((resolve, reject) => {
    
    // 1. กำหนด Options โดยไม่มี Encoding (เพื่อแก้ไข Error 'encoding' does not exist)
    const options: SpawnOptionsWithoutStdio = {
      stdio: 'pipe', 
      // เนื่องจากเราใช้ Buffer เราไม่จำเป็นต้องส่ง encoding ไปที่ spawn
    };
    
    // 2. Spawn process โดยใช้ options ที่ถูกต้อง
    const pythonProcess = spawn('python', ['./scripts/fetch_subtitle.py', videoUrl], options);
    
    let result = '';
    let errorOutput = '';

    // 3. รวบรวมข้อมูลจาก stdout (ข้อมูลเป็น Buffer)
    // แก้ไข: ใช้ (data: Buffer) เพื่อกำหนด Type และเรียกใช้ toString('utf8')
    pythonProcess.stdout.on('data', (data: Buffer) => {
      // **บรรทัดสำคัญ:** แปลง Buffer เป็น String ด้วย UTF-8 encoding
      result += data.toString('utf8'); 
    });

    // 4. รวบรวม Error จาก stderr (ข้อมูลเป็น Buffer)
    // แก้ไข: ใช้ (data: Buffer) เพื่อกำหนด Type และเรียกใช้ toString('utf8')
    pythonProcess.stderr.on('data', (data: Buffer) => {
      errorOutput += data.toString('utf8');
    });
    
    // 5. เมื่อ Child Process ปิดตัว
    pythonProcess.on('close', (code: number) => { // แก้ไข: กำหนด Type code: number
      if (code !== 0) {
        // ถ้า exit code ไม่ใช่ 0 แสดงว่ามี Error
        return reject(new Error(`Python script exited with code ${code}. Error details: ${errorOutput || result}`));
      }
      // ถ้าไม่มี Error ใน stderr ให้ส่งผลลัพธ์ JSON ที่ได้จาก stdout กลับไป
      resolve(result);
    });

    // 6. จัดการ Error ในการรัน Process
    pythonProcess.on('error', (err: Error) => { // แก้ไข: กำหนด Type err: Error
      reject(new Error(`Failed to start python process. Check if 'python' is in your PATH. (${err.message})`));
    });
  });
}


// POST /api/fetch-video-data - โค้ดส่วนนี้ยังคงเหมือนเดิม
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