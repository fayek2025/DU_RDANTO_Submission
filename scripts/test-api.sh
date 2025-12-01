#!/bin/bash

# API Integration Test Suite
# Tests API endpoints through the gateway

# Don't exit on error - we want to collect all test results
set +e

GATEWAY_URL="http://localhost:5921"
TEST_COUNT=0
PASS_COUNT=0
FAIL_COUNT=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
test_pass() { ((TEST_COUNT++)); ((PASS_COUNT++)); log_info "✓ $1"; }
test_fail() { ((TEST_COUNT++)); ((FAIL_COUNT++)); log_error "✗ $1"; }

# Test product creation
test_create_product() {
    log_info "Testing product creation..."
    
    response=$(curl -s -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"API Test Product","price":29.99}' \
        -w "\n%{http_code}")
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "201" ]; then
        PRODUCT_ID=$(echo "$body" | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)
        export PRODUCT_ID
        test_pass "Product created successfully (ID: $PRODUCT_ID)"
        return 0
    else
        test_fail "Product creation failed with status $http_code"
        echo "Response: $body"
        return 1
    fi
}

# Test get all products
test_get_all_products() {
    log_info "Testing get all products..."
    
    response=$(curl -s -w "\n%{http_code}" "$GATEWAY_URL/api/products")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" == "200" ]; then
        product_count=$(echo "$body" | grep -o '"name"' | wc -l)
        test_pass "Retrieved products successfully (count: $product_count)"
    else
        test_fail "Get products failed with status $http_code"
    fi
}

# Test input validation - empty name
test_validation_empty_name() {
    log_info "Testing validation: empty name..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"","price":10.00}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "400" ]; then
        test_pass "Empty name correctly rejected"
    else
        test_fail "Empty name should return 400, got $http_code"
    fi
}

# Test input validation - missing name
test_validation_missing_name() {
    log_info "Testing validation: missing name..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"price":10.00}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "400" ] || [ "$http_code" == "500" ]; then
        test_pass "Missing name correctly rejected"
    else
        test_fail "Missing name should return 400/500, got $http_code"
    fi
}

# Test input validation - negative price
test_validation_negative_price() {
    log_info "Testing validation: negative price..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Product","price":-5.00}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "400" ]; then
        test_pass "Negative price correctly rejected"
    else
        test_fail "Negative price should return 400, got $http_code"
    fi
}

# Test input validation - invalid price type
test_validation_invalid_price() {
    log_info "Testing validation: invalid price type..."
    
    response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Product","price":"not-a-number"}')
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "400" ] || [ "$http_code" == "500" ]; then
        test_pass "Invalid price type correctly rejected"
    else
        test_fail "Invalid price should return 400/500, got $http_code"
    fi
}

# Test multiple product creation
test_multiple_products() {
    log_info "Testing multiple product creation..."
    
    for i in {1..5}; do
        response=$(curl -s -w "\n%{http_code}" -X POST "$GATEWAY_URL/api/products" \
            -H "Content-Type: application/json" \
            -d "{\"name\":\"Product $i\",\"price\":$((i * 10)).99}")
        http_code=$(echo "$response" | tail -n1)
        
        if [ "$http_code" != "201" ]; then
            test_fail "Failed to create product $i (status: $http_code)"
            return 1
        fi
    done
    
    test_pass "Successfully created 5 products"
}

# Test response format
test_response_format() {
    log_info "Testing response format..."
    
    response=$(curl -s -X POST "$GATEWAY_URL/api/products" \
        -H "Content-Type: application/json" \
        -d '{"name":"Format Test","price":15.50}')
    
    if echo "$response" | grep -q '"_id"'; then
        test_pass "Response includes _id field"
    else
        test_fail "Response missing _id field"
    fi
    
    if echo "$response" | grep -q '"name".*"Format Test"'; then
        test_pass "Response includes name field"
    else
        test_fail "Response missing or incorrect name field"
    fi
    
    if echo "$response" | grep -q '"price".*15.5'; then
        test_pass "Response includes price field"
    else
        test_fail "Response missing or incorrect price field"
    fi
}

# Test gateway proxy functionality
test_gateway_proxy() {
    log_info "Testing gateway proxy functionality..."
    
    # Test that gateway forwards requests correctly
    response=$(curl -s -w "\n%{http_code}" "$GATEWAY_URL/api/products")
    http_code=$(echo "$response" | tail -n1)
    
    if [ "$http_code" == "200" ]; then
        test_pass "Gateway successfully proxies requests to backend"
    else
        test_fail "Gateway proxy failed (status: $http_code)"
    fi
}

main() {
    echo "=========================================="
    echo "  API Integration Test Suite"
    echo "=========================================="
    echo ""
    
    # Wait for gateway to be ready
    log_info "Waiting for gateway to be ready..."
    for i in {1..30}; do
        if curl -sf "$GATEWAY_URL/health" > /dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    test_create_product
    test_get_all_products
    test_validation_empty_name
    test_validation_missing_name
    test_validation_negative_price
    test_validation_invalid_price
    test_multiple_products
    test_response_format
    test_gateway_proxy
    
    echo ""
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo "Total Tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo ""
    
    if [ $FAIL_COUNT -eq 0 ]; then
        log_info "All API tests passed! ✓"
        exit 0
    else
        log_error "Some API tests failed!"
        exit 1
    fi
}

main

