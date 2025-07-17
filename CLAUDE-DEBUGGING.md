# Debugging Guide for Worktree Wrangler

This document covers common debugging patterns, issues, and solutions encountered while maintaining the Worktree Wrangler codebase.

## Common Bug Patterns

### 1. Directory Change Issues

**Symptom**: Commands leave user in different directory than they started
**Root Cause**: Uncontained `cd` commands that change the parent shell's directory
**Example**: `w --status` was changing current directory

**Debugging**:
```bash
# Test if command changes directory
original_dir="$PWD"
w --some-command
if [ "$PWD" != "$original_dir" ]; then
    echo "BUG: Command changed directory from $original_dir to $PWD"
fi
```

**Solutions**:
```bash
# BAD: Changes parent shell directory
cd "$some_path" && git status

# GOOD: Uses subshell for isolation
(cd "$some_path" && git status)

# GOOD: Preserves and restores directory
local old_pwd="$PWD"
cd "$some_path"
git status
cd "$old_pwd"
```

### 2. Variable Name Conflicts

**Symptom**: `read-only variable: status` or similar errors
**Root Cause**: zsh has built-in read-only variables that can't be overwritten
**Common conflicts**: `status`, `options`, `signals`

**Debugging**:
```bash
# Check if variable is read-only
echo $status  # Built-in zsh variable
status="test" # This will fail
```

**Solutions**:
```bash
# BAD: Conflicts with zsh built-in
local status="clean"

# GOOD: Use descriptive prefixes
local git_status="clean"
local command_status="success"
```

### 3. zsh vs bash Compatibility

**Symptom**: Syntax errors like `syntax error near unexpected token '('`
**Root Cause**: zsh-specific syntax being interpreted by bash
**Common issues**: Glob patterns `*(/N)`, array syntax

**Debugging**:
```bash
# Test if script loads in both shells
zsh -c "source worktree-wrangler.zsh; w --version"  # Should work
bash -c "source worktree-wrangler.zsh; w --version" # May fail
```

**Solutions**:
```bash
# zsh-specific glob patterns (OK in zsh scripts)
for project in $worktrees_dir/*(/N); do

# Portable alternative for bash compatibility
for project in "$worktrees_dir"/*; do
    if [[ -d "$project" ]]; then
```

### 4. Environment Variable Issues

**Symptom**: Branch names like `/feature1` instead of `user/feature1`
**Root Cause**: `$USER` environment variable not set
**Common in**: Docker containers, minimal environments

**Debugging**:
```bash
# Check environment variables
echo "USER=$USER"
echo "HOME=$HOME"
whoami  # Alternative to $USER
```

**Solutions**:
```bash
# BAD: Assumes $USER is always set
local branch_name="$USER/$worktree"

# GOOD: Fallback to whoami or default
local user="${USER:-$(whoami)}"
local branch_name="$user/$worktree"

# Or in Dockerfile
ENV USER=testuser
```

## Debugging Workflow

### 1. Identify the Problem

#### For User Reports
1. **Reproduce the issue** in your own environment
2. **Check recent changes** that might have introduced the bug
3. **Look for patterns** in error messages or behavior

#### For Test Failures
1. **Read the test output** carefully for clues
2. **Run individual failing tests** for more detail
3. **Check if multiple tests fail** (systemic vs isolated issue)

### 2. Isolate the Root Cause

#### Use Debugging Commands
```bash
# Add debug output temporarily
echo "DEBUG: PWD=$PWD, USER=$USER, HOME=$HOME" >&2

# Trace execution
set -x  # Enable trace
w --some-command
set +x  # Disable trace

# Check function definitions
type w  # Show function definition
```

#### Test in Isolation
```bash
# Test individual components
source worktree-wrangler.zsh
w --version  # Basic functionality
w --list     # Information commands
w --config list  # Configuration
```

### 3. Create Minimal Reproduction

```bash
# Create clean test environment
export TEST_HOME="/tmp/debug-$$"
export HOME="$TEST_HOME"
mkdir -p "$TEST_HOME"

# Set up minimal git repo
mkdir -p "$TEST_HOME/projects/test"
cd "$TEST_HOME/projects/test"
git init && git commit --allow-empty -m "init"

# Test specific issue
source path/to/worktree-wrangler.zsh
w test feature1  # Or whatever reproduces the bug
```

