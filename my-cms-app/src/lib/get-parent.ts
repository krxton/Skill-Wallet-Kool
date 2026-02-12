import { NextRequest, NextResponse } from 'next/server';
import { createAuthClient } from './auth-helpers';
import { SupabaseClient } from '@supabase/supabase-js';

interface AuthResult {
  supabase: SupabaseClient;
  user: { id: string; email?: string };
  parent: { parent_id: string; name_surname: string; email: string; user_id: string };
  error?: undefined;
}

interface AuthError {
  error: NextResponse;
  supabase?: undefined;
  user?: undefined;
  parent?: undefined;
}

/**
 * Get authenticated parent from request.
 * Handles Bearer token (Flutter) and cookie (web) auth.
 * Returns { supabase, user, parent } or { error: NextResponse }.
 */
export async function getAuthenticatedParent(
  request: NextRequest
): Promise<AuthResult | AuthError> {
  try {
    const supabase = await createAuthClient(request);
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return {
        error: NextResponse.json(
          { error: 'Unauthorized' },
          { status: 401 }
        ),
      };
    }

    const { data: parent, error: parentError } = await supabase
      .from('parent')
      .select('parent_id, name_surname, email, user_id')
      .eq('user_id', user.id)
      .single();

    if (parentError || !parent) {
      return {
        error: NextResponse.json(
          { error: 'Parent not found for this user' },
          { status: 404 }
        ),
      };
    }

    return { supabase, user, parent };
  } catch (err: any) {
    return {
      error: NextResponse.json(
        { error: 'Authentication failed', details: err.message },
        { status: 500 }
      ),
    };
  }
}
