const SITE = "https://freeopenocean.com";
function isDevLocalOrigin(origin) {
  try {
    const url = new URL(origin);
    if (url.protocol !== "http:") return false;
    if (url.hostname !== "localhost" && url.hostname !== "127.0.0.1") return false;
    const port = Number(url.port);
    return port >= 65500 && port <= 65550;
  } catch {
    return false;
  }
}

function callerOrigin(request) {
  const origin = request.headers.get("Origin");
  if (origin) return origin;
  const referer = request.headers.get("Referer");
  if (!referer) return "";
  try {
    return new URL(referer).origin;
  } catch {
    return "";
  }
}

function devModeOn(env) {
  return String(env.DEV_MODE || "").trim().toLowerCase() === "on";
}

function allowed(request, env) {
  const origin = callerOrigin(request);
  if (origin === SITE) return origin;
  if (devModeOn(env) && isDevLocalOrigin(origin)) return origin;
  return "";
}

function deny() {
  return new Response("Forbidden", {
    status: 403,
    headers: { "cache-control": "no-store" },
  });
}

export default {
  async fetch(request, env) {
    const origin = allowed(request, env);
    if (!origin) return deny();

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "access-control-allow-origin": origin,
          "access-control-allow-methods": "GET, HEAD, OPTIONS",
          "access-control-allow-headers": "if-none-match",
          "access-control-expose-headers": "etag",
          vary: "Origin",
          "cache-control": "no-store",
        },
      });
    }
    if (request.method !== "GET" && request.method !== "HEAD") return deny();

    const path = new URL(request.url).pathname;
    if (!/^\/pages\/pages_[a-z0-9_-]+\.md$/.test(path)) {
      return new Response("Not found", { status: 404, headers: { "cache-control": "no-store" } });
    }

    const object = await env.PAGES.get(path.slice(1));
    if (!object) {
      return new Response("Not found", { status: 404, headers: { "cache-control": "no-store" } });
    }

    const headers = new Headers();
    object.writeHttpMetadata(headers);
    headers.set("content-type", "text/markdown; charset=utf-8");
    headers.set("etag", object.httpEtag);
    const devCaller = isDevLocalOrigin(origin);
    headers.set(
      "cache-control",
      devCaller ? "no-store" : "public, max-age=2592000",
    );
    if (devCaller) headers.set("cdn-cache-control", "no-store");
    headers.set("access-control-allow-origin", origin);
    headers.set("access-control-expose-headers", "etag");
    headers.set("vary", "Origin");
    headers.set("x-content-type-options", "nosniff");

    if (request.headers.get("if-none-match") === object.httpEtag) {
      return new Response(null, { status: 304, headers });
    }
    return new Response(request.method === "HEAD" ? null : object.body, { headers });
  },
};
