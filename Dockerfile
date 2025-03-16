# Use a more specific and existing Node.js version (node:22-slim doesn't exist yet)
FROM node:20-slim

# Enable Corepack to manage Yarn versions
RUN corepack enable

# Create and set working directory
WORKDIR /app

# Copy package files first (for better layer caching)
COPY package.json yarn.lock .yarnrc.yml ./

# Install dependencies using the correct Yarn version
RUN corepack prepare yarn@4.0.2 --activate &&
  yarn install --immutable --frozen-lockfile

# Copy the rest of the application
COPY . .

# Build the application
RUN yarn build

# Use a multi-stage build for a smaller production image
FROM node:20-slim

WORKDIR /app

# Copy only necessary files from builder
COPY --from=0 /app/.next ./.next
COPY --from=0 /app/public ./public
COPY --from=0 /app/node_modules ./node_modules
COPY --from=0 /app/package.json ./package.json
COPY --from=0 /app/yarn.lock ./yarn.lock
COPY --from=0 /app/.yarnrc.yml ./.yarnrc.yml

# Expose the port your app runs on
EXPOSE 3000

# Set environment variables
ENV NODE_ENV=production \
  PORT=3000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/api/health || exit 1

# Start the application
CMD ["yarn", "start"]
