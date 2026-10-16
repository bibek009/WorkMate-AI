
# Shared Node.js base with OpenSSL
FROM node:22-bookworm-slim AS base

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Stage 1: Dependencies
FROM base AS deps

COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: Build
FROM base AS builder

ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .

RUN npx prisma generate
RUN npm run build

# Stage 3: Runtime
FROM base AS runner

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=8080
ENV HOSTNAME=0.0.0.0

RUN groupadd --system --gid 1001 nodejs \
    && useradd --system --uid 1001 --gid nodejs nextjs

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/standalone ./

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/static ./.next/static

COPY --from=builder --chown=nextjs:nodejs \
    /app/public ./public

COPY --from=builder --chown=nextjs:nodejs \
    /app/src/generated/prisma ./src/generated/prisma

USER nextjs

EXPOSE 8080

CMD ["node", "server.js"]
