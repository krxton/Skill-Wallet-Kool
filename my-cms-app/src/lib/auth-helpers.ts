import { NextRequest } from 'next/server';
import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { createHmac } from 'crypto';

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
 * Verify Supabase JWT locally using SUPABASE_JWT_SECRET (HS256).
 * No network call — eliminates supabase.auth.getUser() latency for Flutter requests.
 * Returns { id: userId, email } or null if invalid/expired.
 */
export function verifyBearerToken(token: string): { id: string; email?: string } | null {
  const secret = process.env.SUPABASE_JWT_SECRET;
  if (!secret) return null;

  try {
    const parts = token.split('.');
    if (parts.length !== 3) return null;

    const [headerB64, payloadB64, signatureB64] = parts;

    // Verify HS256 signature using Node.js built-in crypto
    const expectedSig = createHmac('sha256', secret)
      .update(`${headerB64}.${payloadB64}`)
      .digest('base64url');

    if (expectedSig !== signatureB64) return null;

    // Decode payload
    const payload = JSON.parse(Buffer.from(payloadB64, 'base64url').toString('utf8'));

    // Check expiry
    if (payload.exp && Math.floor(Date.now() / 1000) > payload.exp) return null;

    if (!payload.sub) return null;

    return { id: payload.sub, email: payload.email };
  } catch {
    return null;
  }
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
