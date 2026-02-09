// src/app/api/update-medal/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { medalsId, name, cost } = body;

    if (!medalsId || !name || cost == null) {
      return NextResponse.json(
        { error: 'Missing required fields: medalsId, name, and cost are required' },
        { status: 400 }
      );
    }

    const authHeader = request.headers.get('authorization');
    let supabase;

    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
          global: {
            headers: { Authorization: `Bearer ${token}` }
          },
          cookies: { getAll: () => [], setAll: () => {} },
        }
      );
    } else {
      const cookieStore = await cookies();
      supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
          cookies: {
            getAll() { return cookieStore.getAll(); },
            setAll(cookiesToSet) {
              cookiesToSet.forEach(({ name, value, options }) => {
                cookieStore.set(name, value, options);
              });
            },
          },
        }
      );
    }

    // Verify authenticated user
    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Get parent
    const { data: parent, error: parentError } = await supabase
      .from('parent')
      .select('parent_id')
      .eq('user_id', user.id)
      .single();

    if (parentError || !parent) {
      return NextResponse.json({ error: 'Parent not found' }, { status: 404 });
    }

    // Verify this medal belongs to this parent
    const { data: link, error: linkError } = await supabase
      .from('parent_and_medals')
      .select('medals_id')
      .eq('parent_id', parent.parent_id)
      .eq('medals_id', medalsId)
      .single();

    if (linkError || !link) {
      return NextResponse.json(
        { error: 'Medal not found or does not belong to this parent' },
        { status: 403 }
      );
    }

    // Update the medal
    const { error: updateError } = await supabase
      .from('medals')
      .update({
        name_medals: name,
        point_medals: Number(cost),
      })
      .eq('id', medalsId);

    if (updateError) {
      console.error('Update medal error:', updateError);
      return NextResponse.json(
        { error: `Failed to update medal: ${updateError.message}` },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Medal updated successfully',
    });

  } catch (error) {
    console.error('Update medal error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
