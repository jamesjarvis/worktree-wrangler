#!/bin/bash

# Local test runner for Worktree Wrangler
# Supports both native execution and Docker

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_IMAGE="worktree-wrangler-test"
USE_DOCKER=${USE_DOCKER:-true}

echo -e "${BLUE}🧪 Worktree Wrangler Test Suite${NC}"
echo "=================================="

# Check if running with gh act
if [ "$GITHUB_ACTIONS" = "true" ] && [ "$ACT" = "true" ]; then
    echo -e "${YELLOW}Running with gh act${NC}"
    USE_DOCKER=false
fi

# Function to check if BATS is available
check_bats() {
    if command -v bats >/dev/null 2>&1; then
        echo -e "${GREEN}✅ BATS found: $(command -v bats)${NC}"
        return 0
    else
        echo -e "${RED}❌ BATS not found${NC}"
        return 1
    fi
}

# Function to install BATS
install_bats() {
    echo -e "${YELLOW}📦 Installing BATS...${NC}"
    
    if [ -d "/tmp/bats-core" ]; then
        rm -rf /tmp/bats-core
    fi
    
    git clone https://github.com/bats-core/bats-core.git /tmp/bats-core
    cd /tmp/bats-core
    sudo ./install.sh /usr/local
    cd - >/dev/null
    rm -rf /tmp/bats-core
    
    echo -e "${GREEN}✅ BATS installed${NC}"
}

# Function to run tests natively
run_tests_native() {
    echo -e "${BLUE}🏃 Running tests natively${NC}"
    
    if ! check_bats; then
        echo -e "${YELLOW}Installing BATS...${NC}"
        install_bats
    fi
    
    # Run tests
    echo -e "${BLUE}Starting test execution...${NC}"
    if bats tests.bats --tap; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        return 1
    fi
}

# Function to run tests in Docker
run_tests_docker() {
    echo -e "${BLUE}🐳 Running tests in Docker${NC}"
    
    # Check if Docker is available
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}❌ Docker not found. Install Docker or run with USE_DOCKER=false${NC}"
        exit 1
    fi
    
    # Build test image
    echo -e "${YELLOW}🔨 Building test container...${NC}"
    if docker build -t "$DOCKER_IMAGE" . >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Container built${NC}"
    else
        echo -e "${RED}❌ Failed to build container${NC}"
        exit 1
    fi
    
    # Run tests in container
    echo -e "${BLUE}Starting test execution...${NC}"
    if docker run --rm \
        -v "$(pwd)/..:/workspace" \
        -w /workspace/tests \
        "$DOCKER_IMAGE" \
        zsh -c "bats tests.bats --tap"; then
        echo -e "${GREEN}✅ All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        return 1
    fi
}

# Function to run quick test
run_quick_test() {
    echo -e "${BLUE}⚡ Running quick smoke test${NC}"
    
    # Just test that the script loads and shows version
    cd ..
    if zsh -c "source worktree-wrangler.zsh; w --version" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Quick test passed - script loads correctly${NC}"
        return 0
    else
        echo -e "${RED}❌ Quick test failed - script has syntax errors${NC}"
        return 1
    fi
}

# Main execution
case "${1:-full}" in
    "quick")
        run_quick_test
        ;;
    "native")
        USE_DOCKER=false
        run_tests_native
        ;;
    "docker")
        USE_DOCKER=true
        run_tests_docker
        ;;
    "full"|"")
        if [ "$USE_DOCKER" = "true" ]; then
            run_tests_docker
        else
            run_tests_native
        fi
        ;;
    "help")
        echo "Usage: $0 [quick|native|docker|full|help]"
        echo ""
        echo "  quick  - Run basic syntax check only"
        echo "  native - Run tests natively (installs BATS if needed)"
        echo "  docker - Run tests in Docker container"
        echo "  full   - Run full test suite (default, respects USE_DOCKER env var)"
        echo "  help   - Show this help"
        echo ""
        echo "Environment variables:"
        echo "  USE_DOCKER=false  - Force native execution"
        echo ""
        echo "Examples:"
        echo "  ./run-tests.sh quick          # Fast syntax check"
        echo "  ./run-tests.sh native         # Native execution"
        echo "  USE_DOCKER=false ./run-tests.sh  # Native execution"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo "Run '$0 help' for usage information"
        exit 1
        ;;
esac