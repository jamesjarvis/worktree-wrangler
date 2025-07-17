#!/bin/zsh

# Test environment setup script
# Creates isolated test environment with sample git repositories

set -e

echo "Setting up test environment..."

# Create isolated test directories
export TEST_HOME="/tmp/worktree-wrangler-test-$$"
export TEST_PROJECTS="$TEST_HOME/projects"
export TEST_CONFIG="$TEST_HOME/.local/share/worktree-wrangler"

mkdir -p "$TEST_HOME"
mkdir -p "$TEST_PROJECTS" 
mkdir -p "$TEST_CONFIG"

echo "Test directories created at: $TEST_HOME"

# Create sample git repositories for testing
create_test_repo() {
    local repo_name="$1"
    local repo_path="$TEST_PROJECTS/$repo_name"
    
    echo "Creating test repo: $repo_name"
    mkdir -p "$repo_path"
    cd "$repo_path"
    
    git init
    echo "# $repo_name" > README.md
    echo "Initial content for $repo_name" > file.txt
    git add .
    git commit -m "Initial commit"
    
    # Create a feature branch
    git checkout -b feature/test-branch
    echo "Feature content" >> file.txt
    git add .
    git commit -m "Add feature content"
    git checkout main
}

# Create test repositories
create_test_repo "test-project-1"
create_test_repo "test-project-2"
create_test_repo "empty-project"

# Create legacy core-wts directory structure for compatibility testing
mkdir -p "$TEST_PROJECTS/core-wts"

echo "Test environment setup complete!"
echo "TEST_HOME: $TEST_HOME"
echo "TEST_PROJECTS: $TEST_PROJECTS"
echo ""
echo "To clean up: rm -rf $TEST_HOME"