import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * Verify child belongs to authenticated parent.
 */
async function verifyChildOwnership(
  supabase: any,
  parentId: string,
  childId: string
): Promise<boolean> {
  const { data } = await supabase
    .from('parent_and_child')
    .select('child_id')
    .eq('parent_id', parentId)
    .eq('child_id', childId)
    .maybeSingle();
  return !!data;
}

/**
 * GET /api/children/[id]
 * Get single child details.
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { supabase, parent } = auth;

  const owns = await verifyChildOwnership(supabase, parent.parent_id, childId);
  if (!owns) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  const { data, error } = await supabase
    .from('child')
    .select('child_id, name_surname, wallet, birthday')
    .eq('child_id', childId)
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

/**
 * PATCH /api/children/[id]
 * Update child details.
 * Body: { fullName?, birthday? }
 */
export async function PATCH(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { supabase, parent } = auth;

  const owns = await verifyChildOwnership(supabase, parent.parent_id, childId);
  if (!owns) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  const body = await request.json();
  const updates: Record<string, any> = {};
  if (body.fullName) updates.name_surname = body.fullName;
  if (body.birthday) updates.birthday = body.birthday;

  if (Object.keys(updates).length === 0) {
    return NextResponse.json({ error: 'No updates provided' }, { status: 400 });
  }

  const { data, error } = await supabase
    .from('child')
    .update(updates)
    .eq('child_id', childId)
    .select('child_id, name_surname, wallet, birthday')
    .single();

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json(data);
}

/**
 * DELETE /api/children/[id]
 * Remove child and parent-child link.
 */
export async function DELETE(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;
  const { supabase, parent } = auth;

  const owns = await verifyChildOwnership(supabase, parent.parent_id, childId);
  if (!owns) {
    return NextResponse.json({ error: 'Child not found' }, { status: 404 });
  }

  try {
    // 1. Remove parent-child link first
    await supabase
      .from('parent_and_child')
      .delete()
      .eq('child_id', childId)
      .eq('parent_id', parent.parent_id);

    // 2. Remove child record
    await supabase.from('child').delete().eq('child_id', childId);

    return NextResponse.json({ success: true });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Failed to delete child', details: err.message },
      { status: 500 }
    );
  }
}
