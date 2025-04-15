# Use the official Node.js image
FROM node:18-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the source code
COPY . .

# Build the TypeScript application
RUN npm run build

# Use a smaller image for the final stage
FROM node:18-alpine

# Set the working directory
WORKDIR /app

# Copy built files and package files from the builder stage
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Indicate that NOTION_API_TOKEN is required but don't set a value
# This should be provided via Coolify environment variables
ENV NOTION_API_TOKEN=""

# Expose port 3000 (le port par défaut du serveur MCP)
EXPOSE 3000

# Command to run the application
CMD ["node", "dist/index.js"]