## Common Error Messages and Solutions

### Git-Related Errors

#### `fatal: '/feature1' is not a valid branch name`
**Cause**: Empty or invalid `$USER` variable
**Solution**: Set USER environment variable or provide fallback

#### `fatal: worktree already exists`
**Cause**: Attempting to create worktree that already exists
**Solution**: Check if worktree exists before creation

#### `fatal: not a git repository`
**Cause**: Command run outside git repo or in invalid directory
**Solution**: Validate git repo before operations

### File System Errors

#### `No such file or directory`
**Cause**: Path doesn't exist or incorrect path construction
**Solution**: Use `mkdir -p` for directories, validate paths exist

#### `Permission denied`
**Cause**: Insufficient permissions for file/directory operations
**Solution**: Check ownership, use appropriate user in containers

### Configuration Errors

#### `Projects directory not found`
**Cause**: User hasn't configured projects directory or it was deleted
**Solution**: Provide helpful error message with fix instructions

## zsh-Specific Debugging

### Common zsh Features Used

#### Glob Patterns
```bash
# zsh-specific (used in codebase)
for project in $worktrees_dir/*(/N); do  # Directories only, null if no match

# Components:
# *       - glob pattern
# (/)     - directories only
# (N)     - null_glob option (return nothing if no matches)
```

#### Parameter Expansion
```bash
# Extract filename from path
project_name=$(basename "$project")  # Portable
project_name=${project:t}            # zsh-specific (not used in codebase)
```

#### Array Handling
```bash
# zsh arrays (1-indexed)
local -a projects
projects+=(new_item)  # Append to array
```

### Testing zsh Features
```bash
# Test in clean zsh environment
zsh -c "
setopt null_glob  # Important for (N) flag
for dir in /tmp/*(/N); do echo \$dir; done
"
```

## Performance Debugging

### Slow Commands

#### Profile execution time
```bash
# Time individual operations
time w --list
time w testproject feature1

# Profile specific functions
time (cd /some/path && git status)
```

#### Common performance issues
1. **Git operations**: Always the slowest part
2. **Directory traversal**: Can be slow with many worktrees
3. **JSON parsing**: `jq` operations can be expensive

### Memory Usage

#### Monitor resource usage
```bash
# Monitor while running tests
top -p $(pgrep bats)
htop  # If available
```

## Error Handling Patterns

### Defensive Programming
```bash
# Always validate inputs
if [[ -z "$project" || -z "$worktree" ]]; then
    echo "Usage: w <project> <worktree>"
    return 1
fi

# Check dependencies
if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required"
    return 1
fi

# Validate paths exist
if [[ ! -d "$projects_dir" ]]; then
    echo "Projects directory not found: $projects_dir"
    return 1
fi
```

### Error Recovery
```bash
# Provide actionable error messages
echo "❌ Projects directory not found: $projects_dir"
echo ""
echo "💡 To fix this, set your projects directory:"
echo "   w --config projects ~/your/projects/directory"
```

## Testing Your Fixes

### Before Committing
```bash
# 1. Quick syntax check
cd tests && ./run-tests.sh quick

# 2. Full test suite
cd tests && ./run-tests.sh

# 3. Manual testing of specific issue
# (reproduce the original problem to verify it's fixed)
```

### Regression Testing
```bash
# Add test for the bug you just fixed
@test "w --command does not change current directory" {
    local original_dir="$PWD"
    w --command >/dev/null
    [ "$PWD" = "$original_dir" ]
}
```

## Documentation After Fixes

### Update CHANGELOG.md
```markdown
## [X.Y.Z] - DATE

### Fixed
- Fixed `w --command` changing current working directory
- Description of what was broken and how it's fixed

### Technical Details
- Specific implementation details
- Why the bug occurred
```

### Update Test Coverage
- Add regression tests
- Update test count in documentation
- Ensure tests actually catch the bug if reintroduced

This debugging approach helps systematically identify, isolate, and fix issues while building confidence through comprehensive testing.