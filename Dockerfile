
# Stage 1: Install dependencies
FROM node:22-bookworm-slim AS deps

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: Generate Prisma Client and build Next.js
FROM node:22-bookworm-slim AS builder

WORKDIR /app

ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Generate the client using the repository's Prisma 7 config
RUN npx prisma generate

# Build the production Next.js standalone output
RUN npm run build

# Stage 3: Production runtime
FROM node:22-bookworm-slim AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Run as a non-root user
RUN groupadd --system --gid 1001 nodejs \
    && useradd --system --uid 1001 --gid nodejs nextjs

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/standalone ./

COPY --from=builder --chown=nextjs:nodejs \
    /app/.next/static ./.next/static

COPY --from=builder --chown=nextjs:nodejs \
    /app/public ./public

# Your Prisma generator writes to this custom location
COPY --from=builder --chown=nextjs:nodejs \
    /app/src/generated/prisma ./src/generated/prisma

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
