FROM node:20-slim

# Enable Corepack to manage Yarn versions
RUN corepack enable

WORKDIR /app

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies using the correct Yarn version
RUN corepack prepare yarn@4.7.0 --activate && \
    yarn install --immutable

# Copy the rest of the application
COPY . .

# Build the application
RUN yarn build

# Expose the port your app runs on
EXPOSE 3000

# Start the application
CMD ["yarn", "start"]