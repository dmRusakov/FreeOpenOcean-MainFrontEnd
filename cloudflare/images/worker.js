const TYPES = {
  avif: "image/avif",
  gif: "image/gif",
  jpeg: "image/jpeg",
  jpg: "image/jpeg",
  png: "image/png",
  svg: "image/svg+xml",
  webp: "image/webp",
};

const KEY = /^[a-z0-9][a-z0-9/_-]{0,180}\.(avif|gif|jpe?g|png|svg|webp)$/;
const HASHED = /-[a-f0-9]{8,}\.(avif|gif|jpe?g|png|svg|webp)$/;

function notFound() {
  return new Response("Not found", {
    status: 404,
    headers: { "cache-control": "no-store" },
  });
}

function keyFromPath(pathname) {
  let path = pathname;
  try {
    path = decodeURIComponent(pathname);
  } catch {
    return "";
  }
  if (path.startsWith("/")) path = path.slice(1);
  path = path.toLowerCase();
  if (!KEY.test(path) || path.includes("..") || path.includes("//")) return "";
  return path;
}

function clampInt(value, min, max) {
  if (value == null || value === "") return undefined;
  const n = Number(value);
  if (!Number.isInteger(n) || n < min || n > max) return null;
  return n;
}

function variant(url, contentType, request) {
  if (contentType === "image/svg+xml" || contentType === "image/gif") return undefined;
  const q = url.searchParams;
  const width = clampInt(q.get("w"), 16, 4096);
  const height = clampInt(q.get("h"), 16, 4096);
  const quality = clampInt(q.get("q"), 40, 90);
  if (width === null || height === null || quality === null) return null;
  const format = q.get("f") || "";
  if (format && !["auto", "avif", "webp", "jpeg", "png"].includes(format)) return null;
  if (width == null && height == null && !format && quality == null) return undefined;
  const transform = { fit: "scale-down" };
  if (width != null) transform.width = width;
  if (height != null) transform.height = height;
  let outputFormat = "image/webp";
  if (format === "auto") {
    const accept = request.headers.get("accept") || "";
    outputFormat = accept.includes("image/avif") ? "image/avif" : "image/webp";
  } else if (format) {
    outputFormat = `image/${format === "jpeg" ? "jpeg" : format}`;
  }
  return { transform, outputFormat, quality: quality ?? 75 };
}

export default {
  async fetch(request, env, ctx) {
    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { allow: "GET, HEAD", "cache-control": "no-store" },
      });
    }

    const url = new URL(request.url);
    const key = keyFromPath(url.pathname);
    if (!key) return notFound();

    const ext = key.slice(key.lastIndexOf(".") + 1);
    const contentType = TYPES[ext];
    const variantSpec = variant(url, contentType, request);
    if (variantSpec === null) return notFound();

    const cacheUrl = new URL(url.origin + "/" + key);
    if (variantSpec) {
      const { transform, outputFormat } = variantSpec;
      if (transform.width) cacheUrl.searchParams.set("w", String(transform.width));
      if (transform.height) cacheUrl.searchParams.set("h", String(transform.height));
      cacheUrl.searchParams.set("q", String(variantSpec.quality));
      cacheUrl.searchParams.set("f", outputFormat);
    }
    const cacheKey = new Request(cacheUrl.toString(), { method: "GET" });
    const cache = caches.default;
    const cached = await cache.match(cacheKey);
    if (cached) {
      return request.method === "HEAD" ? new Response(null, { status: cached.status, headers: cached.headers }) : cached;
    }

    const object = await env.IMAGES_BUCKET.get(key);
    if (!object) return notFound();

    const immutable = HASHED.test(key);
    const headers = new Headers();
    headers.set("content-type", contentType);
    headers.set("etag", object.httpEtag);
    headers.set("cache-control", immutable ? "public, max-age=31536000, immutable" : "public, max-age=86400");
    headers.set("access-control-allow-origin", "*");
    headers.set("x-content-type-options", "nosniff");
    headers.set("referrer-policy", "no-referrer");
    if (contentType === "image/svg+xml") {
      headers.set("content-security-policy", "default-src 'none'; style-src 'unsafe-inline'; sandbox");
    }

    if (!variantSpec && request.headers.get("if-none-match") === object.httpEtag) {
      return new Response(null, { status: 304, headers });
    }

    let response;
    if (!variantSpec) {
      response = new Response(request.method === "HEAD" ? null : object.body, { headers });
    } else {
      const out = await env.IMAGES.input(object.body)
        .transform(variantSpec.transform)
        .output({ format: variantSpec.outputFormat, quality: variantSpec.quality });
      const encoded = out.response();
      response = new Response(request.method === "HEAD" ? null : encoded.body, { headers });
      response.headers.set("content-type", encoded.headers.get("content-type") || variantSpec.outputFormat);
      response.headers.delete("etag");
    }

    if (response.status === 200 && request.method === "GET") {
      ctx.waitUntil(cache.put(cacheKey, response.clone()));
    }
    return response;
  },
};
