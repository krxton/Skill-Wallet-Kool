import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/children/[id]/stats
 * Get child stats: wallet, name, totalActivities.
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { supabase } = auth;

  try {
    // Get child info
    const { data: child, error: childError } = await supabase
      .from('child')
      .select('wallet, name_surname')
      .eq('child_id', childId)
      .single();

    if (childError) {
      return NextResponse.json({ error: childError.message }, { status: 500 });
    }

    // Count activity records
    const { data: records, error: recordError } = await supabase
      .from('activity_record')
      .select('ActivityRecord_id')
      .eq('child_id', childId);

    const totalActivities = records ? records.length : 0;

    // Handle wallet as potentially decimal
    let wallet = 0;
    if (typeof child.wallet === 'number') {
      wallet = Math.floor(child.wallet);
    } else if (child.wallet != null) {
      wallet = parseInt(String(child.wallet)) || 0;
    }

    return NextResponse.json({
      wallet,
      name: child.name_surname || '',
      totalActivities,
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to get stats', details: err.message },
      { status: 500 }
    );
  }
}
