import { createAuthClient } from 'better-auth/react'
import { bearerClient } from 'better-auth/client/plugins'
import { inferAdditionalFields } from 'better-auth/client/plugins'
import type { auth } from './auth'

export const authClient = createAuthClient({
  baseURL: process.env.NEXT_PUBLIC_APP_URL || '',
  plugins: [
    bearerClient(),
    inferAdditionalFields<typeof auth>(),
  ],
})
