# Worktree Wrangler

Multi-project Git worktree manager for zsh with Claude Code integration.

## Installation

```bash
curl -sSL https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/install.sh | bash
```

Then restart your terminal or run `source ~/.zshrc`.

## Usage

### Basic Commands

```bash
# Switch to (or create) a worktree
w myproject feature-branch

# Run a command in a worktree
w myproject feature-branch git status
w myproject feature-branch claude

# List all worktrees
w --list

# Remove a worktree
w --rm myproject feature-branch

# Clean up merged PR worktrees
w --cleanup

# Check version
w --version

# Update to latest version
w --update

# Configure projects directory
w --config projects ~/development

# Show current configuration
w --config list

# Reset configuration to defaults
w --config reset
```

### Directory Structure

```
~/projects/
├── myproject/              # Main git repo
└── worktrees/
    └── myproject/
        ├── feature-auth/   # Worktree
        └── bugfix-login/   # Worktree
```

## Requirements

- zsh shell
- [GitHub CLI](https://cli.github.com/) (for `--cleanup` feature)

## Configuration

Set your projects directory (where your git repos are located):

```bash
w --config projects ~/development
```

Check current configuration:

```bash
w --config list
```

Reset to defaults:

```bash
w --config reset
```

## Troubleshooting

**Tab completion not working?**
Restart your terminal completely.

**Command not found?**
Run `source ~/.zshrc` to reload.

**Cleanup not working?**
Install and authenticate GitHub CLI: `gh auth login`

**Update not working?**
Reinstall: `curl -sSL https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/install.sh | bash`

## Uninstall

```bash
rm -rf ~/.local/share/worktree-wrangler
rm -f ~/.local/share/zsh/site-functions/_w
# Remove the "Worktree Wrangler - Zsh Integration" section from ~/.zshrc
```

## Credits

Originally inspired by [rorydbain's gist](https://gist.github.com/rorydbain/e20e6ab0c7cc027fc1599bd2e430117d).

This entire repository was coded by Claude (Anthropic's AI assistant).