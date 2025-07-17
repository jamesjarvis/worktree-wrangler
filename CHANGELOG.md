# Changelog

All notable changes to Worktree Wrangler will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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