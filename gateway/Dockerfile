# Production Dockerfile for gateway
FROM node:20-alpine

# Install pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Create app directory
WORKDIR /app

# Copy package files
COPY package*.json pnpm-lock.yaml* ./

# Install only production dependencies
RUN pnpm install --prod --frozen-lockfile && \
    pnpm store prune

# Copy source code
COPY src ./src

# Change ownership to non-root user
RUN chown -R nodejs:nodejs /app

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 5921

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:5921/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start the application
CMD ["node", "src/gateway.js"]

