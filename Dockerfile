# ---- Base Stage: Install Dependencies ----
FROM node:22 AS builder

# Set working directory
WORKDIR /app

# Copy package.json and yarn.lock first (to use Docker's cache)
COPY package.json yarn.lock ./

# Install dependencies (faster builds due to caching)
RUN yarn install --frozen-lockfile

# Copy the rest of the application code
COPY . .

# Build the application
RUN yarn build

# ---- Production Runner ----
FROM node:22 AS runner

# Set working directory
WORKDIR /app

# Copy only the necessary built files and dependencies
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json

# Expose port 3000
EXPOSE 3000

# Run the app
CMD ["yarn", "start"]
