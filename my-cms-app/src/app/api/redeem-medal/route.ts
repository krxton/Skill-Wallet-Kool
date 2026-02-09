// src/app/api/redeem-medal/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { childId, medalsId, cost } = body;

    // Validate required fields
    if (!childId || !medalsId || cost == null) {
      return NextResponse.json(
        { error: 'Missing required fields: childId, medalsId, and cost are required' },
        { status: 400 }
      );
    }

    // Get Authorization header (for Flutter app)
    const authHeader = request.headers.get('authorization');
    let supabase;

    if (authHeader?.startsWith('Bearer ')) {
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

    // Get current child wallet
    const { data: childData, error: childDataError } = await supabase
      .from('child')
      .select('wallet')
      .eq('child_id', childId)
      .single();

    if (childDataError || !childData) {
      return NextResponse.json(
        { error: 'Failed to fetch child data' },
        { status: 500 }
      );
    }

    const currentWallet = Number(childData.wallet) || 0;
    const redeemCost = Number(cost);

    // Check if child has enough points
    if (currentWallet < redeemCost) {
      return NextResponse.json(
        {
          success: false,
          error: `Not enough points. Need ${redeemCost} but only have ${currentWallet}`,
          currentWallet,
        },
        { status: 400 }
      );
    }

    const newWallet = currentWallet - redeemCost;

    // Update child's wallet
    const { error: walletError } = await supabase
      .from('child')
      .update({ wallet: newWallet })
      .eq('child_id', childId);

    if (walletError) {
      console.error('Wallet update error:', walletError);
      return NextResponse.json(
        { error: `Failed to update wallet: ${walletError.message}` },
        { status: 500 }
      );
    }

    // Insert redemption record
    const { error: redemptionError } = await supabase
      .from('redemption')
      .insert({
        child_id: childId,
        medals_id: medalsId,
        parent_id: parent.parent_id,
        point_for_reward: redeemCost,
        date_redemption: new Date().toISOString(),
      });

    if (redemptionError) {
      console.error('Redemption record error:', redemptionError);
      // Wallet already deducted, log but don't fail
    }

    return NextResponse.json({
      success: true,
      message: 'Medal redeemed successfully!',
      newWallet,
      cost: redeemCost,
    });

  } catch (error) {
    console.error('Redeem medal error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
