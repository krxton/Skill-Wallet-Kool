import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/children/[id]/redemptions
 * Get redemption history for a child.
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { supabase } = auth;

  try {
    const { data, error } = await supabase
      .from('redemption')
      .select(`
        *,
        medals:medals_id (
          name_medals,
          point_medals
        )
      `)
      .eq('child_id', childId)
      .order('created_at', { ascending: false });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json(data || []);
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to get redemption history', details: err.message },
      { status: 500 }
    );
  }
}
