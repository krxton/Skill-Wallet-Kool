import { betterAuth } from "better-auth";
import { prismaAdapter } from "better-auth/adapters/prisma";
import { openAPI } from "better-auth/plugins";
import prisma from "./prisma";
import type { User as PrismaUser, Session as PrismaSession } from "@prisma/client";

console.log('=== Better Auth Configuration ===');
console.log('Google Client ID:', process.env.GOOGLE_CLIENT_ID ? '✓ Found' : '✗ Missing');
console.log('Facebook Client ID:', process.env.FACEBOOK_CLIENT_ID ? '✓ Found' : '✗ Missing');
console.log('Base URL:', process.env.BETTER_AUTH_URL || 'http://localhost:3000');

export const auth = betterAuth({
  database: prismaAdapter(prisma, {
    provider: "postgresql",
  }),
  
  emailAndPassword: {
    enabled: true,
  },
  
  // ✅ แก้ socialProviders
  socialProviders: {
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID!,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
      // เพิ่ม redirect URI ชัดเจน
      redirectURI: `${process.env.BETTER_AUTH_URL || "http://localhost:3000"}/api/auth/callback/google`,
    },
    facebook: {
      clientId: process.env.FACEBOOK_CLIENT_ID!,
      clientSecret: process.env.FACEBOOK_CLIENT_SECRET!,
      redirectURI: `${process.env.BETTER_AUTH_URL || "http://localhost:3000"}/api/auth/callback/facebook`,
    },
  },
  
  secret: process.env.BETTER_AUTH_SECRET!,
  
  // ✅ ต้องมี baseURL
  baseURL: process.env.BETTER_AUTH_URL || "http://localhost:3000",

  trustedOrigins: [
    "skillwalletkool://"
  ],
  
  plugins: [openAPI()],
});

console.log('=== Auth initialized ===');

export type User = PrismaUser;
export type Session = PrismaSession;