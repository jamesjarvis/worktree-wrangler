# Testing Guide for Worktree Wrangler

This document provides comprehensive guidance for writing, running, and debugging tests for the Worktree Wrangler project.

## Test Suite Overview

The test suite is built using **BATS (Bash Automated Testing System)** and runs in a **Docker container** for complete isolation from the local environment.

### Key Files
- `tests/tests.bats` - All test cases (currently 20 tests)
- `tests/Dockerfile` - Docker environment with zsh + git + BATS
- `tests/run-tests.sh` - Local test runner with multiple execution modes
- `.github/workflows/test.yml` - GitHub Actions workflow

## Running Tests

### Quick Commands
```bash
# Quick syntax check (1 second)
cd tests && ./run-tests.sh quick

# Full test suite (15-20 seconds)
cd tests && ./run-tests.sh

# Force Docker execution
cd tests && ./run-tests.sh docker

# Force native execution (requires BATS)
cd tests && ./run-tests.sh native

# GitHub Actions locally
gh act
```

### Test Execution Modes
1. **Docker mode** (default) - Complete isolation, consistent environment
2. **Native mode** - Faster, but requires BATS installation
3. **Quick mode** - Just syntax validation, no functional tests

## Writing New Tests

### Test Structure
```bash
@test "descriptive test name" {
    # Setup if needed (runs in setup() function automatically)
    
    # Execute command
    run w --some-command
    
    # Verify exit code
    [ "$status" -eq 0 ]  # or -eq 1 for expected failures
    
    # Verify output content
    [[ "$output" == *"expected text"* ]]
    
    # Verify file system state
    [ -d "$TEST_PROJECTS/worktrees/project/worktree" ]
    [ -f "$TEST_HOME/.local/share/worktree-wrangler/config" ]
}
```

### Test Categories

#### 1. Core Functionality Tests
Test basic worktree operations:
```bash
@test "w creates new worktree successfully" {
    run w testproject feature1
    [ "$status" -eq 0 ]
    [ -d "$TEST_PROJECTS/worktrees/testproject/feature1" ]
    [ -e "$TEST_PROJECTS/worktrees/testproject/feature1/.git" ]  # Note: .git is a file, not directory
}
```

#### 2. Information Command Tests
Test output and information display:
```bash
@test "w --list shows created worktree" {
    w testproject feature1
    run w --list
    [ "$status" -eq 0 ]
    [[ "$output" == *"[testproject]"* ]]
    [[ "$output" == *"feature1"* ]]
}
```

#### 3. Error Handling Tests
Test failure scenarios:
```bash
@test "w fails with nonexistent project" {
    run w nonexistent feature1
    [ "$status" -eq 1 ]
    [[ "$output" == *"Project not found"* ]]
}
```

#### 4. State Preservation Tests
Test that commands don't have side effects:
```bash
@test "w --status does not change current directory" {
    local original_dir="$PWD"
    w --status >/dev/null
    [ "$PWD" = "$original_dir" ]
}
```

### Critical Testing Patterns

#### zsh Function Testing
The `w` function must be called through a zsh wrapper:
```bash
# In setup()
w() {
    zsh -c "source '$TEST_HOME/worktree-wrangler.zsh'; w $*"
}
```

#### Environment Isolation
Each test runs in complete isolation:
```bash
# In setup()
export TEST_HOME="/tmp/worktree-wrangler-test-$$-$BATS_TEST_NUMBER"
export HOME="$TEST_HOME"
export TEST_PROJECTS="$TEST_HOME/projects"
```

#### Git Repository Setup
Tests need real git repositories:
```bash
# In setup()
mkdir -p "$TEST_PROJECTS/testproject"
cd "$TEST_PROJECTS/testproject"
git init
git config user.name "Test User"
git config user.email "test@example.com"
echo "# Test Project" > README.md
git add .
git commit -m "Initial commit"
```

## Debugging Tests

### Docker Environment Debugging
```bash
# Build and enter container for debugging
cd tests
docker build -t worktree-wrangler-test .
docker run -it --rm -v "$PWD/..:/workspace" -w /workspace/tests worktree-wrangler-test zsh

# Inside container, run individual tests
bats tests.bats -f "specific test name"
```

