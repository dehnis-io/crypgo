# Stage 1: Dependency Installation
FROM node:20-alpine AS base
# Install necessary packages for Next.js production server on Alpine
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Stage 2: Builder
FROM base AS builder
WORKDIR /app
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* .npmrc* ./
RUN npm ci

# Copy the rest of the source code
COPY . .

# Run the build. Next.js creates the .next/standalone and .next/static folders.
RUN npm run build

# Stage 3: Production Runner
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Set up a non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Copy the standalone output and static assets from the builder stage
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

# The container will run the bundled server.js file
EXPOSE 3000
ENV PORT 3000
CMD ["node", "server.js"]