import { auth } from "@/lib/auth"; // path to your auth file
import { toNextJsHandler } from "better-auth/next-js";

export const { POST: _POST, GET: _GET } = toNextJsHandler(auth);

export const OPTIONS = async () => {
    return new Response(null, {
        status: 204,
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
            "Access-Control-Allow-Headers": "Content-Type, Authorization",
        },
    });
};

export const POST = async (request: Request) => {
    const response = await _POST(request);
    response.headers.set("Access-Control-Allow-Origin", "*");
    return response;
};

export const GET = async (request: Request) => {
    const response = await _GET(request);
    response.headers.set("Access-Control-Allow-Origin", "*");
    return response;
};