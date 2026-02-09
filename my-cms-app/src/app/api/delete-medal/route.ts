// src/app/api/delete-medal/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { medalsId } = body;

    if (!medalsId) {
      return NextResponse.json(
        { error: 'Missing required field: medalsId' },
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

    // Delete from parent_and_medals first (foreign key)
    const { error: unlinkError } = await supabase
      .from('parent_and_medals')
      .delete()
      .eq('medals_id', medalsId);

    if (unlinkError) {
      console.error('Unlink medal error:', unlinkError);
      return NextResponse.json(
        { error: `Failed to unlink medal: ${unlinkError.message}` },
        { status: 500 }
      );
    }

    // Delete the medal itself
    const { error: deleteError } = await supabase
      .from('medals')
      .delete()
      .eq('id', medalsId);

    if (deleteError) {
      console.error('Delete medal error:', deleteError);
      return NextResponse.json(
        { error: `Failed to delete medal: ${deleteError.message}` },
        { status: 500 }
      );
    }

    return NextResponse.json({
      success: true,
      message: 'Medal deleted successfully',
    });

  } catch (error) {
    console.error('Delete medal error:', error);
    return NextResponse.json(
      { error: 'Internal server error', details: error instanceof Error ? error.message : 'Unknown error' },
      { status: 500 }
    );
  }
}
