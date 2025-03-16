# Use Node.js 22
FROM node:22-slim AS builder

# Set NODE_ENV to development for build stage
ENV NODE_ENV=development

# Add build-time labels
LABEL org.opencontainers.image.description="Next.js application"
LABEL org.opencontainers.image.licenses="0BSD"

# Enable Corepack to manage Yarn versions
RUN corepack enable

# Create a non-root user
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs

# Create and set working directory
WORKDIR /app

# Copy package files and yarn configuration first
COPY --chown=nodejs:nodejs package.json yarn.lock .yarnrc.yml ./

# Install all dependencies
RUN corepack prepare yarn@4.7.0 --activate && yarn install --immutable && yarn cache clean

# Copy the rest of the application
COPY --chown=nodejs:nodejs . .

# Install only production dependencies
RUN yarn workspaces focus --production

# Build the application
RUN yarn build

# Production image
FROM node:22-slim AS runner

# Set production environment
ENV NODE_ENV=production \
  PORT=3000 \
  NEXT_TELEMETRY_DISABLED=1

# Create a non-root user
RUN groupadd -r nodejs && useradd -r -g nodejs nodejs

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder --chown=nodejs:nodejs /app/.next ./.next
COPY --from=builder --chown=nodejs:nodejs /app/public ./public
COPY --from=builder --chown=nodejs:nodejs /app/package.json ./package.json
COPY --from=builder --chown=nodejs:nodejs /app/yarn.lock ./yarn.lock
COPY --from=builder --chown=nodejs:nodejs /app/.yarnrc.yml ./.yarnrc.yml
COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules

# Install curl for healthcheck and clean up in the same layer
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/* && chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose the port your app runs on
EXPOSE 3000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start the application
CMD ["yarn", "start"]
