# Hackathon Challenge

Your challenge is to take this simple e-commerce backend and turn it into a fully containerized microservices setup using Docker and solid DevOps practices.

## Problem Statement

The backend setup consisting of:

- A service for managing products
- A gateway that forwards API requests

The system must be containerized, secure, optimized, and maintain data persistence across container restarts.

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

**Key Points:**
- Gateway is the only service exposed to external clients (port 5921)
- All external requests must go through the Gateway
- Backend and MongoDB should not be exposed to public network


## Prerequisites

Before you begin, ensure you have the following installed:

- **Docker** (version 20.10 or higher)
- **Docker Compose** (version 2.0 or higher)
- **Make** (for using Makefile commands)
- **curl** (for testing endpoints, optional)

To verify your installation:
```bash
docker --version
docker compose version
make --version
```

## Getting Started

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd cuet-cse-fest-devops-hackathon-preli
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

**Important:** 
- Change `MONGO_INITDB_ROOT_PASSWORD` to a secure password
- Update `MONGO_URI` to match your password
- The ports (3847 and 5921) must not be changed

### 3. Start the Services

#### Development Mode

```bash
# Start all services in development mode
make dev-up

# Or use the full command
make up MODE=dev
```

This will:
- Build Docker images for backend and gateway
- Start MongoDB, backend, and gateway services
- Enable hot-reload for development
- Create persistent volumes for data

#### Production Mode

```bash
# Start all services in production mode
make prod-up

# Or use the full command
make up MODE=prod
```

**Note:** Production mode uses optimized images and security hardening.

### 4. Verify Services are Running

```bash
# Check service status
make dev-ps
# or
docker ps

# Check service health
make health
```

You should see three containers running:
- `ecom-gateway-dev` (or `ecom-gateway-prod`)
- `ecom-backend-dev` (or `ecom-backend-prod`)
- `ecom-mongo-dev` (or `ecom-mongo-prod`)

### 5. Run Tests

```bash
# Run all test suites
make test

# Run individual test suites
make test-integration   # Integration tests
make test-api          # API tests
make test-docker       # Docker configuration tests
make test-makefile     # Makefile command tests
```

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

The following environment variables are required in your `.env` file:

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

## Expectations (Open ended, DO YOUR BEST!!!)

- Separate Dev and Prod configs
- Data Persistence
- Follow security basics (limit network exposure, sanitize input) 
- Docker Image Optimization
- Makefile CLI Commands for smooth dev and prod deploy experience (TRY TO COMPLETE THE COMMANDS COMMENTED IN THE Makefile)

**ADD WHAT EVER BEST PRACTICES YOU KNOW**

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

## Testing

### Automated Test Suites

Comprehensive test suites are available to validate the DevOps setup:

```bash
# Run all tests (recommended)
make test

# Run individual test suites
make test-integration   # Integration tests (requires services running)
make test-api          # API endpoint tests (requires services running)
make test-docker       # Docker configuration tests
make test-makefile     # Makefile command tests
```

**Test Coverage:**
- ✅ Service health and connectivity
- ✅ Network isolation and security
- ✅ API functionality and validation
- ✅ Docker configurations
- ✅ Makefile commands
- ✅ Data persistence
- ✅ Security best practices

See [scripts/README.md](scripts/README.md) for detailed test documentation.

### Manual Testing

Use the following curl commands to manually test your implementation.

#### Health Checks

Check gateway health:
```bash
curl http://localhost:5921/health
```

Check backend health via gateway:
```bash
curl http://localhost:5921/api/health
```

#### Product Management

Create a product:
```bash
curl -X POST http://localhost:5921/api/products \
  -H 'Content-Type: application/json' \
  -d '{"name":"Test Product","price":99.99}'
```

Get all products:
```bash
curl http://localhost:5921/api/products
```

#### Security Test

Verify backend is not directly accessible (should fail or be blocked):
```bash
curl http://localhost:3847/api/products
```

Expected: Connection refused or timeout (this is correct - backend should not be exposed)

## Project Structure

The project follows this structure (DO NOT CHANGE):

```
.
├── backend/                    # Backend service (TypeScript/Express)
│   ├── Dockerfile             # Production Dockerfile
│   ├── Dockerfile.dev         # Development Dockerfile
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
├── .gitignore                  # Git ignore rules
└── README.md                   # This file
```

## Submission Process

1. **Fork the Repository**
   - Fork this repository to your GitHub account
   - The repository must remain **private** during the contest

2. **Make Repository Public**
   - In the **last 5 minutes** of the contest, make your repository **public**
   - Repositories that remain private after the contest ends will not be evaluated

3. **Submit Repository URL**
   - Submit your repository URL at [arena.bongodev.com](https://arena.bongodev.com)
   - Ensure the URL is correct and accessible

4. **Code Evaluation**
   - All submissions will be both **automated and manually evaluated**
   - Plagiarism and code copying will result in disqualification

## Rules

- ⚠️ **NO COPYING**: All code must be your original work. Copying code from other participants or external sources will result in immediate disqualification.

- ⚠️ **NO POST-CONTEST COMMITS**: Pushing any commits to the git repository after the contest ends will result in **disqualification**. All work must be completed and committed before the contest deadline.

- ✅ **Repository Visibility**: Keep your repository private during the contest, then make it public in the last 5 minutes.

- ✅ **Submission Deadline**: Ensure your repository is public and submitted before the contest ends.

Good luck!

