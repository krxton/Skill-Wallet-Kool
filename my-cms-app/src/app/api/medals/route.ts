import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

/**
 * GET /api/medals
 * List medals for authenticated parent.
 */
export async function GET(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { supabase, parent } = auth;

  try {
    const { data, error } = await supabase
      .from('parent_and_medals')
      .select(`
        *,
        medals:medals_id (
          id,
          name_medals,
          point_medals,
          created_at
        )
      `)
      .eq('parent_id', parent.parent_id)
      .order('created_at', { ascending: false });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data || []);
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to fetch medals', details: err.message },
      { status: 500 }
    );
  }
}

/**
 * POST /api/medals
 * Create medal + link to parent.
 * Replaces RPC 'create_medal_and_link'.
 *
 * Body: { name, cost }
 */
export async function POST(request: NextRequest) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { supabase } = auth;

  try {
    const body = await request.json();
    const { name, cost } = body;

    if (!name) {
      return NextResponse.json({ error: 'name is required' }, { status: 400 });
    }
    if (cost === undefined || cost === null) {
      return NextResponse.json({ error: 'cost is required' }, { status: 400 });
    }

    // Use the existing RPC function
    const { data, error } = await supabase.rpc('create_medal_and_link', {
      p_name_medals: name,
      p_point_medals: cost,
    });

    if (error) {
      return NextResponse.json(
        { error: 'Failed to create medal', details: error.message },
        { status: 500 }
      );
    }

    return NextResponse.json(data, { status: 201 });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to create medal', details: err.message },
      { status: 500 }
    );
  }
}
