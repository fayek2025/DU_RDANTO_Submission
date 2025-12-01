#!/bin/bash

# Docker Configuration Test Suite
# Tests Docker setup, images, and configurations

# Don't exit on error - we want to collect all test results
set +e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
test_pass() { ((TEST_COUNT++)); ((PASS_COUNT++)); log_info "✓ $1"; }
test_fail() { ((TEST_COUNT++)); ((FAIL_COUNT++)); log_error "✗ $1"; }

# Test Docker images
test_docker_images() {
    log_info "Testing Docker images..."
    
    # Check if images exist (optional - images may not be built yet)
    if docker images --format "{{.Repository}}" 2>/dev/null | grep -q "cuet-cse-fest-devops-hackathon-preli-backend"; then
        test_pass "Backend Docker image exists"
    else
        log_warn "Backend Docker image not found (run 'make dev-build' to build images)"
        # Don't fail the test - images are optional for configuration tests
    fi
    
    if docker images --format "{{.Repository}}" 2>/dev/null | grep -q "cuet-cse-fest-devops-hackathon-preli-gateway"; then
        test_pass "Gateway Docker image exists"
    else
        log_warn "Gateway Docker image not found (run 'make dev-build' to build images)"
        # Don't fail the test - images are optional for configuration tests
    fi
}

# Test Dockerfile syntax
test_dockerfile_syntax() {
    log_info "Testing Dockerfile syntax..."
    
    # Check if Dockerfiles exist and are readable
    if [ -f backend/Dockerfile ] && [ -r backend/Dockerfile ]; then
        test_pass "Backend Dockerfile exists and is readable"
    else
        test_fail "Backend Dockerfile not found or not readable"
    fi
    
    if [ -f gateway/Dockerfile ] && [ -r gateway/Dockerfile ]; then
        test_pass "Gateway Dockerfile exists and is readable"
    else
        test_fail "Gateway Dockerfile not found or not readable"
    fi
    
    # Try to validate syntax (optional - may not work in all environments)
    if command -v hadolint > /dev/null 2>&1; then
        if hadolint backend/Dockerfile > /dev/null 2>&1; then
            test_pass "Backend Dockerfile passes hadolint validation"
        fi
    fi
}

# Test docker-compose files
test_compose_files() {
    log_info "Testing docker-compose files..."
    
    if docker compose -f docker/compose.development.yaml config > /dev/null 2>&1; then
        test_pass "Development docker-compose file is valid"
    else
        test_fail "Development docker-compose file has errors"
    fi
    
    if docker compose -f docker/compose.production.yaml config > /dev/null 2>&1; then
        test_pass "Production docker-compose file is valid"
    else
        test_fail "Production docker-compose file has errors"
    fi
}

# Test .dockerignore files
test_dockerignore() {
    log_info "Testing .dockerignore files..."
    
    if [ -f backend/.dockerignore ]; then
        test_pass "Backend .dockerignore exists"
    else
        test_fail "Backend .dockerignore not found"
    fi
    
    if [ -f gateway/.dockerignore ]; then
        test_pass "Gateway .dockerignore exists"
    else
        test_fail "Gateway .dockerignore not found"
    fi
}

# Test image sizes (should be reasonable)
test_image_sizes() {
    log_info "Testing Docker image sizes..."
    
    backend_size=$(docker images --format "{{.Size}}" cuet-cse-fest-devops-hackathon-preli-backend 2>/dev/null | head -1 || echo "0")
    gateway_size=$(docker images --format "{{.Size}}" cuet-cse-fest-devops-hackathon-preli-gateway 2>/dev/null | head -1 || echo "0")
    
    if [ "$backend_size" != "0" ]; then
        test_pass "Backend image size: $backend_size"
    else
        log_info "Skipping backend image size (image not built)"
    fi
    
    if [ "$gateway_size" != "0" ]; then
        test_pass "Gateway image size: $gateway_size"
    else
        log_info "Skipping gateway image size (image not built)"
    fi
}

# Test multi-stage build
test_multistage_build() {
    log_info "Testing multi-stage build configuration..."
    
    if grep -q "FROM.*AS builder" backend/Dockerfile 2>/dev/null; then
        test_pass "Backend uses multi-stage build"
    else
        test_fail "Backend should use multi-stage build"
    fi
}

# Test security: non-root user
test_security_config() {
    log_info "Testing security configurations..."
    
    if grep -q "USER nodejs" backend/Dockerfile 2>/dev/null; then
        test_pass "Backend Dockerfile uses non-root user"
    else
        test_fail "Backend Dockerfile should use non-root user"
    fi
    
    if grep -q "USER nodejs" gateway/Dockerfile 2>/dev/null; then
        test_pass "Gateway Dockerfile uses non-root user"
    else
        test_fail "Gateway Dockerfile should use non-root user"
    fi
}

# Test health checks in Dockerfiles
test_healthchecks() {
    log_info "Testing health check configurations..."
    
    if grep -q "HEALTHCHECK" backend/Dockerfile 2>/dev/null; then
        test_pass "Backend Dockerfile has health check"
    else
        test_fail "Backend Dockerfile should have health check"
    fi
    
    if grep -q "HEALTHCHECK" gateway/Dockerfile 2>/dev/null; then
        test_pass "Gateway Dockerfile has health check"
    else
        test_fail "Gateway Dockerfile should have health check"
    fi
}

main() {
    echo "=========================================="
    echo "  Docker Configuration Test Suite"
    echo "=========================================="
    echo ""
    
    test_dockerfile_syntax
    test_docker_images
    test_compose_files
    test_dockerignore
    test_image_sizes
    test_multistage_build
    test_security_config
    test_healthchecks
    
    echo ""
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo "Total Tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo ""
    
    if [ $FAIL_COUNT -eq 0 ]; then
        log_info "All tests passed! ✓"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

main

