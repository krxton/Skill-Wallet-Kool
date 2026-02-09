import { NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';

export type UserRole = 'user' | 'admin';

/**
 * Get user role from Supabase app_metadata.
 * Default: 'user' if not set.
 * Only changeable via Supabase dashboard or service_role API.
 */
export function getUserRole(user: { app_metadata?: Record<string, unknown> }): UserRole {
  const role = user.app_metadata?.role;
  if (role === 'admin') return 'admin';
  return 'user';
}

/**
 * Create authenticated Supabase client from request.
 * Supports both Bearer token (Flutter) and cookie (web).
 */
export async function createAuthClient(request: NextRequest) {
  const authHeader = request.headers.get('authorization');

  if (authHeader?.startsWith('Bearer ')) {
    const token = authHeader.substring(7);
    return createServerClient(
      process.env.NEXT_PUBLIC_SUPABASE_URL!,
      process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      {
        global: {
          headers: { Authorization: `Bearer ${token}` },
        },
        cookies: { getAll: () => [], setAll: () => {} },
      }
    );
  }

  const cookieStore = await cookies();
  return createServerClient(
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
