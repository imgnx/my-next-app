# ---- Base Stage: Install Dependencies ----
FROM node:22 AS builder

WORKDIR /app

# Copy package manager files first (for caching)
COPY package.json yarn.lock ./

# Enable Yarn v4 explicitly
RUN corepack enable && corepack prepare yarn@4.7.0 --activate

# Force Yarn to use `node_modules` instead of PnP
ENV YARN_NODE_LINKER=node-modules

# Install dependencies
RUN yarn install --immutable

# Copy the rest of the application
COPY . .

# Build the application
RUN yarn build

# ---- Production Runner ----
FROM node:22 AS runner

WORKDIR /app

# Enable Yarn in runtime container
RUN corepack enable && corepack prepare yarn@4.7.0 --activate

# Force Yarn to use `node_modules`
ENV YARN_NODE_LINKER=node-modules

# Copy only necessary files from builder stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/yarn.lock ./yarn.lock
COPY --from=builder /app/public ./public

# Install only production dependencies
RUN yarn workspaces focus -A --production --json

# Expose port 3000
EXPOSE 3000

# Run the application
CMD ["yarn", "start"]
