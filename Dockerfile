# Stage 1: Base image and dependencies
FROM node:20.12.2-alpine AS base

# Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
RUN apk update && apk add --no-cache libc6-compat

WORKDIR /app

# Install dependencies based on the preferred package manager (npm, yarn, or pnpm)
# If you use pnpm, uncomment the following lines:
# RUN corepack enable
# RUN corepack prepare pnpm@latest --activate
# ENV PNPM_HOME="/pnpm"
# ENV PATH="$PNPM_HOME:$PATH"

COPY package.json yarn.lock* pnpm-lock.yaml* ./
RUN npm install --frozen-lockfile

# Stage 2: Build the application
FROM base AS builder

WORKDIR /app

COPY --from=base /app/node_modules ./node_modules
COPY . .

# Next.js collects completely anonymous telemetry data about general usage.
# Uncomment the following line to disable telemetry during the build.
# ENV NEXT_TELEMETRY_DISABLED 1

RUN npm run build

# Stage 3: Run the application
FROM node:20.12.2-alpine AS runner

WORKDIR /app

# Next.js collects completely anonymous telemetry data about general usage.
# Uncomment the following line to disable telemetry during the run time.
# ENV NEXT_TELEMETRY_DISABLED 1

# If you use the standalone output feature in next.config.js, uncomment the following line.
# This copies only necessary files for production.
# COPY --from=builder /app/.next/standalone ./
# COPY --from=builder /app/.next/static ./.next/static
# COPY --from=builder /app/public ./public

# If not using standalone, copy necessary files manually:
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

ENV NODE_ENV=production


ENV PORT=6769
# Next.js handles port 3000 by default.
EXPOSE 6769

CMD ["npm", "start"]
