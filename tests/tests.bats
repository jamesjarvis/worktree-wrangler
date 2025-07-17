#!/usr/bin/env bats

# Worktree Wrangler Test Suite
# Tests all core functionality in isolated environment

# Setup and teardown
setup() {
    # Source the test environment setup
    export ORIGINAL_HOME="$HOME"
    
    # Create unique test environment for this test
    export TEST_HOME="/tmp/worktree-wrangler-test-$$-$BATS_TEST_NUMBER"
    export HOME="$TEST_HOME"
    export TEST_PROJECTS="$TEST_HOME/projects"
    
    # Create test directories
    mkdir -p "$TEST_PROJECTS"
    mkdir -p "$TEST_HOME/.local/share/worktree-wrangler"
    
    # Copy worktree-wrangler script to test environment
    cp "$BATS_TEST_DIRNAME/../worktree-wrangler.zsh" "$TEST_HOME/"
    
    # Create a helper function to run w commands in zsh
    w() {
        zsh -c "source '$TEST_HOME/worktree-wrangler.zsh'; w $*"
    }
    
    # Create test git repo
    mkdir -p "$TEST_PROJECTS/testproject"
    cd "$TEST_PROJECTS/testproject"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "# Test Project" > README.md
    git add .
    git commit -m "Initial commit"
    cd "$TEST_HOME"
    
    # Configure w to use test projects directory
    w --config projects "$TEST_PROJECTS"
}

teardown() {
    # Clean up test environment
    export HOME="$ORIGINAL_HOME"
    rm -rf "$TEST_HOME" 2>/dev/null || true
}

# Core Functionality Tests

@test "w --version shows version" {
    run w --version
    [ "$status" -eq 0 ]
    [[ "$output" == *"Worktree Wrangler v"* ]]
}

@test "w without args shows usage" {
    run w
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"w <project> <worktree>"* ]]
}

@test "w --config projects sets directory" {
    run w --config projects "$TEST_PROJECTS"
    [ "$status" -eq 0 ]
    [[ "$output" == *"Set projects directory to:"* ]]
}

@test "w --config list shows configuration" {
    w --config projects "$TEST_PROJECTS"
    run w --config list
    [ "$status" -eq 0 ]
    [[ "$output" == *"Projects directory:"* ]]
    [[ "$output" == *"$TEST_PROJECTS"* ]]
}

@test "w --list shows empty worktrees initially" {
    run w --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"No worktrees found"* ]]
}

@test "w creates new worktree successfully" {
    run w testproject feature1
    [ "$status" -eq 0 ]
    
    # Verify worktree was created
    [ -d "$TEST_PROJECTS/worktrees/testproject/feature1" ]
    
    # Verify it's a git worktree (worktrees have .git file, not directory)
    [ -e "$TEST_PROJECTS/worktrees/testproject/feature1/.git" ]
}

@test "w --list shows created worktree" {
    w testproject feature1
    run w --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"[testproject]"* ]]
    [[ "$output" == *"feature1"* ]]
}

@test "w executes command in worktree" {
    w testproject feature1
    run w testproject feature1 pwd
    [ "$status" -eq 0 ]
    [[ "$output" == *"/worktrees/testproject/feature1"* ]]
}

@test "w --rm removes worktree" {
    w testproject feature1
    
    # Verify worktree exists
    [ -d "$TEST_PROJECTS/worktrees/testproject/feature1" ]
    
    # Remove it
    run w --rm testproject feature1
    [ "$status" -eq 0 ]
    
    # Verify it's gone
    [ ! -d "$TEST_PROJECTS/worktrees/testproject/feature1" ]
}

@test "w --status shows clean worktrees" {
    w testproject feature1
    run w --status
    [ "$status" -eq 0 ]
    [[ "$output" == *"All worktrees are clean"* ]]
}

@test "w --status shows dirty worktrees" {
    w testproject feature1
    
    # Make worktree dirty
    echo "new content" > "$TEST_PROJECTS/worktrees/testproject/feature1/newfile.txt"
    
    run w --status
    [ "$status" -eq 0 ]
    [[ "$output" == *"testproject/feature1"* ]]
}

@test "w --recent tracks worktree usage" {
    w testproject feature1
    run w --recent
    [ "$status" -eq 0 ]
    [[ "$output" == *"testproject/feature1"* ]]
}

# Error Handling Tests

@test "w fails with nonexistent project" {
    run w nonexistent feature1
    [ "$status" -eq 1 ]
    [[ "$output" == *"Project not found"* ]]
}

@test "w --rm fails with nonexistent worktree" {
    run w --rm testproject nonexistent
    [ "$status" -eq 1 ]
    [[ "$output" == *"Worktree not found"* ]]
}

@test "w --config fails with nonexistent directory" {
    run w --config projects "/nonexistent/path"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Directory does not exist"* ]]
}

# Configuration Tests

@test "w --config reset removes configuration" {
    w --config projects "$TEST_PROJECTS"
    run w --config reset
    [ "$status" -eq 0 ]
    [[ "$output" == *"Configuration reset"* ]]
}

@test "w works with default projects directory" {
    # Don't set custom config, should use default
    mkdir -p "$TEST_HOME/development/testproject"
    cd "$TEST_HOME/development/testproject"
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    echo "# Test" > README.md
    git add .
    git commit -m "Initial commit"
    cd "$TEST_HOME"
    
    run w testproject feature1
    [ "$status" -eq 0 ]
}

# Edge Cases

@test "w handles empty projects directory" {
    mkdir -p "$TEST_HOME/empty-projects"
    w --config projects "$TEST_HOME/empty-projects"
    
    run w --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"No worktrees found"* ]]
}

@test "w --list handles missing projects directory gracefully" {
    local nonexistent_dir="/tmp/nonexistent-$BATS_TEST_NUMBER"
    
    # Manually set config to point to nonexistent directory
    echo "projects_dir=$nonexistent_dir" > "$TEST_HOME/.local/share/worktree-wrangler/config"
    
    run w --list
    [ "$status" -eq 1 ]
    [[ "$output" == *"Projects directory not found"* ]]
}