### Common Issues and Solutions

#### 1. zsh vs bash Compatibility
**Problem**: Script uses zsh-specific syntax like `*(/N)` glob patterns
**Solution**: Always run tests with zsh, use subshells for isolation

#### 2. Git Worktree Validation
**Problem**: Worktrees have `.git` file, not `.git` directory
**Solution**: Use `[ -e "$path/.git" ]` not `[ -d "$path/.git" ]`

#### 3. Environment Variables
**Problem**: `$USER` not set in Docker, causing branch names like `/feature1`
**Solution**: Set `ENV USER=testuser` in Dockerfile

#### 4. Directory Changes
**Problem**: Commands like `cd "$path" && git status` change current directory
**Solution**: Use subshells `(cd "$path" && git status)` for isolation

#### 5. Variable Conflicts
**Problem**: zsh built-in variables like `$status` are read-only
**Solution**: Use different names like `$git_status`

### Test Failure Debugging Process

1. **Identify the failing test**:
   ```bash
   cd tests && ./run-tests.sh docker
   # Look for "not ok" lines
   ```

2. **Run single test for details**:
   ```bash
   docker run --rm -v "$PWD/..:/workspace" -w /workspace/tests \
     worktree-wrangler-test \
     zsh -c "bats tests.bats -f 'failing test name'"
   ```

3. **Debug interactively**:
   ```bash
   # Enter container
   docker run -it --rm -v "$PWD/..:/workspace" -w /workspace/tests \
     worktree-wrangler-test zsh
   
   # Set up test environment manually
   export TEST_HOME="/tmp/debug-test"
   export HOME="$TEST_HOME"
   # ... rest of setup
   
   # Test commands manually
   source ../worktree-wrangler.zsh
   w --version
   ```

## Adding Test Coverage

### When to Add Tests
- **New features**: Always add tests for new commands or functionality
- **Bug fixes**: Add regression tests to prevent the bug from returning
- **Edge cases**: Test error conditions and boundary cases
- **State preservation**: Ensure commands don't have unintended side effects

### Test Naming Convention
- Use descriptive names that explain what's being tested
- Start with the command: `"w --status shows clean worktrees"`
- Be specific about the scenario: `"w fails with nonexistent project"`
- Include expected behavior: `"w --status does not change current directory"`

### Test Update Process
1. Add new test to `tests.bats`
2. Run tests to ensure they pass: `./run-tests.sh`
3. Update test count in documentation if needed
4. Commit with descriptive message about test coverage

## Performance Considerations

### Test Execution Speed
- **Current benchmark**: 20 tests in ~15-20 seconds
- **Docker overhead**: ~10 seconds for image build (cached after first run)
- **Individual test**: ~1 second average

### Optimization Strategies
- Use `setup()` function for common initialization
- Minimize git operations (they're slower than file operations)
- Use `run` command only when you need to check exit codes/output
- Clean up efficiently in `teardown()` function

## Integration with CI/CD

### GitHub Actions
- Runs automatically on push and PR
- Uses Docker for consistent environment
- Fails fast on test failures
- Compatible with `gh act` for local testing

### Local Development Workflow
```bash
# Before committing
cd tests && ./run-tests.sh quick  # Fast syntax check

# Before pushing
cd tests && ./run-tests.sh        # Full test suite

# For debugging
cd tests && ./run-tests.sh docker # Explicit Docker run
```

## Test Environment Details

### Docker Environment
- **Base**: Alpine Linux (lightweight)
- **Shell**: zsh with proper completion setup
- **Tools**: git, curl, jq, sudo, BATS
- **User**: testuser (non-root for security)
- **Isolation**: Complete filesystem and environment isolation

### Test Data
- **Projects**: Created in `/tmp/worktree-wrangler-test-$$-$TEST_NUMBER`
- **Configuration**: Isolated to test HOME directory
- **Git repos**: Real repositories with actual commits
- **Cleanup**: Automatic removal after each test

This testing approach ensures reliability, catches regressions early, and provides confidence in the codebase quality.