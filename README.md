# E-Commerce Microservices - DevOps Implementation

This repository contains our submission for the DevOps hackathon challenge. We have transformed the simple e-commerce backend into a fully containerized microservices architecture with comprehensive DevOps best practices.

## Overview

We have implemented a production-ready microservices setup with:
- **API Gateway** - Single entry point for all external requests
- **Backend Service** - Product management service built with TypeScript/Express
- **MongoDB** - Persistent data storage with authentication
- **Complete DevOps Tooling** - Development and production configurations with comprehensive automation

## Architecture

```
                    ┌─────────────────┐
                    │   Client/User   │
                    └────────┬────────┘
                             │
                             │ HTTP (port 5921)
                             │
                    ┌────────▼────────┐
                    │    Gateway      │
                    │  (port 5921)    │
                    │   [Exposed]     │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │                 │
         ┌──────────▼──────────┐      │
         │   Private Network   │      │
         │  (Docker Network)   │      │
         └──────────┬──────────┘      │
                    │                 │
         ┌──────────┴──────────┐      │
         │                     │      │
    ┌────▼────┐         ┌──────▼──────┐
    │ Backend │         │   MongoDB   │
    │(port    │◄────────┤  (port      │
    │ 3847)   │         │  27017)     │
    │[Not     │         │ [Not        │
    │Exposed] │         │ Exposed]    │
    └─────────┘         └─────────────┘
```

**Key Security Features:**
- Gateway is the only service exposed to external clients (port 5921)
- Backend and MongoDB are isolated in a private Docker network
- All external requests must go through the Gateway
- Network isolation prevents direct access to internal services

## Features Implemented

### ✅ Separate Development and Production Configurations

- **Development Mode**: Hot-reload support, volume mounts for live code editing, development dependencies
- **Production Mode**: Optimized multi-stage builds, minimal images, security hardening, resource limits

### ✅ Data Persistence

- Named Docker volumes for MongoDB data (`mongo_data_dev`, `mongo_data_prod`)
- Separate volumes for development and production environments
- Data persists across container restarts and updates
- MongoDB configuration stored in persistent volumes

### ✅ Security Best Practices

- **Non-root users**: All services run as non-root users (UID 1001)
- **Read-only filesystems**: Production containers use read-only root filesystems with tmpfs for writable directories
- **Network isolation**: Backend and MongoDB are not exposed to the host network
- **Resource limits**: CPU and memory limits configured for all services
- **Security options**: `no-new-privileges` flag enabled to prevent privilege escalation
- **Input validation**: Request validation and sanitization in backend routes

### ✅ Docker Image Optimization

- **Multi-stage builds**: Production images use multi-stage builds to minimize final image size
- **Alpine base images**: All images use `node:20-alpine` for smaller footprint
- **Layer caching**: Optimized Dockerfile layer ordering for better build cache utilization
- **Production dependencies only**: Production images exclude dev dependencies
- **pnpm store pruning**: Removes unused packages after installation

### ✅ Comprehensive Makefile

All Makefile commands requested in the challenge have been implemented:

**Service Management:**
- `make dev-up` / `make prod-up` - Start services
- `make dev-down` / `make prod-down` - Stop services
- `make dev-build` / `make prod-build` - Build images
- `make dev-logs` / `make prod-logs` - View logs
- `make dev-restart` / `make prod-restart` - Restart services
- `make dev-shell` / `make shell` - Open container shell

**Database Operations:**
- `make mongo-shell` - Open MongoDB shell
- `make db-reset` - Reset database (with confirmation)
- `make db-backup` - Backup database

**Backend Development:**
- `make backend-build` - Build TypeScript
- `make backend-install` - Install dependencies
- `make backend-type-check` - Type check
- `make backend-dev` - Run locally

**Testing:**
- `make test` - Run all test suites
- `make test-integration` - Integration tests
- `make test-api` - API tests
- `make test-docker` - Docker configuration tests
- `make test-makefile` - Makefile command tests

**Utilities:**
- `make health` - Check service health
- `make ps` - Show running containers
- `make clean` - Remove containers and networks
- `make clean-all` - Full cleanup including volumes and images

### ✅ Health Checks

- All services include health check configurations
- Health checks verify service availability and database connectivity
- Proper startup periods and retry logic configured
- Health endpoints available at `/health` (gateway) and `/api/health` (backend)

### ✅ Comprehensive Testing Suite

We've implemented a complete testing framework:

- **Integration Tests** (`test.sh`): Service health, network isolation, data persistence
- **API Tests** (`test-api.sh`): Product CRUD operations, input validation
- **Docker Tests** (`test-docker.sh`): Dockerfile validation, security configurations
- **Makefile Tests** (`test-makefile.sh`): Command validation and functionality

All tests can be run with `make test` or individually.

