// src/app/api/complete-quest/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const {
      childId,
      activityId,
      totalScoreEarned,
      segmentResults,
      evidence,
      parentScore,
      timeSpent
    } = body;

    // Validate required fields
    if (!childId || !activityId) {
      return NextResponse.json(
        { error: 'Missing required fields: childId and activityId are required' },
        { status: 400 }
      );
    }

    // Get Authorization header (for Flutter app)
    const authHeader = request.headers.get('authorization');
    let supabase;

    if (authHeader?.startsWith('Bearer ')) {
      // Flutter app authentication with Bearer token
      const token = authHeader.substring(7);
      supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
          global: {
            headers: {
              Authorization: `Bearer ${token}`
            }
          },
          cookies: {
            getAll: () => [],
            setAll: () => {},
          },
        }
      );
    } else {
      // Web browser authentication with cookies
      const cookieStore = await cookies();
      supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
          cookies: {
            getAll() {
              return cookieStore.getAll();
            },
            setAll(cookiesToSet) {
              cookiesToSet.forEach(({ name, value, options }) => {
                cookieStore.set(name, value, options);
              });
            },
          },
        }
      );
    }

    // Get authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json(
        { error: 'Unauthorized - Please log in' },
        { status: 401 }
      );
    }

    // Get parent info from user
    const { data: parent, error: parentError } = await supabase
      .from('parent')
      .select('parent_id')
      .eq('user_id', user.id)
      .single();

    if (parentError || !parent) {
      return NextResponse.json(
        { error: 'Parent profile not found' },
        { status: 404 }
      );
    }

    // Verify child belongs to this parent
    const { data: childRelation, error: childError } = await supabase
      .from('parent_and_child')
      .select('child_id')
      .eq('parent_id', parent.parent_id)
      .eq('child_id', childId)
      .single();

    if (childError || !childRelation) {
      return NextResponse.json(
        { error: 'Child not found or does not belong to this parent' },
        { status: 403 }
      );
    }

    // Get current child wallet to update
    const { data: childData, error: childDataError } = await supabase
      .from('child')
      .select('wallet, update_wallet')
      .eq('child_id', childId)
      .single();

    if (childDataError || !childData) {
      return NextResponse.json(
        { error: 'Failed to fetch child data' },
        { status: 500 }
      );
    }

    const scoreToAdd = totalScoreEarned || 0;
    const currentWallet = Number(childData.wallet) || 0;
    const currentUpdateWallet = Number(childData.update_wallet) || 0;

    // Create activity record with evidence
    const { data: activityRecord, error: recordError } = await supabase
      .from('activity_record')
      .insert({
        parent_id: parent.parent_id,
        child_id: childId,
        activity_id: activityId,
        point: scoreToAdd,
        time_spent: timeSpent || null,
        date: new Date().toISOString(),
        segment_results: segmentResults || null,
        evidence: evidence || null,
      })
      .select()
      .single();

    if (recordError) {
      console.error('Activity record error:', recordError);
      return NextResponse.json(
        { error: `Failed to create activity record: ${recordError.message}` },
        { status: 500 }
      );
    }

    // Update child's wallet
    const { error: walletError } = await supabase
      .from('child')
      .update({
        wallet: currentWallet + scoreToAdd,
        update_wallet: currentUpdateWallet + scoreToAdd,
      })
      .eq('child_id', childId);

    if (walletError) {
      console.error('Wallet update error:', walletError);
      // Don't fail the request, just log the error
    }

    // Update activity play count
    const { data: activity } = await supabase
      .from('activity')
      .select('play_count')
      .eq('activity_id', activityId)
      .single();

    if (activity) {
      const currentPlayCount = Number(activity.play_count) || 0;
      await supabase
        .from('activity')
        .update({ play_count: currentPlayCount + 1 })
        .eq('activity_id', activityId);
    }

    return NextResponse.json({
      success: true,
      message: 'Quest completed successfully!',
      activityRecord,
      scoreEarned: scoreToAdd,
      newWallet: currentWallet + scoreToAdd,
      segmentResults,
      evidence,
    });

  } catch (error) {
    console.error('Complete quest error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
