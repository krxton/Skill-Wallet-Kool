import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

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
