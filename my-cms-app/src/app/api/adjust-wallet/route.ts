// src/app/api/adjust-wallet/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { childId, delta } = body;

    // Validate required fields
    if (!childId || delta == null) {
      return NextResponse.json(
        { error: 'Missing required fields: childId and delta are required' },
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
    const deltaValue = Number(delta);
    const newWallet = Math.max(0, Math.min(999999, currentWallet + deltaValue));

    // Update child's wallet
    const { error: walletError } = await supabase
      .from('child')
      .update({ wallet: newWallet })
      .eq('child_id', childId);

    if (walletError) {
      console.error('Wallet adjust error:', walletError);
      return NextResponse.json(
        { error: `Failed to adjust wallet: ${walletError.message}` },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      newWallet,
      delta: deltaValue,
    });

  } catch (error) {
    console.error('Adjust wallet error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
