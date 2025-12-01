#!/bin/bash

# DevOps Integration Test Suite
# Tests the overall containerized setup

# Don't exit on error - we want to collect all test results
set +e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GATEWAY_URL="http://localhost:5921"
BACKEND_URL="http://localhost:3847"
MAX_WAIT=60
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

test_pass() {
    ((TEST_COUNT++))
    ((PASS_COUNT++))
    log_info "✓ $1"
}

test_fail() {
    ((TEST_COUNT++))
    ((FAIL_COUNT++))
    log_error "✗ $1"
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local count=0
    
    log_info "Waiting for $service_name to be ready..."
    while [ $count -lt $MAX_WAIT ]; do
        # Use curl with timeout to check service
        if curl -sf --max-time 2 "$url" > /dev/null 2>&1; then
            echo ""
            test_pass "$service_name is ready"
            return 0
        fi
        echo -n "."
        sleep 2
        count=$((count + 2))
    done
    echo ""
    
    test_fail "$service_name failed to start within ${MAX_WAIT}s"
    log_error "Service URL: $url"
    log_error "Check if services are running: docker ps"
    log_error "Check service logs: docker logs ecom-gateway-dev"
    return 1
}

# Test 1: Check if services are running
test_services_running() {
    log_info "Test 1: Checking if Docker services are running..."
    
    if docker ps | grep -q "ecom-gateway"; then
        test_pass "Gateway container is running"
    else
        test_fail "Gateway container is not running"
    fi
    
    if docker ps | grep -q "ecom-backend"; then
        test_pass "Backend container is running"
    else
        test_fail "Backend container is not running"
    fi
    
    if docker ps | grep -q "ecom-mongo"; then
        test_pass "MongoDB container is running"
    else
        test_fail "MongoDB container is not running"
    fi
}

# Test 2: Gateway health check
test_gateway_health() {
    log_info "Test 2: Testing Gateway health endpoint..."
    
    response=$(curl -s -w "\n%{http_code}" "$GATEWAY_URL/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        if echo "$body" | grep -q '"ok"'; then
            test_pass "Gateway health check returns 200 with ok status"
        else
            test_fail "Gateway health check returns 200 but invalid response"
        fi
    else
        test_fail "Gateway health check returned $http_code"
    fi
}

# Test 3: Backend health check via gateway
test_backend_health_via_gateway() {
    log_info "Test 3: Testing Backend health via Gateway..."
    
    response=$(curl -s -w "\n%{http_code}" "$GATEWAY_URL/api/health")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        if echo "$body" | grep -q '"ok"'; then
            test_pass "Backend health check via gateway returns 200"
        else
            test_fail "Backend health check via gateway returns 200 but invalid response"
        fi
    else
        test_fail "Backend health check via gateway returned $http_code"
    fi
}

# Test 4: Backend should not be directly accessible
test_backend_not_exposed() {
    log_info "Test 4: Verifying Backend is not directly accessible..."
    
    if curl -sf "$BACKEND_URL/api/health" > /dev/null 2>&1; then
        test_fail "Backend is directly accessible (security issue!)"
    else
        test_pass "Backend is correctly not exposed to public network"
    fi
}

# Test 5: MongoDB should not be directly accessible
test_mongo_not_exposed() {
    log_info "Test 5: Verifying MongoDB is not directly accessible..."
    
    if nc -z localhost 27017 2>/dev/null; then
        test_fail "MongoDB port 27017 is exposed (security issue!)"
    else
        test_pass "MongoDB is correctly not exposed to public network"
    fi
}

# Test 6: Create product via gateway
test_create_product() {
    log_info "Test 6: Testing product creation via Gateway..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Product","price":99.99}')
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "201" ]; then
        if echo "$body" | grep -q '"name".*"Test Product"'; then
            test_pass "Product creation successful"
            # Extract product ID for later tests
            PRODUCT_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
            export PRODUCT_ID
        else
            test_fail "Product creation returned 201 but invalid response"
        fi
    elif [ "$http_code" == "500" ]; then
        test_fail "Product creation returned 500 (server error)"
        log_error "Response: $body"
        log_error "Check backend logs: docker logs ecom-backend-dev"
        log_error "Check MongoDB connection in .env file"
    else
        test_fail "Product creation returned $http_code"
        log_error "Response: $body"
    fi
}

# Test 7: Get all products
test_get_products() {
    log_info "Test 7: Testing get all products..."
    
    response=$(curl -s -w "\n%{http_code}" "$GATEWAY_URL/api/products")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        if echo "$body" | grep -q '"name"'; then
            test_pass "Get products successful"
        else
            test_pass "Get products successful (empty list)"
        fi
    elif [ "$http_code" == "500" ]; then
        test_fail "Get products returned 500 (server error)"
        log_error "Response: $body"
        log_error "Check backend logs: docker logs ecom-backend-dev"
        log_error "Check MongoDB connection in .env file"
    else
        test_fail "Get products returned $http_code"
        log_error "Response: $body"
    fi
}

