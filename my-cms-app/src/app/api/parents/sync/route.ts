import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { createAuthClient } from '@/lib/auth-helpers';

/**
 * POST /api/parents/sync
 * Upsert parent record for authenticated user.
 * Called after login/register from Flutter.
 *
 * Body: { email: string, fullName: string }
 * Response: { success: true, parent: { parentId, nameSurname, email } }
 */
export async function POST(request: NextRequest) {
  try {
    const supabase = await createAuthClient(request);
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const body = await request.json();
    const { email, fullName } = body;

    if (!fullName) {
      return NextResponse.json(
        { error: 'fullName is required' },
        { status: 400 }
      );
    }

    const emailToSave = email || user.email;

    // Check if parent exists
    const { data: existing } = await supabase
      .from('parent')
      .select('parent_id, name_surname, email, user_id')
      .eq('user_id', user.id)
      .maybeSingle();

    let parent;

    if (existing) {
      // Update existing parent
      const { data, error } = await supabase
        .from('parent')
        .update({ name_surname: fullName })
        .eq('user_id', user.id)
        .select('parent_id, name_surname, email')
        .single();

      if (error) {
        return NextResponse.json(
          { error: 'Failed to update parent', details: error.message },
          { status: 500 }
        );
      }
      parent = data;
    } else {
      // Insert new parent
      const { data, error } = await supabase
        .from('parent')
        .insert({
          user_id: user.id,
          email: emailToSave,
          name_surname: fullName,
        })
        .select('parent_id, name_surname, email')
        .single();

      if (error) {
        return NextResponse.json(
          { error: 'Failed to create parent', details: error.message },
          { status: 500 }
        );
      }
      parent = data;
    }

    return NextResponse.json({
      success: true,
      parent: {
        parentId: parent.parent_id,
        nameSurname: parent.name_surname,
        email: parent.email,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Sync failed', details: err.message },
      { status: 500 }
    );
  }
}