## Prerequisites

To evaluate this submission, ensure you have:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Make** (for using Makefile commands)
- **curl** (for testing endpoints, optional)
- **jq** (for JSON parsing in health checks, optional)

Verify installation:
```bash
docker --version
docker compose version
make --version
```

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd DU_RDANTO_Submission
```

### 2. Set Up Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit the `.env` file with your MongoDB credentials:

```env
# MongoDB Configuration
MONGO_INITDB_ROOT_USERNAME=admin
MONGO_INITDB_ROOT_PASSWORD=changeme
MONGO_DATABASE=ecommerce
MONGO_URI=mongodb://admin:changeme@mongo:27017/ecommerce?authSource=admin

# Service Ports (DO NOT CHANGE)
BACKEND_PORT=3847
GATEWAY_PORT=5921

# Environment
NODE_ENV=development
```

**Note:** The ports (3847 and 5921) are fixed as per requirements and should not be changed.

### 3. Start the Services

#### Development Mode

```bash
make dev-up
```

This will:
- Build Docker images for backend and gateway
- Start MongoDB, backend, and gateway services
- Enable hot-reload for development
- Create persistent volumes for data

#### Production Mode

```bash
make prod-up
```

Production mode features:
- Optimized multi-stage builds
- Security hardening (non-root users, read-only filesystems)
- Resource limits
- Production-only dependencies

### 4. Verify Services

```bash
# Check service status
make dev-ps

# Check service health
make health
```

You should see three containers running:
- `ecom-gateway-dev` (or `ecom-gateway-prod`)
- `ecom-backend-dev` (or `ecom-backend-prod`)
- `ecom-mongo-dev` (or `ecom-mongo-prod`)

### 5. Run Tests

```bash
# Run all test suites (recommended)
make test

# Or run individual test suites
make test-integration   # Integration tests
make test-api          # API tests
make test-docker       # Docker configuration tests
make test-makefile     # Makefile command tests
```

## Project Structure

```
.
├── backend/                    # Backend service (TypeScript/Express)
│   ├── Dockerfile             # Production Dockerfile (multi-stage)
│   ├── Dockerfile.dev         # Development Dockerfile (hot-reload)
│   ├── package.json
│   ├── tsconfig.json
│   └── src/
│       ├── config/            # Configuration files
│       ├── models/            # MongoDB models
│       ├── routes/            # API routes
│       └── types/             # TypeScript types
├── gateway/                    # API Gateway (Node.js/Express)
│   ├── Dockerfile             # Production Dockerfile
│   ├── Dockerfile.dev         # Development Dockerfile
│   ├── package.json
│   └── src/
│       └── gateway.js         # Gateway proxy logic
├── docker/                     # Docker Compose configurations
│   ├── compose.development.yaml
│   └── compose.production.yaml
├── scripts/                     # Test and utility scripts
│   ├── test.sh                # Integration tests
│   ├── test-api.sh            # API tests
│   ├── test-docker.sh         # Docker tests
│   ├── test-makefile.sh       # Makefile tests
│   ├── run-all-tests.sh       # Master test runner
│   └── fix-mongo-auth.sh      # MongoDB auth fix script
├── Makefile                    # Build and deployment commands
├── .env.example                # Environment variables template
└── README.md                   # This file
```

## Key Implementation Details

### Development Configuration

**Features:**
- Hot-reload support using `tsx watch` for backend
- Volume mounts for live code editing
- Development dependencies included
- Faster startup times
- Detailed logging

**Docker Compose:** `docker/compose.development.yaml`

### Production Configuration

**Features:**
- Multi-stage builds for optimized images
- Non-root user execution (UID 1001)
- Read-only root filesystem with tmpfs for writable directories
- Resource limits (CPU and memory)
- Security options (`no-new-privileges`)
- Production-only dependencies
- Health checks with proper intervals

**Docker Compose:** `docker/compose.production.yaml`

### Security Measures

1. **Network Isolation**
   - Backend and MongoDB are not exposed to host network
   - Only gateway is accessible from outside (port 5921)
   - Services communicate via private Docker network

2. **Container Security**
   - Non-root users in all containers
   - Read-only filesystems in production
   - `no-new-privileges` security option
   - Resource limits to prevent resource exhaustion

3. **Input Validation**
   - Request body validation in backend routes
   - Type checking with TypeScript
   - MongoDB query sanitization

### Image Optimization

**Backend Production Image:**
- Multi-stage build (builder + production)
- Alpine base image (~5MB base)
- Only production dependencies
- Pre-built TypeScript (no build tools in final image)
- pnpm store pruning

**Gateway Production Image:**
- Alpine base image
- Only production dependencies
- Non-root user
- Minimal layers

## Testing

### Automated Test Suites

Our comprehensive test suite validates:

- ✅ Service health and connectivity
- ✅ Network isolation and security
- ✅ API functionality and validation
- ✅ Docker configurations
- ✅ Makefile commands
- ✅ Data persistence
- ✅ Security best practices

**Run all tests:**
```bash
make test
```

**Test Documentation:** See [scripts/README.md](scripts/README.md) for detailed test documentation.

### Manual Testing

#### Health Checks

```bash
# Gateway health
curl http://localhost:5921/health

