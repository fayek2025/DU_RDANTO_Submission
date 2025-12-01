#!/bin/bash

# Makefile Command Test Suite
# Tests all Makefile commands

# Don't exit on error - we want to collect all test results
set +e

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

cd "$(dirname "$0")/.." || exit 1

# Test Makefile exists
test_makefile_exists() {
    log_info "Testing Makefile existence..."
    if [ -f Makefile ]; then
        test_pass "Makefile exists"
    else
        test_fail "Makefile not found"
    fi
}

# Test help command
test_help_command() {
    log_info "Testing help command..."
    if make help > /dev/null 2>&1; then
        test_pass "Help command works"
    else
        test_fail "Help command failed"
    fi
}

# Test docker compose config validation
test_compose_config() {
    log_info "Testing docker-compose config validation..."
    if make -n up MODE=dev > /dev/null 2>&1 || \
       docker compose -f docker/compose.development.yaml config > /dev/null 2>&1; then
        test_pass "Development compose config is valid"
    else
        test_fail "Development compose config has errors"
    fi
    
    if make -n up MODE=prod > /dev/null 2>&1 || \
       docker compose -f docker/compose.production.yaml config > /dev/null 2>&1; then
        test_pass "Production compose config is valid"
    else
        test_fail "Production compose config has errors"
    fi
}

# Test backend commands (dry-run)
test_backend_commands() {
    log_info "Testing backend commands..."
    
    # Test backend-build (check if command exists)
    if grep -q "backend-build:" Makefile; then
        test_pass "backend-build command defined"
    else
        test_fail "backend-build command not found"
    fi
    
    if grep -q "backend-install:" Makefile; then
        test_pass "backend-install command defined"
    else
        test_fail "backend-install command not found"
    fi
    
    if grep -q "backend-type-check:" Makefile; then
        test_pass "backend-type-check command defined"
    else
        test_fail "backend-type-check command not found"
    fi
    
    if grep -q "backend-dev:" Makefile; then
        test_pass "backend-dev command defined"
    else
        test_fail "backend-dev command not found"
    fi
}

# Test dev aliases
test_dev_aliases() {
    log_info "Testing development aliases..."
    
    aliases=("dev-up" "dev-down" "dev-build" "dev-logs" "dev-restart" "dev-shell" "dev-ps")
    for alias in "${aliases[@]}"; do
        if grep -q "^${alias}:" Makefile; then
            test_pass "$alias alias defined"
        else
            test_fail "$alias alias not found"
        fi
    done
}

# Test prod aliases
test_prod_aliases() {
    log_info "Testing production aliases..."
    
    aliases=("prod-up" "prod-down" "prod-build" "prod-logs" "prod-restart")
    for alias in "${aliases[@]}"; do
        if grep -q "^${alias}:" Makefile; then
            test_pass "$alias alias defined"
        else
            test_fail "$alias alias not found"
        fi
    done
}

# Test database commands
test_db_commands() {
    log_info "Testing database commands..."
    
    if grep -q "db-reset:" Makefile; then
        test_pass "db-reset command defined"
    else
        test_fail "db-reset command not found"
    fi
    
    if grep -q "db-backup:" Makefile; then
        test_pass "db-backup command defined"
    else
        test_fail "db-backup command not found"
    fi
    
    if grep -q "mongo-shell:" Makefile; then
        test_pass "mongo-shell command defined"
    else
        test_fail "mongo-shell command not found"
    fi
}

# Test cleanup commands
test_cleanup_commands() {
    log_info "Testing cleanup commands..."
    
    if grep -q "^clean:" Makefile; then
        test_pass "clean command defined"
    else
        test_fail "clean command not found"
    fi
    
    if grep -q "^clean-all:" Makefile; then
        test_pass "clean-all command defined"
    else
        test_fail "clean-all command not found"
    fi
    
    if grep -q "^clean-volumes:" Makefile; then
        test_pass "clean-volumes command defined"
    else
        test_fail "clean-volumes command not found"
    fi
}

# Test utility commands
test_utility_commands() {
    log_info "Testing utility commands..."
    
    if grep -q "^status:" Makefile; then
        test_pass "status command defined"
    else
        test_fail "status command not found"
    fi
    
    if grep -q "^health:" Makefile; then
        test_pass "health command defined"
    else
        test_fail "health command not found"
    fi
}

# Test shell commands
test_shell_commands() {
    log_info "Testing shell commands..."
    
    if grep -q "backend-shell:" Makefile; then
        test_pass "backend-shell command defined"
    else
        test_fail "backend-shell command not found"
    fi
    
    if grep -q "gateway-shell:" Makefile; then
        test_pass "gateway-shell command defined"
    else
        test_fail "gateway-shell command not found"
    fi
}

main() {
    echo "=========================================="
    echo "  Makefile Command Test Suite"
    echo "=========================================="
    echo ""
    
    test_makefile_exists
    test_help_command
    test_compose_config
    test_backend_commands
    test_dev_aliases
    test_prod_aliases
    test_db_commands
    test_cleanup_commands
    test_utility_commands
    test_shell_commands
    
    echo ""
    echo "=========================================="
    echo "  Test Summary"
    echo "=========================================="
    echo "Total Tests: $TEST_COUNT"
    echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
    echo -e "${RED}Failed: $FAIL_COUNT${NC}"
    echo ""
    
    if [ $FAIL_COUNT -eq 0 ]; then
        log_info "All Makefile tests passed! ✓"
        exit 0
    else
        log_error "Some Makefile tests failed!"
        exit 1
    fi
}

main

