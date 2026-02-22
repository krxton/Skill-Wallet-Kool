import { NextRequest, NextResponse } from 'next/server';
import { SupabaseClient } from '@supabase/supabase-js';
import { createAuthClient, verifyBearerToken } from './auth-helpers';
import { prisma } from './prisma';

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
 * Flutter (Bearer token): verify JWT locally + query Prisma — no Supabase network call.
 * Web (cookie): use Supabase auth as before.
 */
export async function getAuthenticatedParent(
  request: NextRequest
): Promise<AuthResult | AuthError> {
  try {
    const authHeader = request.headers.get('authorization');

    if (authHeader?.startsWith('Bearer ')) {
      const token = authHeader.substring(7);

      // Fast path: local HS256 JWT verification (no Supabase network call)
      let userId: string | undefined = verifyBearerToken(token)?.id;

      if (!userId) {
        // Fallback: remote Supabase auth (in case token uses new asymmetric key)
        const supabaseFallback = await createAuthClient(request);
        const { data: { user: remoteUser }, error } = await supabaseFallback.auth.getUser();
        if (error || !remoteUser) {
          return { error: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) };
        }
        userId = remoteUser.id;
      }

      // Query parent via Prisma (direct DB — fast)
      const parentRow = await prisma.parent.findFirst({
        where: { user_id: userId },
        select: { parent_id: true, name_surname: true, email: true, user_id: true },
      });

      if (!parentRow) {
        return {
          error: NextResponse.json(
            { error: 'Parent not found for this user' },
            { status: 404 }
          ),
        };
      }

      const supabase = await createAuthClient(request);

      return {
        supabase,
        user: { id: userId },
        parent: {
          parent_id: parentRow.parent_id,
          name_surname: parentRow.name_surname ?? '',
          email: parentRow.email,
          user_id: parentRow.user_id ?? '',
        },
      };
    }

    // Web path (cookie): keep existing Supabase auth flow
    const supabase = await createAuthClient(request);
    const { data: { user }, error: authError } = await supabase.auth.getUser();

    if (authError || !user) {
      return {
        error: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }),
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
