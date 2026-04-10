// api/parents/photo/route.ts
// อัปโหลดรูปโปรไฟล์ของ parent ไปยัง MinIO
// แล้วอัปเดต image field ใน ba_user

import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { uploadToMinio } from '@/lib/minio';
import { prisma } from '@/lib/prisma';

export async function POST(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if ('error' in auth) {
    return NextResponse.json({ error: auth.error }, { status: 401 });
  }
  const { user } = auth;

  const formData = await request.formData();
  const file = formData.get('photo') as File | null;

  if (!file) {
    return NextResponse.json({ error: 'photo field is required' }, { status: 400 });
  }

  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!allowedTypes.includes(file.type)) {
    return NextResponse.json(
      { error: 'Unsupported file type. Use JPEG, PNG or WebP.' },
      { status: 400 },
    );
  }

  const MAX_SIZE = 5 * 1024 * 1024;
  if (file.size > MAX_SIZE) {
    return NextResponse.json({ error: 'File too large (max 5 MB)' }, { status: 400 });
  }

  try {
    const bytes = await file.arrayBuffer();
    const buffer = new Uint8Array(bytes);

    // path: parents/{userId}/profile.jpg (overwrites previous)
    const key = `parents/${user.id}/profile.jpg`;
    const photoUrl = await uploadToMinio(key, buffer, file.type);

    await prisma.user.update({
      where: { id: user.id },
      data: { image: photoUrl },
    });

    return NextResponse.json({ success: true, photoUrl });
  } catch (error) {
    console.error('POST /api/parents/photo error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
