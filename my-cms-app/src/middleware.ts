import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'
import { createServerClient } from '@supabase/ssr'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll: () => req.cookies.getAll(),
        setAll: (cookiesToSet) => {
          cookiesToSet.forEach(({ name, value }) =>
            res.cookies.set(name, value)
          )
        },
      },
    }
  )

  const {
    data: { user },
  } = await supabase.auth.getUser()

  // Public paths that don't require authentication
  const publicPaths = ['/login', '/api', '/_next', '/favicon.ico']
  const isPublicPath = publicPaths.some(path => req.nextUrl.pathname.startsWith(path))

  // Not logged in → redirect to login
  if (!user && !isPublicPath) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  // Logged in but NOT admin → block access to protected routes
  if (user && !isPublicPath) {
    const role = user.app_metadata?.role
    if (role !== 'admin') {
      // Sign out and redirect to login with error
      await supabase.auth.signOut()
      return NextResponse.redirect(
        new URL('/login?error=unauthorized', req.url)
      )
    }
  }

  // Admin logged in and trying to access login page → redirect to admin
  if (user && req.nextUrl.pathname === '/login') {
    const role = user.app_metadata?.role
    if (role === 'admin') {
      return NextResponse.redirect(new URL('/admin/activities', req.url))
    }
  }

  return res
}

export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
}
