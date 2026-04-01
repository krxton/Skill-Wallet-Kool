// api/children/[id]/photo/route.ts
// อัปโหลดรูปโปรไฟล์ของเด็กไปยัง Supabase Storage
// แล้วอัปเดต photo_url ในตาราง child

import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { createSupabaseServerClient } from '@/lib/supabase/server';
import { prisma } from '@/lib/prisma';

type RouteContext = { params: Promise<{ id: string }> };

export async function POST(
  request: NextRequest,
  context: RouteContext
) {
  const { id: childId } = await context.params;

  // ตรวจสอบ auth
  const auth = await getAuthenticatedParent(request);
  if ('error' in auth) {
    return NextResponse.json({ error: auth.error }, { status: 401 });
  }
  const { user, parent } = auth;

  // ตรวจสอบว่าเด็กคนนี้เป็นของ parent นี้จริง
  const link = await prisma.parent_and_child.findFirst({
    where: { parent_id: parent.parent_id, child_id: childId },
  });
  if (!link) {
    return NextResponse.json({ error: 'Child not found or access denied' }, { status: 403 });
  }

  // รับไฟล์จาก multipart/form-data
  const formData = await request.formData();
  const file = formData.get('photo') as File | null;

  if (!file) {
    return NextResponse.json({ error: 'photo field is required' }, { status: 400 });
  }

  // ตรวจ MIME type
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
  if (!allowedTypes.includes(file.type)) {
    return NextResponse.json(
      { error: 'Unsupported file type. Use JPEG, PNG or WebP.' },
      { status: 400 }
    );
  }

  // จำกัดขนาดไฟล์ 5 MB
  const MAX_SIZE = 5 * 1024 * 1024;
  if (file.size > MAX_SIZE) {
    return NextResponse.json({ error: 'File too large (max 5 MB)' }, { status: 400 });
  }

  try {
    const supabase = await createSupabaseServerClient();
    const bytes = await file.arrayBuffer();
    const buffer = new Uint8Array(bytes);

    // path: avatars/children/{childId}/profile.jpg
    const storagePath = `children/${childId}/profile.jpg`;

    const { error: uploadError } = await supabase.storage
      .from('avatars')
      .upload(storagePath, buffer, {
        contentType: file.type,
        upsert: true,
      });

    if (uploadError) {
      console.error('Storage upload error:', uploadError);
      return NextResponse.json({ error: 'Failed to upload photo' }, { status: 500 });
    }

    // ดึง public URL
    const { data: urlData } = supabase.storage
      .from('avatars')
      .getPublicUrl(storagePath);

    const photoUrl = `${urlData.publicUrl}?v=${Date.now()}`;

    // บันทึก photo_url ลงในตาราง child
    await prisma.child.update({
      where: { child_id: childId },
      data: { photo_url: photoUrl },
    });

    return NextResponse.json({ success: true, photoUrl });
  } catch (error) {
    console.error('POST /api/children/[id]/photo error:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
