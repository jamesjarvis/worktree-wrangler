# Changelog

All notable changes to Worktree Wrangler will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.5.0] - 2025-08-18

### 🔄 BREAKING CHANGE: Per-Repository Script Configuration

**MIGRATION REQUIRED**: Setup and archive scripts are now configured per-repository instead of globally.

### Added
- **Per-Repository Script Commands**:
  - `w <repo> --setup_script <path>` - Set setup script for specific repository
  - `w <repo> --archive_script <path>` - Set archive script for specific repository
  - `w <repo> --setup_script ""` - Clear setup script for repository
  - `w <repo> --archive_script ""` - Clear archive script for repository
- **Enhanced Configuration Display** - `w --config list` now shows all configured repository scripts with clear organization
- **Repository Validation** - Commands validate that the specified repository exists before configuring scripts
- **Improved Help Documentation** - Updated `--help` and `--config` to show new per-repository syntax

### Changed
- **BREAKING**: Global script configuration (`w --config setup_script/archive_script`) is now **deprecated**
- Scripts are stored per-repository in `~/.local/share/worktree-wrangler/repos/` directory
- Each repository can have its own setup and archive scripts for maximum flexibility
- Configuration commands now provide clear migration guidance with examples

### Migration Guide
```bash
# OLD (deprecated):
w --config setup_script ~/scripts/setup.sh

# NEW (per-repository):
w myproject --setup_script ~/scripts/setup.sh
w frontend --setup_script ~/scripts/frontend-setup.sh
w backend --setup_script ~/scripts/backend-setup.sh
```

### Technical Details
- Repository scripts stored as individual files: `<repo>.setup_script` and `<repo>.archive_script`
- Same environment variables provided: `$W_WORKSPACE_NAME`, `$W_WORKSPACE_PATH`, `$W_ROOT_PATH`, `$W_DEFAULT_BRANCH`
- Backward compatibility maintained through deprecation warnings with migration examples
- Enhanced error handling with repository existence validation

## [1.4.0] - 2025-08-15

### Added
- **Setup and Archive Script Configuration** for automated worktree lifecycle management
- **`w --config setup_script <path>`** to configure a script that runs when creating worktrees
- **`w --config archive_script <path>`** to configure a script that runs before removing worktrees
- **Environment variables for scripts**:
  - `$W_WORKSPACE_NAME` - Name of the worktree
  - `$W_WORKSPACE_PATH` - Full path to worktree directory
  - `$W_ROOT_PATH` - Path to the root repository
  - `$W_DEFAULT_BRANCH` - Default branch name (usually 'main' or 'master')
- **Script execution during `w --rm`** and `w --cleanup`** operations
- **Enhanced configuration display** showing setup and archive script settings in `w --config list`

### Changed
- Extended configuration system to support executable script paths
- Added script validation (existence and executable permissions) during configuration
- Improved error handling with clear messages for script configuration issues

### Technical Details
- Scripts run with working directory set to the worktree path
- Scripts execute in subshells with exported environment variables
- Archive scripts can fallback to project root if worktree path is inaccessible during removal
- Scripts can be cleared by setting empty string: `w --config setup_script ""`
- Exit codes are captured and displayed for debugging

## [1.3.4] - 2025-07-23

### Added
- **New `--copy-pr-link` command** for copying PR links with size-based emoji prefixes
- **Smart emoji selection** based on diff size: 🐜 ant (<50 lines), 🐭 mouse (50-150), 🐕 dog (150-600), 🦁 lion (600-2000), 🐋 whale (2000+)
- **Flexible usage patterns**: `w --copy-pr-link` (current directory) or `w --copy-pr-link <project> <worktree>` (specific worktree)
- **Cross-platform clipboard support** with automatic detection of pbcopy, xclip, or wl-copy
- **Enhanced tab completion** for the new --copy-pr-link command

### Changed
- Improved error handling: warnings instead of errors for non-worktree directories when using `--copy-pr-link`
- Enhanced git repository detection logic to work with both regular repos and worktrees

### Technical Details
- Uses robust 4-method PR detection system from existing --cleanup command
- Generates markdown-formatted links: `[emoji] [PR Title](PR_URL)`
- Supports both legacy and modern worktree directory structures
- Graceful fallback when clipboard utilities are unavailable

## [1.3.3] - 2025-07-17

### Added
- **Colorful output throughout the tool** with beautiful colors and better visual hierarchy
- **Enhanced `--recent` command** with helpful guidance when no usage history exists
- **Improved visual feedback** for worktree creation with success/failure messages

### Changed
- All command outputs now use colors: cyan headers, green success, red errors, yellow warnings
- Project names displayed with purple bold formatting and folder emojis
- Worktree information shows colored branch names, status indicators, and timestamps
- Better visual distinction between clean and dirty worktree states
- Enhanced guidance messages with colored examples and clearer instructions