# Backend health (via gateway)
curl http://localhost:5921/api/health
```

#### Product Management

```bash
# Create a product
curl -X POST http://localhost:5921/api/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Product","price":99.99}'

# Get all products
curl http://localhost:5921/api/products
```

#### Security Verification

Verify backend is not directly accessible (should fail):
```bash
curl http://localhost:3847/api/products
```

Expected: Connection refused or timeout (this confirms backend is not exposed)

## Common Commands

### Service Management

```bash
# Development
make dev-up          # Start development services
make dev-down        # Stop development services
make dev-build       # Build development images
make dev-logs        # View logs
make dev-restart     # Restart services
make dev-shell       # Open shell in backend container

# Production
make prod-up         # Start production services
make prod-down       # Stop production services
make prod-build      # Build production images
make prod-logs       # View logs
make prod-restart    # Restart services

# General
make up [service]    # Start services (default: dev)
make down [service]  # Stop services
make build [service] # Build images
make logs [service]  # View logs
make ps              # Show running containers
make restart         # Restart services
```

### Database Operations

```bash
# Open MongoDB shell
make mongo-shell

# Reset database (WARNING: deletes all data)
make db-reset

# Backup database
make db-backup
```

### Backend Development

```bash
# Build TypeScript
make backend-build

# Install dependencies
make backend-install

# Type check
make backend-type-check

# Run locally (outside Docker)
make backend-dev
```

### Cleanup

```bash
make clean           # Remove containers and networks
make clean-all       # Remove containers, networks, volumes, and images
make clean-volumes   # Remove all volumes
```

## Environment Variables

Required environment variables in `.env` file:

```env
MONGO_INITDB_ROOT_USERNAME=admin          # MongoDB root username
MONGO_INITDB_ROOT_PASSWORD=changeme       # MongoDB root password
MONGO_URI=mongodb://admin:changeme@mongo:27017/ecommerce?authSource=admin
MONGO_DATABASE=ecommerce                  # Database name
BACKEND_PORT=3847                         # DO NOT CHANGE
GATEWAY_PORT=5921                         # DO NOT CHANGE
NODE_ENV=development                      # or 'production'
```

**Security Note:** Never commit your `.env` file to version control. The `.env.example` file is provided as a template.

## Troubleshooting

### Services Won't Start

```bash
# Check if ports are already in use
lsof -i :5921  # Gateway port
lsof -i :3847  # Backend port (should not be accessible)

# Check Docker logs
make dev-logs
# or for specific service
docker logs ecom-gateway-dev
docker logs ecom-backend-dev
docker logs ecom-mongo-dev
```

### MongoDB Connection Issues

If you see authentication errors:

```bash
# Reset MongoDB with correct password
./scripts/fix-mongo-auth.sh

# Or manually:
make dev-down ARGS="--volumes"
# Update .env with correct password
make dev-up
```

### Container Health Issues

```bash
# Check container health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Restart unhealthy containers
make dev-restart
```

### Permission Issues

```bash
# Ensure scripts are executable
chmod +x scripts/*.sh

# Check Docker permissions
docker ps  # Should work without sudo
```

## Evaluation Checklist

For evaluators, here's what to verify:

### ✅ Requirements Met

- [x] Separate Dev and Prod configurations
- [x] Data persistence across restarts
- [x] Security basics (network isolation, input sanitization)
- [x] Docker image optimization (multi-stage builds, alpine images)
- [x] Complete Makefile with all commands
- [x] Health checks for all services
- [x] Comprehensive testing suite

### ✅ Best Practices Implemented

- [x] Non-root users in containers
- [x] Read-only filesystems in production
- [x] Resource limits configured
- [x] Security options enabled
- [x] Health checks with proper intervals
- [x] Multi-stage Docker builds
- [x] Layer caching optimization
- [x] Production dependency pruning
- [x] Network isolation
- [x] Input validation
- [x] Error handling
- [x] Comprehensive logging

## Additional Notes

- All code is original work
- Repository structure maintained as per requirements
- Ports 3847 and 5921 are fixed as specified
- Both development and production modes are fully functional
- All tests pass successfully
- Makefile commands are complete and tested

## Contact

For questions or issues during evaluation, please refer to the test scripts and documentation in the `scripts/` directory.

---

**Thank you for evaluating our submission!**
