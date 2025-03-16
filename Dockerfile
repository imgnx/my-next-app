# Use Node.js 22
FROM node:22-slim AS builder

# Enable Corepack to manage Yarn versions
RUN corepack enable

# Create and set working directory
WORKDIR /app

# Copy package files and yarn configuration first
COPY package.json yarn.lock .yarnrc.yml ./

# Install all dependencies (including dev dependencies for building)
RUN corepack prepare yarn@4.7.0 --activate && yarn install --immutable

# Copy the rest of the application
COPY . .

# Build the application
RUN yarn build

# Install only production dependencies
RUN yarn workspaces focus --production --all

# Use a multi-stage build for a smaller production image
FROM node:22-slim

WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/yarn.lock ./yarn.lock
COPY --from=builder /app/.yarnrc.yml ./.yarnrc.yml
COPY --from=builder /app/node_modules ./node_modules

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Expose the port your app runs on
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production PORT=3000

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD curl -f http://localhost:3000/api/health || exit 1

# Start the application
CMD ["yarn", "start"]
