# Test Scripts

This directory contains comprehensive test suites for validating the DevOps setup.

## Test Suites

### 1. `test.sh` - DevOps Integration Tests
Tests the overall containerized setup including:
- Service health checks
- Network isolation and security
- API functionality through gateway
- Data persistence
- Container configurations

**Usage:**
```bash
./scripts/test.sh
# or
make test-integration
```

**Requirements:**
- Services must be running (`make dev-up` or `make prod-up`)

### 2. `test-api.sh` - API Integration Tests
Tests API endpoints through the gateway:
- Product creation
- Product retrieval
- Input validation
- Response format validation
- Multiple product operations

**Usage:**
```bash
./scripts/test-api.sh
# or
make test-api
```

**Requirements:**
- Services must be running

### 3. `test-docker.sh` - Docker Configuration Tests
Tests Docker setup and configurations:
- Dockerfile syntax validation
- Docker image existence
- docker-compose file validation
- Security configurations (non-root users)
- Health check configurations
- Multi-stage build verification

**Usage:**
```bash
./scripts/test-docker.sh
# or
make test-docker
```

**Requirements:**
- Docker must be installed
- Docker images may need to be built first

### 4. `test-makefile.sh` - Makefile Command Tests
Tests all Makefile commands and aliases:
- Command definitions
- Development aliases
- Production aliases
- Database commands
- Cleanup commands
- Utility commands

**Usage:**
```bash
./scripts/test-makefile.sh
# or
make test-makefile
```

**Requirements:**
- Makefile must exist

### 5. `run-all-tests.sh` - Master Test Runner
Runs all test suites in sequence and provides a comprehensive summary.

**Usage:**
```bash
./scripts/run-all-tests.sh
# or
make test
```

## Running Tests

### Run All Tests
```bash
make test
```

### Run Individual Test Suites
```bash
make test-integration   # Integration tests
make test-api          # API tests
make test-docker       # Docker tests
make test-makefile    # Makefile tests
```

### Manual Execution
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Run individual tests
./scripts/test.sh
./scripts/test-api.sh
./scripts/test-docker.sh
./scripts/test-makefile.sh

# Or run all
./scripts/run-all-tests.sh
```

## Test Output

All test scripts provide:
- Color-coded output (green for pass, red for fail)
- Detailed test descriptions
- Summary statistics
- Exit codes (0 for success, 1 for failure)

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run DevOps Tests
  run: |
    make dev-up
    sleep 10
    make test
```

## Troubleshooting

### Services Not Running
If integration tests fail with "services not running":
```bash
make dev-up
# Wait for services to start
make test-integration
```

### Docker Not Available
If Docker tests fail:
- Ensure Docker is installed and running
- Check Docker daemon: `docker ps`
- Build images first: `make dev-build`

### Port Conflicts
If tests fail due to port conflicts:
- Check if ports 5921 or 3847 are in use
- Stop conflicting services
- Or modify test scripts to use different ports

## Test Coverage

The test suites cover:
- ✅ Service startup and health
- ✅ Network security and isolation
- ✅ API functionality
- ✅ Input validation
- ✅ Docker configurations
- ✅ Makefile commands
- ✅ Data persistence
- ✅ Security best practices

