// src/app/api/get-direct-url/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { exec } from 'child_process';
import { promisify } from 'util';

const execAsync = promisify(exec);

const corsHeaders = {
    'Access-Control-Allow-Origin': 'http://192.168.1.58:3000',
    'Access-Control-Allow-Methods': 'GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
};

export async function GET(request: NextRequest) {
    const errorCorsHeaders = {
        'Access-Control-Allow-Origin': corsHeaders['Access-Control-Allow-Origin'],
    };

    const { searchParams } = new URL(request.url);
    const videoUrl = searchParams.get('url');
    const quality = searchParams.get('quality') || '1080'; // รับค่าความละเอียดที่ต้องการ

    if (!videoUrl) {
        return NextResponse.json(
            { error: 'Missing video URL.' },
            { status: 400, headers: errorCorsHeaders }
        );
    }

    try {
        const ytDlpPath = 'C:\\Users\\higan\\AppData\\Roaming\\Python\\Python313\\Scripts\\yt-dlp.exe';
        
        // 🔥 SOLUTION: ใช้ format ที่รวมเสียงแล้ว (pre-merged formats)
        // Format 22 = 720p HD + audio (ใช้ได้กับ YouTube ส่วนใหญ่)
        // Format 18 = 360p + audio (fallback)
        // best = fallback สุดท้าย
        const formatSelector = '22/18/best';
        
        // 🔥 ใช้ -g เพื่อดึง URL โดยตรง (ไม่ต้อง parse JSON)
        const command = `"${ytDlpPath}" -f "${formatSelector}" -g --no-warnings "${videoUrl}"`;
        
        console.log('🎬 Executing:', command);
        
        const { stdout, stderr } = await execAsync(command, {
            maxBuffer: 1024 * 1024 * 10,
            timeout: 30000,
        });

        console.log('📦 stdout:', stdout);
        console.log('⚠️  stderr:', stderr);

        if (!stdout || stdout.trim() === '') {
            console.error('❌ Empty stdout from yt-dlp');
            return NextResponse.json(
                { 
                    error: 'No data returned from yt-dlp',
                    stderr: stderr 
                },
                { status: 500, headers: errorCorsHeaders }
            );
        }

        // 🔥 -g จะคืน URL โดยตรง (format 22/18 จะได้ 1 บรรทัดเสมอ = รวมเสียงแล้ว)
        const directUrl = stdout.trim();
        
        if (!directUrl.startsWith('http')) {
            console.error('❌ Invalid URL format');
            return NextResponse.json(
                { 
                    error: 'Invalid URL from yt-dlp',
                    output: stdout 
                },
                { status: 500, headers: errorCorsHeaders }
            );
        }

        console.log('✅ Got direct URL (with audio)');
        console.log('📺 Video URL:', directUrl.substring(0, 80) + '...');

        // ดึง duration จาก metadata
        const durationCommand = `"${ytDlpPath}" --dump-json --no-warnings "${videoUrl}"`;
        const { stdout: metadataJson } = await execAsync(durationCommand, {
            maxBuffer: 1024 * 1024 * 10,
            timeout: 30000,
        });

        const lines = metadataJson.trim().split('\n');
        const jsonLine = lines.find(line => line.trim().startsWith('{'));
        const metadata = jsonLine ? JSON.parse(jsonLine) : {};
        const duration = metadata.duration || 0;
        const actualHeight = metadata.height || 0;

        console.log(`✅ Video ready - Duration: ${duration}s, Quality: ${actualHeight}p (with audio)`);

        return NextResponse.json(
            {
                directUrl: directUrl,
                duration: duration,
                quality: actualHeight,
                hasAudio: true,
                format: 'merged' // รวมเสียงแล้ว
            },
            { headers: corsHeaders }
        );

    } catch (error: any) {
        console.error('❌ yt-dlp error:', error);
        
        if (error.code === 'ETIMEDOUT') {
            return NextResponse.json(
                {
                    error: 'Request timeout',
                    details: 'yt-dlp took too long to respond'
                },
                { status: 504, headers: errorCorsHeaders }
            );
        }

        return NextResponse.json(
            {
                error: 'Failed to fetch video data from source.',
                details: error.message,
                stderr: error.stderr,
                stdout: error.stdout
            },
            { status: 500, headers: errorCorsHeaders }
        );
    }
}

export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, { headers: corsHeaders });
}