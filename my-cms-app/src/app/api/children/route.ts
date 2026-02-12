import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

/**
 * GET /api/children
 * List children for authenticated parent.
 * Returns nested format matching Flutter's expected structure.
 */
export async function GET(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { supabase, parent } = auth;

  try {
    const { data, error } = await supabase
      .from('parent_and_child')
      .select('child_id, relationship, child!inner(child_id, name_surname, wallet, birthday)')
      .eq('parent_id', parent.parent_id);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data || []);
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to fetch children', details: err.message },
      { status: 500 }
    );
  }
}

/**
 * POST /api/children
 * Create child + link to parent.
 * Replaces RPC 'create_child_and_link'.
 *
 * Body: { fullName, birthday, relationship? }
 */
export async function POST(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { supabase, parent } = auth;

  try {
    const body = await request.json();
    const { fullName, birthday, relationship } = body;

    if (!fullName) {
      return NextResponse.json({ error: 'fullName is required' }, { status: 400 });
    }

    // Use the existing RPC function to create child and link
    const { data, error } = await supabase.rpc('create_child_and_link', {
      p_name_surname: fullName,
      p_birthday: birthday || '',
      p_wallet: 0,
      p_relationship: relationship || 'พ่อ/แม่',
    });

    if (error) {
      return NextResponse.json(
        { error: 'Failed to create child', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(data, { status: 201 });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to create child', details: err.message },
      { status: 500 }
    );
  }
}
