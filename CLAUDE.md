# Claude Instructions for Worktree Wrangler

This file contains instructions for Claude (Anthropic's AI assistant) when working on the Worktree Wrangler repository. Follow these guidelines to maintain consistency and quality.

## Git Commit and Release Management

### Automated Git Commits

**IMPORTANT**: Claude should make git commits automatically when making changes to this repository.

**Commit Message Format**: `[AI] <message>`
- All commit messages must start with `[AI]` prefix
- Use clear, descriptive commit messages
- Examples:
  - `[AI] fix: resolve PR detection issue in cleanup command`
  - `[AI] feat: add configuration persistence system`
  - `[AI] docs: update README with new installation method`

**Git Configuration**: Use the existing git user email (`james.jarvis@incident.io`)

### Automated Releases

**When to Create Releases**: Claude should automatically create new releases when making changes that warrant them according to semantic versioning.

**Release Process**:
1. Update version numbers in all required files
2. Update CHANGELOG.md with new version entry
3. Make git commit with version bump
4. Create GitHub release using `gh release create`

## Version Management

### When to Update Versions

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR (X.0.0)**: Breaking changes, incompatible API changes
- **MINOR (0.X.0)**: New functionality, backward compatible
- **PATCH (0.0.X)**: Bug fixes, backward compatible

**Automatic Version Updates**: Claude should proactively update versions when making meaningful changes and create corresponding releases.

### Version Update Process

**CRITICAL**: Version must be updated in **multiple locations**:

1. **`worktree-wrangler.zsh`**:
   - Header comment: `# Version: X.Y.Z`
   - VERSION variable: `local VERSION="X.Y.Z"`

2. **`w.zsh`** (legacy file):
   - Header comment: `# Version: X.Y.Z` 
   - VERSION variable: `local VERSION="X.Y.Z"`

3. **`CHANGELOG.md`**:
   - Add new version entry with date
   - Document all changes in appropriate sections

### Version Update Checklist

```bash
# 1. Update worktree-wrangler.zsh (2 places)
# 2. Update w.zsh (2 places)  
# 3. Update CHANGELOG.md
# 4. Test version command: w --version
# 5. Test update mechanism works after push to GitHub
```

## README Maintenance

### README Philosophy
- **Keep it simple and direct** - no marketing fluff
- **Installation first** - users want to get started quickly
- **Essential information only** - usage, config, troubleshooting
- **Maintain the credits section** - reference to original author and Claude

### README Structure (DO NOT CHANGE)
1. Title and brief description
2. Installation (one-liner preferred)
3. Usage examples
4. Directory structure
5. Requirements
6. Configuration
7. Troubleshooting
8. Uninstall
9. Credits (preserve Rory's reference and Claude disclaimer)

## Codebase Structure

### File Overview

- **`worktree-wrangler.zsh`** - Main script (standalone version)
- **`w.zsh`** - Legacy monolithic version
- **`_w`** - zsh completion file
- **`zshrc-integration.zsh`** - Minimal .zshrc integration
- **`install.sh`** - Installation script for curl method
- **`README.md`** - User documentation
- **`CHANGELOG.md`** - Version history
- **`CLAUDE.md`** - This file

### Architecture

**Modern Architecture (Recommended)**:
```
~/.local/share/worktree-wrangler/
├── worktree-wrangler.zsh          # Main script
└── config                         # User configuration

~/.local/share/zsh/site-functions/
└── _w                              # Completion

~/.zshrc                           # Minimal integration (sources main script)
```

**Legacy Architecture**:
- Entire script embedded in `~/.zshrc`
- Completion embedded in script
- No separation of concerns

### Key Implementation Details

1. **Configuration System**:
   - Stored in `~/.local/share/worktree-wrangler/config`
   - Simple `key=value` format
   - Loaded on script startup
   - Commands: `--config projects <path>`, `--config list`, `--config reset`

2. **PR Detection (CRITICAL COMPONENT)**:
   - 4 fallback methods for maximum reliability
   - Method 1: Branch format matching (`branch`, `origin/branch`, `short-branch`)
   - Method 2: Context-aware `gh pr status` from worktree
   - Method 3: All PRs filtering with partial matching
   - Method 4: Commit-based lookup using SHA
   - **Smart JSON parsing** handles different response formats

3. **Directory Structure**:
   - Default: `~/development/` (configurable)
   - Worktrees: `~/development/worktrees/`
   - Legacy support: `~/projects/core-wts/` for backward compatibility

4. **Update Mechanism**:
   - Downloads from GitHub raw URL
   - Replaces standalone script file (not entire .zshrc)
   - Automatic backup before updates
   - Version comparison for update detection

## Dependencies

### Required
- **zsh** - Script is zsh-specific, uses zsh arrays and glob patterns
- **GitHub CLI (gh)** - For `--cleanup` feature, PR detection
- **jq** - For JSON parsing of GitHub API responses
- **curl** - For installation and updates

### Optional
- **git** - Obviously required for worktree functionality
- **realpath** - Used in configuration validation

## Testing Procedures

### Manual Testing Checklist

**Basic Functionality**:
```bash
# Test basic commands
w --version
w --list  
w --config list
w <project> <worktree>  # Create/switch
w --rm <project> <worktree>  # Remove
```

**Error Handling**:
```bash
w                    # Should show usage, not error
w --config projects /nonexistent  # Should error gracefully
w nonexistent project            # Should show available projects
```

**GitHub Integration**:
```bash
w --cleanup          # Test with actual worktrees/PRs
gh auth status       # Verify GitHub CLI is working
```

**Configuration**:
```bash
w --config projects ~/test-dir
w --config list      # Verify change
w --config reset     # Test reset
```

### Edge Cases to Test

1. **No GitHub CLI** - Should error gracefully
2. **No git remotes** - Should handle missing origin
3. **Empty directories** - Should not break on missing subdirs
4. **Different PR formats** - Test with various PR states
5. **Tab completion** - Test in clean zsh session

## Important Implementation Notes

### zsh-Specific Features
- **Glob patterns**: Uses `*(N/)` syntax (zsh-specific)
- **Arrays**: Uses zsh array syntax `array+=(item)`
- **Completion**: Uses zsh completion framework (`_arguments`, `_describe`)

### GitHub CLI Integration
- **Authentication**: Always check `gh auth status` before PR operations
- **JSON parsing**: Handle multiple response formats gracefully
- **Error handling**: GitHub API can be flaky, always have fallbacks

### PR Detection Robustness
The PR detection system is complex but critical. Key points:

1. **Multiple methods** - Never rely on just one approach
2. **JSON format handling** - `gh pr status` vs `gh pr list` have different formats
3. **Branch name variations** - Users create PRs with different naming
4. **Context awareness** - Running from worktree vs main repo matters

### Configuration System
- **Persistence** - Config survives updates
- **Validation** - Always validate paths exist
- **Defaults** - Graceful fallback to defaults
- **User experience** - Clear error messages with solutions

## Release Process

### Before Release
1. Update version in all locations
2. Update CHANGELOG.md
3. Test all major functionality
4. Test update mechanism works
5. Verify installation script works

### After Release
1. Push to GitHub
2. Test that `w --update` works from previous version
3. Verify curl installation still works
4. Monitor for issues

## Troubleshooting Common Issues

### Tab Completion Not Working
- Check fpath setup in zsh
- Verify completion file location
- Test with `autoload -U compinit && compinit`

### PR Detection Failing
- Check GitHub CLI authentication
- Verify repository has remote origin
- Test each detection method individually
- Check for unusual branch naming

### Configuration Issues
- Verify config file permissions
- Check directory exists and is writable
- Test with default configuration

### Update Mechanism
- Verify GitHub raw URL works
- Check curl availability
- Test with different versions

## Code Style Guidelines

### Shell Scripting
- Use `local` for all variables in functions
- Quote all variable expansions: `"$variable"`
- Use `[[ ]]` instead of `[ ]` for tests
- Handle errors gracefully with meaningful messages

### User Experience
- Provide helpful error messages with solutions
- Use consistent command patterns
- Keep output clean and informative
- Always offer next steps when things fail

### Documentation
- Keep README concise and practical
- Update CHANGELOG.md for all user-facing changes
- Maintain this CLAUDE.md file when architecture changes

## Final Notes

This repository was entirely coded by Claude and should maintain that heritage. The tool is designed to be simple, reliable, and user-friendly while leveraging modern development practices like GitHub CLI integration and XDG directory standards.

When in doubt, prioritize user experience and reliability over complex features. The core use case is switching between worktrees quickly and cleaning up merged PRs automatically.