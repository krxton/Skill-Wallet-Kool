import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
type Session = {
  user: {
    id: string
    email: string
    role: string
  }
}

async function getSession(req: NextRequest): Promise<Session | null> {
  // Use BETTER_AUTH_URL (localhost) for internal fetch to avoid going through public network
  const baseURL = process.env.BETTER_AUTH_URL || req.nextUrl.origin
  try {
    const res = await fetch(`${baseURL}/api/auth/get-session`, {
      headers: { cookie: req.headers.get('cookie') || '' },
    })
    if (!res.ok) return null
    return await res.json()
  } catch {
    return null
  }
}

export async function proxy(req: NextRequest) {
  const res = NextResponse.next()
  const { pathname } = req.nextUrl

  // Always-public: health check, auth endpoints, static assets
  if (
    pathname === '/api/health' ||
    pathname.startsWith('/api/auth') ||
    pathname.startsWith('/_next') ||
    pathname === '/favicon.ico'
  ) {
    return res
  }

  const isApiPath = pathname.startsWith('/api')

  // /api/* routes: require X-API-Key or active admin session
  if (isApiPath) {
    const expectedKey = process.env.API_SECRET_KEY
    if (!expectedKey) return res

    const apiKey = req.headers.get('x-api-key')
    if (apiKey === expectedKey) return res

    // No API key — allow if caller has an admin session cookie (CMS internal)
    const session = await getSession(req)
    if (session?.user?.role === 'admin') return res

    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  // Login page: redirect admins who are already logged in
  if (pathname === '/login') {
    const session = await getSession(req)
    if (session?.user?.role === 'admin') {
      return NextResponse.redirect(new URL('/admin/activities', req.url))
    }
    return res
  }

  // All other pages: require admin session
  const session = await getSession(req)
  if (!session?.user) {
    return NextResponse.redirect(new URL('/login', req.url))
  }
  if (session.user.role !== 'admin') {
    return NextResponse.redirect(new URL('/login?error=unauthorized', req.url))
  }

  return res
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