### Fixed
- **`--recent` command explanation**: Now clearly explains why it might be empty and how to populate it
- Better user experience for first-time users with more helpful empty state messages

### Technical Details
- Added comprehensive color definitions using ANSI escape codes
- Colors are used consistently across all output commands
- Maintained emoji usage while adding complementary color coding
- Enhanced visual hierarchy with bold, dim, and colored text combinations

## [1.3.2] - 2025-07-17

### Fixed
- Fixed `w --status` command changing current working directory
- Status command now runs git operations in subshells to preserve user's location

### Added
- Test coverage for directory preservation in `--status` command

### Technical Details
- Wrapped `cd` commands in subshells `(cd "$path" && command)` to prevent directory changes
- Added regression test to catch this issue in the future

## [1.3.1] - 2025-07-17

### Fixed
- Fixed variable name conflict with zsh built-in `status` variable causing `read-only variable: status` error
- Renamed `status` variable to `git_status` throughout the codebase

### Technical Details
- Resolved conflict with zsh's built-in read-only `$status` variable
- Updated all instances in `--list`, `--recent`, and legacy location handling

## [1.3.0] - 2025-07-17

### Added
- **Enhanced `--list` command**: Now shows git status, branch names, ahead/behind indicators, and last commit time
- **New `--status` command**: Show git status for all worktrees or specific project worktrees
- **New `--recent` command**: Display recently used worktrees with timestamps and current status
- **Recent worktree tracking**: Automatically tracks worktree usage for quick access

### Changed
- Improved worktree information display with emojis and formatted output
- Enhanced tab completion for new commands
- Better visual formatting for worktree listings

### Technical Details
- Added `get_worktree_info()` helper function for consistent worktree information retrieval
- Implemented recent usage tracking in `~/.local/share/worktree-wrangler/recent`
- Enhanced completion system to support `--status` and `--recent` commands
- Cross-platform date handling for recent worktree timestamps

## [1.2.0] - 2025-07-17

### Fixed
- Fixed `--cleanup` command to correctly detect and clean up merged PR worktrees
- Fixed JSON parsing to handle different GitHub CLI response formats
- Robust PR detection now works with `gh pr status`, `gh pr list`, and commit-based lookup

### Changed
- Removed debug logging for cleaner production output
- Enhanced PR detection with 4 fallback methods for maximum reliability

### Technical Details
- Fixed parsing of `gh pr status` response format (`.currentBranch.state` vs `.[0].state`)
- Added smart JSON parsing to handle arrays, objects, and `currentBranch` formats
- Improved branch name matching with multiple format attempts

## [1.1.1] - 2025-07-17

### Fixed
- Fixed shift count error when running `w` command without arguments
- Now shows proper usage message instead of zsh error

### Technical Details
- Moved `shift 2` command after argument validation to prevent errors

## [1.1.0] - 2025-07-17

### Added
- New `--config` command for persistent configuration management
  - `w --config projects <path>` - Set projects directory
  - `w --config list` - Show current configuration  
  - `w --config reset` - Reset to defaults
- Enhanced `--list` command with configuration display and helpful guidance
- Improved error messages with actionable suggestions

### Changed
- Default projects directory changed from `~/projects` to `~/development`
- Better directory structure organization following XDG standards
- Configuration now persists across updates

### Technical Details
- Configuration stored in `~/.local/share/worktree-wrangler/config`
- Automatic configuration loading on script startup
- Enhanced error handling with user-friendly guidance

## [1.0.0] - 2025-07-16

### Added
- Initial release of Worktree Wrangler
- Multi-project Git worktree management
- Smart branch creation with username prefixes
- Tab completion for projects, worktrees, and commands
- Integration commands:
  - `w <project> <worktree>` - Switch to or create worktree
  - `w <project> <worktree> <command>` - Run command in worktree
  - `w --list` - List all worktrees
  - `w --rm <project> <worktree>` - Remove worktree
  - `w --cleanup` - Remove worktrees for merged PRs
  - `w --version` - Show version
  - `w --update` - Update to latest version from GitHub
- Claude Code integration for AI-assisted development
- GitHub CLI integration for PR status checking
- Organized directory structure (`~/projects/worktrees/`)
- Automatic worktree creation and management
- Legacy worktree location support for migration

### Technical Details
- Built for zsh with comprehensive tab completion
- Uses GitHub CLI for PR detection and status checking
- Supports both new (`~/projects/worktrees/`) and legacy (`~/projects/core-wts/`) directory structures
- One-liner installation via curl
- Automatic backup and rollback for updates