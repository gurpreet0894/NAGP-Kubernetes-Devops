# Use Node.js 18 Alpine for minimal image size
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy application code
COPY server.js ./

# Expose port
EXPOSE 3000

# Start application
CMD ["node", "server.js"]
