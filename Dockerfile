# syntax=docker/dockerfile:1.7

# =============================================================================
# Builder stage — installs production dependencies only, on a fresh Node base.
# =============================================================================

# step-4a: builder base image is node:20.11-slim, stage named "builder".
FROM node:20.11-slim AS builder
#   Do NOT use `node:latest` — we want reproducible builds across the cohort.

WORKDIR /app

# step-4b: copy package.json and package-lock.json from app/, then install prod deps.
COPY app/package*.json ./
RUN npm ci --omit=dev

# step-4c: copy the rest of the app source into /app.
COPY app/src ./src

# =============================================================================
# Runtime stage — slim final image. Nothing from builder's caches leaks in.
# =============================================================================

# step-4d: runtime base image (same tag as step-4a for consistency).
FROM node:20.11-slim

WORKDIR /app

# step-4e: copy the fully-installed app from the builder stage.
COPY --from=builder /app .

ENV NODE_ENV=production
EXPOSE 3000

# step-4f: HEALTHCHECK using Node's built-in http module (no curl/wget on slim).
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD node -e "require('http').get('http://localhost:3000/health', r => process.exit(r.statusCode===200?0:1)).on('error', () => process.exit(1))"

# step-4g: container start command.
CMD ["node", "src/index.js"]
