#!/bin/bash

# Master test runner - runs all test suites

# Don't exit on error - we want to run all test suites and collect results
set +e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[TEST RUNNER]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

run_test_suite() {
    local test_name=$1
    local test_script=$2
    
    log_info "Running $test_name..."
    echo "----------------------------------------"
    
    if [ -f "$test_script" ] && [ -x "$test_script" ]; then
        # Run the test and capture exit code
        bash "$test_script"
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            ((PASSED_TESTS++))
            log_success "$test_name passed"
        else
            ((FAILED_TESTS++))
            log_error "$test_name failed (exit code: $exit_code)"
        fi
    else
        log_error "$test_name script not found or not executable: $test_script"
        ((FAILED_TESTS++))
    fi
    
    ((TOTAL_TESTS++))
    echo ""
}

main() {
    echo "=========================================="
    echo "  DevOps Test Suite Runner"
    echo "=========================================="
    echo ""
    
    # Make scripts executable
    chmod +x scripts/*.sh 2>/dev/null || true
    
    # Run test suites
    run_test_suite "Makefile Commands" "scripts/test-makefile.sh"
    run_test_suite "Docker Configuration" "scripts/test-docker.sh"
    
    # Check if services are running before running integration tests
    if docker ps | grep -q "ecom-gateway"; then
        run_test_suite "API Integration" "scripts/test-api.sh"
        run_test_suite "DevOps Integration" "scripts/test.sh"
    else
        log_info "Skipping integration tests (services not running)"
        log_info "Start services with: make dev-up"
    fi
    
    # Summary
    echo "=========================================="
    echo "  Overall Test Summary"
    echo "=========================================="
    echo "Total Test Suites: $TOTAL_TESTS"
    echo -e "${GREEN}Passed: $PASSED_TESTS${NC}"
    echo -e "${RED}Failed: $FAILED_TESTS${NC}"
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "All test suites passed! ✓"
        exit 0
    else
        log_error "Some test suites failed!"
        exit 1
    fi
}

main

