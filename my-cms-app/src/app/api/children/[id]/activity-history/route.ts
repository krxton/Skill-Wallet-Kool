import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/children/[id]/activity-history
 * Get activity history for a child.
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { supabase } = auth;

  try {
    const { data, error } = await supabase
      .from('activity_record')
      .select(`
        *,
        activity:activity_id (
          name_activity,
          category,
          maxscore
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
      { error: 'Failed to get activity history', details: err.message },
      { status: 500 }
    );
  }
}
