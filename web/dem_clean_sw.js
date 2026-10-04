// The AWS terrain tiles contain isolated pixels thousands of meters too deep.
// Contours around those pixels draw as bars in rivers such as the Hudson.
// Replace a pixel that sits far below its neighbors before the chart reads it.

const DROP_M = 200;

self.addEventListener('install', (event) => {
  event.waitUntil(self.skipWaiting());
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', (event) => {
  if (!event.request.url.includes('elevation-tiles-prod/terrarium/')) return;
  event.respondWith(cleanTerrarium(event.request));
});

async function cleanTerrarium(request) {
  const response = await fetch(request);
  if (!response.ok) return response;
  const fallback = response.clone();
  try {
    const png = new Uint8Array(await response.arrayBuffer());
    const cleaned = await cleanPng(png);
    return new Response(cleaned, {
      status: 200,
      headers: {
        'Content-Type': 'image/png',
        'Cache-Control': 'public, max-age=86400',
        'Access-Control-Allow-Origin': '*',
      },
    });
  } catch (error) {
    return fallback;
  }
}

function terrarium(r, g, b) {
  return r * 256 + g + b / 256 - 32768;
}

function encodeTerrarium(elevation) {
  let value = elevation + 32768;
  if (value < 0) value = 0;
  if (value > 65535.99) value = 65535.99;
  const whole = Math.floor(value);
  return [
    Math.floor(whole / 256),
    whole % 256,
    Math.min(255, Math.round((value - whole) * 256)),
  ];
}

function removeSpikes(elevation, width, height) {
  const next = new Float64Array(elevation.length);
  for (let pass = 0; pass < 2; pass++) {
    const source = pass === 0 ? elevation : next;
    for (let y = 0; y < height; y++) {
      for (let x = 0; x < width; x++) {
        const neighbors = [];
        for (let dy = -1; dy <= 1; dy++) {
          for (let dx = -1; dx <= 1; dx++) {
            if (!dx && !dy) continue;
            const yy = y + dy;
            const xx = x + dx;
            if (yy < 0 || yy >= height || xx < 0 || xx >= width) continue;
            neighbors.push(source[yy * width + xx]);
          }
        }
        neighbors.sort((a, b) => a - b);
        const median = neighbors[neighbors.length >> 1];
        const here = source[y * width + x];
        next[y * width + x] = here < median - DROP_M ? median : here;
      }
    }
  }
  return next;
}

async function cleanPng(bytes) {
  const image = await decodePng(bytes);
  const cleaned = removeSpikes(image.elevation, image.width, image.height);
  return encodePng(cleaned, image.width, image.height);
}

async function decodePng(bytes) {
  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  let offset = 8;
  let width = 0;
  let height = 0;
  let color = 0;
  const idat = [];
  while (offset < bytes.length) {
    const length = view.getUint32(offset);
    const type = String.fromCharCode(
      bytes[offset + 4],
      bytes[offset + 5],
      bytes[offset + 6],
      bytes[offset + 7],
    );
    const data = bytes.subarray(offset + 8, offset + 8 + length);
    offset += 12 + length;
    if (type === 'IHDR') {
      width = new DataView(data.buffer, data.byteOffset, data.byteLength).getUint32(0);
      height = new DataView(data.buffer, data.byteOffset, data.byteLength).getUint32(4);
      color = data[9];
      if (data[8] !== 8 || data[12] !== 0) {
        throw new Error('unsupported png');
      }
    } else if (type === 'IDAT') {
      idat.push(data);
    } else if (type === 'IEND') {
      break;
    }
  }
  const channels = color === 2 ? 3 : color === 6 ? 4 : 0;
  if (!channels) throw new Error('unsupported png color');
  const compressed = concat(idat);
  const raw = await inflate(compressed);
  const stride = width * channels;
  const rows = [];
  let index = 0;
  for (let y = 0; y < height; y++) {
    const filter = raw[index++];
    const row = raw.subarray(index, index + stride);
    index += stride;
    const previous = rows.length ? rows[rows.length - 1] : new Uint8Array(stride);
    const out = new Uint8Array(stride);
    for (let x = 0; x < stride; x++) {
      const left = x >= channels ? out[x - channels] : 0;
      const up = previous[x];
      const upLeft = x >= channels ? previous[x - channels] : 0;
      let value = row[x];
      if (filter === 1) value += left;
      else if (filter === 2) value += up;
      else if (filter === 3) value += (left + up) >> 1;
      else if (filter === 4) value += paeth(left, up, upLeft);
      else if (filter !== 0) throw new Error('bad png filter');
      out[x] = value & 255;
    }
    rows.push(out);
  }
  const elevation = new Float64Array(width * height);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = x * channels;
      elevation[y * width + x] = terrarium(rows[y][i], rows[y][i + 1], rows[y][i + 2]);
    }
  }
  return { width, height, elevation };
}

function paeth(left, up, upLeft) {
  const estimate = left + up - upLeft;
  const dl = Math.abs(estimate - left);
  const du = Math.abs(estimate - up);
  const dul = Math.abs(estimate - upLeft);
  if (dl <= du && dl <= dul) return left;
  if (du <= dul) return up;
  return upLeft;
}

function concat(parts) {
  let length = 0;
  for (const part of parts) length += part.length;
  const out = new Uint8Array(length);
  let offset = 0;
  for (const part of parts) {
    out.set(part, offset);
    offset += part.length;
  }
  return out;
}

function inflate(bytes) {
  // PNG stores zlib data. DecompressionStream accepts the zlib wrapper.
  return new Response(
    new Blob([bytes]).stream().pipeThrough(new DecompressionStream('deflate')),
  ).arrayBuffer().then((buffer) => new Uint8Array(buffer));
}

async function encodePng(elevation, width, height) {
  const raw = new Uint8Array(height * (1 + width * 3));
  let offset = 0;
  for (let y = 0; y < height; y++) {
    raw[offset++] = 0;
    for (let x = 0; x < width; x++) {
      const [r, g, b] = encodeTerrarium(elevation[y * width + x]);
      raw[offset++] = r;
      raw[offset++] = g;
      raw[offset++] = b;
    }
  }
  const compressed = new Uint8Array(
    await new Response(
      new Blob([raw]).stream().pipeThrough(new CompressionStream('deflate')),
    ).arrayBuffer(),
  );
  const ihdr = new Uint8Array(13);
  const header = new DataView(ihdr.buffer);
  header.setUint32(0, width);
  header.setUint32(4, height);
  ihdr[8] = 8;
  ihdr[9] = 2;
  const signature = Uint8Array.from([137, 80, 78, 71, 13, 10, 26, 10]);
  return concat([
    signature,
    chunk('IHDR', ihdr),
    chunk('IDAT', compressed),
    chunk('IEND', new Uint8Array(0)),
  ]);
}

function chunk(type, data) {
  const body = new Uint8Array(4 + data.length);
  body.set(new TextEncoder().encode(type), 0);
  body.set(data, 4);
  const out = new Uint8Array(8 + data.length + 4);
  new DataView(out.buffer).setUint32(0, data.length);
  out.set(body, 4);
  new DataView(out.buffer).setUint32(8 + data.length, crc32(body));
  return out;
}

function crc32(bytes) {
  let crc = -1;
  for (let i = 0; i < bytes.length; i++) {
    crc ^= bytes[i];
    for (let bit = 0; bit < 8; bit++) {
      crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
    }
  }
  return (~crc) >>> 0;
}