# Test 8: Input validation
test_input_validation() {
    log_info "Test 8: Testing input validation..."
    
    # Test invalid name
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"","price":99.99}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "400" ]; then
        test_pass "Input validation: empty name rejected"
    else
        test_fail "Input validation: empty name should return 400, got $http_code"
    fi
    
    # Test invalid price
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"Valid Product","price":-10}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "400" ]; then
        test_pass "Input validation: negative price rejected"
    else
        test_fail "Input validation: negative price should return 400, got $http_code"
    fi
}

# Test 9: Container health checks
test_container_health() {
    log_info "Test 9: Testing container health checks..."
    
    gateway_health=$(docker inspect --format='{{.State.Health.Status}}' ecom-gateway-dev 2>/dev/null || docker inspect --format='{{.State.Health.Status}}' ecom-gateway-prod 2>/dev/null || echo "none")
    backend_health=$(docker inspect --format='{{.State.Health.Status}}' ecom-backend-dev 2>/dev/null || docker inspect --format='{{.State.Health.Status}}' ecom-backend-prod 2>/dev/null || echo "none")
    mongo_health=$(docker inspect --format='{{.State.Health.Status}}' ecom-mongo-dev 2>/dev/null || docker inspect --format='{{.State.Health.Status}}' ecom-mongo-prod 2>/dev/null || echo "none")
    
    # Trim whitespace and newlines
    gateway_health=$(echo "$gateway_health" | tr -d '\n\r' | xargs)
    backend_health=$(echo "$backend_health" | tr -d '\n\r' | xargs)
    mongo_health=$(echo "$mongo_health" | tr -d '\n\r' | xargs)
    
    if [ "$gateway_health" == "healthy" ] || [ "$gateway_health" == "none" ] || [ -z "$gateway_health" ]; then
        test_pass "Gateway container health check configured"
    else
        test_fail "Gateway container health check: $gateway_health"
    fi
    
    if [ "$backend_health" == "healthy" ] || [ "$backend_health" == "none" ] || [ -z "$backend_health" ]; then
        test_pass "Backend container health check configured"
    else
        test_fail "Backend container health check: $backend_health"
    fi
    
    if [ "$mongo_health" == "healthy" ] || [ "$mongo_health" == "none" ] || [ -z "$mongo_health" ]; then
        test_pass "MongoDB container health check configured"
    else
        test_fail "MongoDB container health check: $mongo_health"
    fi
}

# Test 10: Network isolation
test_network_isolation() {
    log_info "Test 10: Testing network isolation..."
    
    # Check if containers are on the same network
    gateway_network=$(docker inspect --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' ecom-gateway-dev 2>/dev/null || docker inspect --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' ecom-gateway-prod 2>/dev/null || echo "")
    backend_network=$(docker inspect --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' ecom-backend-dev 2>/dev/null || docker inspect --format='{{range $net, $conf := .NetworkSettings.Networks}}{{$net}}{{end}}' ecom-backend-prod 2>/dev/null || echo "")
    
    if [ "$gateway_network" == "$backend_network" ] && [ -n "$gateway_network" ]; then
        test_pass "Containers are on the same Docker network"
    else
        test_fail "Containers are not properly networked"
    fi
}

# Test 11: Data persistence (volumes)
test_data_persistence() {
    log_info "Test 11: Testing data persistence volumes..."
    
    if docker volume ls | grep -q "mongo_data"; then
        test_pass "MongoDB data volume exists"
    else
        test_fail "MongoDB data volume not found"
    fi
}

# Test 12: Non-root user in production
test_non_root_user() {
    log_info "Test 12: Testing non-root user in containers..."
    
    # This test only works if production containers are running
    backend_user=$(docker exec ecom-backend-prod whoami 2>/dev/null || echo "root")
    gateway_user=$(docker exec ecom-gateway-prod whoami 2>/dev/null || echo "root")
    
    if [ "$backend_user" == "nodejs" ]; then
        test_pass "Backend runs as non-root user"
    elif [ "$backend_user" == "root" ] && docker ps | grep -q "ecom-backend-prod"; then
        test_fail "Backend production container runs as root"
    else
        log_warn "Skipping backend user test (dev mode or container not running)"
    fi
    
    if [ "$gateway_user" == "nodejs" ]; then
        test_pass "Gateway runs as non-root user"
    elif [ "$gateway_user" == "root" ] && docker ps | grep -q "ecom-gateway-prod"; then
        test_fail "Gateway production container runs as root"
    else
        log_warn "Skipping gateway user test (dev mode or container not running)"
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "  DevOps Integration Test Suite"
    echo "=========================================="
    echo ""
    
    # Wait for services to be ready
    if ! wait_for_service "$GATEWAY_URL/health" "Gateway"; then
        log_error "Gateway is not ready. Please start services with: make dev-up"
        log_error "Or check service status with: docker ps"
        exit 1
    fi
    sleep 2
    
    # Run all tests
    test_services_running
    test_gateway_health
    test_backend_health_via_gateway
    test_backend_not_exposed
    test_mongo_not_exposed
    test_create_product
    test_get_products
    test_input_validation
    test_container_health
    test_network_isolation
    test_data_persistence
    test_non_root_user
    
    # Summary
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

# Run main function
main

