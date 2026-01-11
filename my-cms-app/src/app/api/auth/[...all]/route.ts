import { auth } from "@/lib/auth";
import { toNextJsHandler } from "better-auth/next-js";

export const { POST: _POST, GET: _GET } = toNextJsHandler(auth);

// CORS Configuration
const getCorsHeaders = (origin: string | null) => {
  const allowedOrigins = [
    "http://localhost:3000",
    "http://localhost:8080", // Flutter debug
    process.env.NEXT_PUBLIC_APP_URL,
  ].filter(Boolean);

  const isAllowed = origin && (
    allowedOrigins.includes(origin) || 
    process.env.NODE_ENV === "development"
  );

  return {
    "Access-Control-Allow-Origin": isAllowed ? origin! : allowedOrigins[0]!,
    "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type, Authorization, Cookie",
    "Access-Control-Allow-Credentials": "true",
  };
};

// OPTIONS Handler (Preflight)
export const OPTIONS = async (request: Request) => {
  const origin = request.headers.get("origin");
  return new Response(null, {
    status: 204,
    headers: getCorsHeaders(origin),
  });
};

// POST Handler
export const POST = async (request: Request) => {
  const origin = request.headers.get("origin");
  const response = await _POST(request);
  
  const corsHeaders = getCorsHeaders(origin);
  Object.entries(corsHeaders).forEach(([key, value]) => {
    response.headers.set(key, value);
  });
  
  return response;
};

// GET Handler
export const GET = async (request: Request) => {
  const origin = request.headers.get("origin");
  const response = await _GET(request);
  
  const corsHeaders = getCorsHeaders(origin);
  Object.entries(corsHeaders).forEach(([key, value]) => {
    response.headers.set(key, value);
  });
  
  return response;
};