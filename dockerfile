# Multi-stage Dockerfile for building DBGate using official Node.js slim images

# Builder stage
FROM node:22 AS builder

# Install git for cloning the repository
RUN apt-get update && apt-get install -y --no-install-recommends git && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Clone the DBGate repository
RUN git clone https://github.com/dbgate/dbgate.git .

# Install dependencies
RUN yarn install --immutable --immutable-cache

# Prepare for community edition and Docker build
RUN node adjustPackageJson --community
RUN yarn prepare:docker

# Runtime stage
FROM node:22-slim

# Install required system packages (equivalent to official image)
# iputils-ping for ping, iproute2 for networking, unixodbc for ODBC support (e.g., SQL Server)
RUN apt-get update && apt-get install -y --no-install-recommends \
    iputils-ping \
    iproute2 \
    unixodbc \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /home/dbgate-docker

# Copy built artifacts from the docker/ directory prepared in builder stage
COPY --from=builder /app/docker .

# Ensure entrypoint is executable
RUN chmod +x entrypoint.sh

# Add label for source
LABEL org.opencontainers.image.source="https://github.com/dbgate/dbgate"

# Expose the default port
EXPOSE 3000

# Use the entrypoint script
ENTRYPOINT ["/home/dbgate-docker/entrypoint.sh"]
