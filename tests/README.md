# Worktree Wrangler Test Suite

Simple, fast test suite for worktree-wrangler that runs in isolated environments.

## Quick Start

```bash
# Run all tests (Docker by default)
cd tests
./run-tests.sh

# Run tests natively (no Docker)
./run-tests.sh native

# Quick syntax check only
./run-tests.sh quick
```

## Running with gh act (Local GitHub Actions)

```bash
# Install gh act if not already installed
# brew install act  # macOS
# or download from: https://github.com/nektos/act

# Run the GitHub Actions workflow locally
gh act

# Or run specific job
gh act -j test
```

## Test Structure

- **`tests.bats`** - All tests in one file using BATS framework
- **`Dockerfile`** - Minimal Alpine Linux container with zsh + git
- **`run-tests.sh`** - Local test runner with multiple execution modes
- **`test-env-setup.sh`** - Helper script for manual test environment setup

## What Gets Tested

### ✅ Core Commands
- `w <project> <worktree>` - Create and switch to worktrees
- `w <project> <worktree> <command>` - Execute commands in worktrees
- Error handling for missing projects/arguments

### ✅ Information Commands  
- `w --list` - List worktrees with status information
- `w --status` - Show git status across worktrees
- `w --recent` - Show recently used worktrees
- `w --version` - Display version information

### ✅ Management Commands
- `w --rm <project> <worktree>` - Remove worktrees
- `w --config projects <path>` - Configure projects directory
- `w --config list/reset` - Manage configuration

### ✅ Edge Cases
- Missing directories and projects
- Empty repositories
- Configuration validation
- Error message clarity

## Test Isolation

Tests run in completely isolated environments:

- **Temporary directories** - Each test uses unique `/tmp` directories
- **Isolated HOME** - Tests don't touch your real home directory  
- **Clean git repos** - Fresh test repositories for each test
- **No interference** - Won't affect your existing `w` setup or worktrees

## Test Execution Times

- **Quick test**: ~1 second (syntax check only)
- **Full test suite**: ~15-30 seconds
- **Docker overhead**: ~10 seconds for image build

## Manual Testing

For debugging individual tests:

```bash
# Set up test environment manually
./test-env-setup.sh
export TEST_HOME="/tmp/worktree-wrangler-test-$$"
export HOME="$TEST_HOME"

# Source the function
source ../worktree-wrangler.zsh

# Run individual commands
w --version
w --config projects "$TEST_HOME/projects"
w testproject feature1

# Clean up
rm -rf "$TEST_HOME"
```

## GitHub Actions

The test suite runs automatically on:
- Push to `master`/`main`
- Pull requests
- Manual workflow dispatch

View results at: https://github.com/jamesjarvis/worktree-wrangler/actions