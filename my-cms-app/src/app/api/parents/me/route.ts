import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';
import { createClient } from '@supabase/supabase-js';

/**
 * GET /api/parents/me
 * Get current authenticated parent's profile.
 *
 * Response: { parentId, nameSurname, email }
 */
export async function GET(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);

  if (auth.error) {
    return auth.error;
  }

  return NextResponse.json({
    parentId: auth.parent.parent_id,
    nameSurname: auth.parent.name_surname,
    email: auth.parent.email,
  });
}

/**
 * DELETE /api/parents/me
 * Delete current parent's account: unlinks all children, removes parent record,
 * then deletes the Supabase auth user.
 */
export async function DELETE(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { parent } = auth;

  try {
    // 1. Delete all parent_and_child links for this parent
    await prisma.parent_and_child.deleteMany({
      where: { parent_id: parent.parent_id },
    });

    // 2. Delete parent record
    await prisma.parent.delete({
      where: { parent_id: parent.parent_id },
    });

    // 3. Delete Supabase auth user using service role key
    const supabaseAdmin = createClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.SUPABASE_SERVICE_ROLE_KEY!
    );
    await supabaseAdmin.auth.admin.deleteUser(parent.user_id);

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to delete account', details: err.message },
      { status: 500 }
    );
  }
}
