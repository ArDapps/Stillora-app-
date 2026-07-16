FROM node:22-bookworm-slim AS deps

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1
# Use the distro Chromium (installed in the runner) instead of puppeteer's bundled
# download, so the image stays smaller and the binary has all its system deps.
ENV PUPPETEER_SKIP_DOWNLOAD=1

COPY package.json package-lock.json ./
# --ignore-scripts keeps the build hermetic: several deps (ffmpeg-static,
# youtube-dl-exec) download binaries from GitHub in postinstall, which fails on
# cloud build servers (unauthenticated GitHub rate limits → 403). Native deps
# (sharp, unrs-resolver, @next/swc) ship prebuilt binaries via optional
# dependencies, so they don't need their scripts. ffmpeg is provided via apt in
# the runner stage instead.
RUN npm ci --ignore-scripts

FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

FROM node:22-bookworm-slim AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
# Headless Chromium for the HTML → MP4 renderer (app/api/convert/html).
ENV PUPPETEER_SKIP_DOWNLOAD=1
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
# ffmpeg comes from the distro (npm install scripts are skipped in the build),
# so the export/render pipelines resolve this instead of ffmpeg-static.
ENV FFMPEG_PATH=/usr/bin/ffmpeg

# chromium + ffmpeg + fonts (incl. color emoji) for deterministic HTML video rendering.
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    chromium \
    ffmpeg \
    fonts-liberation \
    fonts-noto-core \
    fonts-noto-color-emoji \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN useradd --system --uid 1001 nextjs \
  && mkdir -p /data/stillora /app \
  && chown -R nextjs:nextjs /data/stillora /app

COPY --from=builder --chown=nextjs:nextjs /app/package.json /app/package-lock.json ./
COPY --from=builder --chown=nextjs:nextjs /app/.next ./.next
COPY --from=builder --chown=nextjs:nextjs /app/public ./public
COPY --from=builder --chown=nextjs:nextjs /app/node_modules ./node_modules

USER nextjs

EXPOSE 3000

CMD ["npm", "run", "start"]
