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

# List all worktrees (with status and branch info)
w --list

# Show git status across all worktrees (or specific project)
w --status
w --status myproject

# Show recently used worktrees
w --recent

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

# Configure setup/archive scripts (optional)
w --config setup_script ~/scripts/setup-worktree.sh
w --config archive_script ~/scripts/archive-worktree.sh

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

## Setup and Archive Scripts

Automate your worktree lifecycle with custom scripts that run during creation and removal.

### Configuration

**Setup Script** - Runs automatically when creating new worktrees:
```bash
w --config setup_script ~/scripts/setup-worktree.sh
```

**Archive Script** - Runs before removing worktrees (both `--rm` and `--cleanup`):
```bash
w --config archive_script ~/scripts/archive-worktree.sh
```

**View Configuration:**
```bash
w --config list
```

**Clear Scripts:**
```bash
w --config setup_script ""     # Clear setup script
w --config archive_script ""   # Clear archive script
```

### Environment Variables

Your scripts receive these environment variables:

- `$W_WORKSPACE_NAME` - Name of the worktree (e.g., `feature-auth`)
- `$W_WORKSPACE_PATH` - Full path to worktree directory
- `$W_ROOT_PATH` - Path to the main git repository
- `$W_DEFAULT_BRANCH` - Default branch name (usually `main` or `master`)

### Example Setup Script

Create `~/scripts/setup-worktree.sh`:

```bash
#!/bin/bash
set -e

echo "🚀 Setting up worktree: $W_WORKSPACE_NAME"
echo "📁 Path: $W_WORKSPACE_PATH"
echo "🏠 Root: $W_ROOT_PATH"

# Install dependencies
if [[ -f package.json ]]; then
    echo "📦 Installing npm dependencies..."
    npm install
fi

if [[ -f requirements.txt ]]; then
    echo "🐍 Installing Python dependencies..."
    pip install -r requirements.txt
fi

# Copy environment files
if [[ -f "$W_ROOT_PATH/.env.example" ]]; then
    echo "🔧 Copying environment file..."
    cp "$W_ROOT_PATH/.env.example" .env
fi

# Database setup
if command -v rails >/dev/null 2>&1; then
    echo "💎 Setting up Rails database..."
    rails db:create db:migrate
fi

echo "✅ Worktree setup complete!"
```

### Example Archive Script

Create `~/scripts/archive-worktree.sh`:

```bash
#!/bin/bash
set -e

echo "📦 Archiving worktree: $W_WORKSPACE_NAME"
echo "📁 Path: $W_WORKSPACE_PATH"

# Backup important files
BACKUP_DIR="$HOME/worktree-backups/$W_WORKSPACE_NAME-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Save logs
if [[ -d logs ]]; then
    echo "💾 Backing up logs..."
    cp -r logs "$BACKUP_DIR/"
fi

# Export database data
if command -v rails >/dev/null 2>&1 && [[ -f db/seeds.rb ]]; then
    echo "🗄️ Exporting database..."
    rails db:dump > "$BACKUP_DIR/database.sql"
fi

# Save custom config files
for file in .env.local config.local.json; do
    if [[ -f "$file" ]]; then
        echo "⚙️ Backing up $file..."
        cp "$file" "$BACKUP_DIR/"
    fi
done

echo "✅ Archive complete: $BACKUP_DIR"
```

### Script Requirements

- Scripts must be executable: `chmod +x ~/scripts/setup-worktree.sh`
- Scripts run from the worktree directory (setup) or can fallback to project root (archive)
- Exit codes are captured and displayed for debugging
- Scripts run in subshells so they won't affect your current environment

### Use Cases

**Setup Scripts:**
- Install project dependencies (npm, pip, composer)
- Copy configuration files (.env, config.json)
- Set up databases or services
- Configure development tools
- Create necessary directories

**Archive Scripts:**
- Backup important files or data
- Export database snapshots  
- Save logs or debug information
- Clean up temporary files
- Notify team members

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