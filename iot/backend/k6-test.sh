#!/bin/bash

# K6 Test Runner Script for SiSantri IoT Backend
# Usage: ./k6-test.sh [test-type]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${BASE_URL:-https://sisantri-backend.vercel.app}"
API_KEY="${API_KEY:-secret-api-key-here-f}"
DEVICE_ID="${DEVICE_ID:-rfid-reader-001}"
DEVICE_SECRET="${DEVICE_SECRET:-rfabid-012312345-secret}"

# Check if k6 is installed
if ! command -v k6 &> /dev/null; then
    echo -e "${RED}Error: k6 is not installed${NC}"
    echo "Please install k6 from: https://k6.io/docs/getting-started/installation/"
    echo ""
    echo "Quick install on macOS:"
    echo "  brew install k6"
    exit 1
fi

# Function to run test
run_test() {
    local test_file=$1
    local test_name=$2
    
    echo -e "${BLUE}=================================${NC}"
    echo -e "${GREEN}Running ${test_name}${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "Base URL: ${YELLOW}${BASE_URL}${NC}"
    echo -e "Test File: ${YELLOW}${test_file}${NC}"
    echo ""
    
    k6 run \
        -e BASE_URL="${BASE_URL}" \
        -e API_KEY="${API_KEY}" \
        -e DEVICE_ID="${DEVICE_ID}" \
        -e DEVICE_SECRET="${DEVICE_SECRET}" \
        --out "json=results/${test_name}-$(date +%Y%m%d-%H%M%S).json" \
        "${test_file}"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        echo -e "\n${GREEN}✓ ${test_name} completed successfully${NC}\n"
    else
        echo -e "\n${RED}✗ ${test_name} failed${NC}\n"
    fi
    
    return $exit_code
}

# Create results directory
mkdir -p results

# Main script
case "${1:-all}" in
    smoke)
        run_test "smoke-test.js" "Smoke Test"
        ;;
    load)
        run_test "load-test.js" "Load Test"
        ;;
    stress)
        run_test "stress-test.js" "Stress Test"
        ;;
    spike)
        run_test "spike-test.js" "Spike Test"
        ;;
    all)
        echo -e "${BLUE}Running all tests...${NC}\n"
        run_test "smoke-test.js" "Smoke Test" && \
        run_test "load-test.js" "Load Test" && \
        run_test "stress-test.js" "Stress Test" && \
        run_test "spike-test.js" "Spike Test"
        ;;
    *)
        echo -e "${RED}Invalid test type: $1${NC}"
        echo ""
        echo "Usage: $0 [test-type]"
        echo ""
        echo "Available test types:"
        echo "  smoke   - Quick validation test (1 VU, 30s)"
        echo "  load    - Load test with gradual ramp-up (up to 100 VUs)"
        echo "  stress  - Stress test pushing limits (up to 400 VUs)"
        echo "  spike   - Spike test with sudden traffic surge (up to 500 VUs)"
        echo "  all     - Run all tests sequentially (default)"
        echo ""
        echo "Environment variables:"
        echo "  BASE_URL       - API base URL (default: http://localhost:3000)"
        echo "  API_KEY        - API key for authentication"
        echo "  DEVICE_ID      - Device ID for authentication"
        echo "  DEVICE_SECRET  - Device secret for authentication"
        echo ""
        echo "Example:"
        echo "  BASE_URL=https://api.example.com API_KEY=abc123 $0 smoke"
        exit 1
        ;;
esac

exit $?
