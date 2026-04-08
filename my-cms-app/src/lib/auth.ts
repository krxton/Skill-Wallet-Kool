import { betterAuth } from 'better-auth'
import { prismaAdapter } from 'better-auth/adapters/prisma'
import { bearer } from 'better-auth/plugins'
import { prisma } from './prisma'

export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: 'postgresql',
  }),
  emailAndPassword: {
    enabled: true,
  },
  plugins: [bearer()],
  user: {
    additionalFields: {
      role: {
        type: 'string',
        defaultValue: 'user',
        input: false,
      },
    },
  },
  trustedOrigins: [
    'http://localhost:3000',
    'https://skillwalletkool.duckdns.org',
    `http://103.216.158.225:3000`,
    process.env.BETTER_AUTH_TRUSTED_ORIGIN,
  ].filter(Boolean) as string[],
})
