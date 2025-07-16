# 🌳 Worktree Wrangler

> **The ultimate multi-project Git worktree manager with Claude Code integration**

Stop juggling multiple git repos and branches! Worktree Wrangler makes it effortless to switch between different features across all your projects while keeping your workspace organized.

## ✨ What is this?

Worktree Wrangler is a powerful zsh function that:
- 🚀 **Instantly switches** between projects and feature branches
- 📁 **Organizes worktrees** in a clean, predictable structure
- 🤖 **Integrates with Claude Code** for seamless AI-assisted development
- 🧹 **Auto-cleans** merged PR worktrees to keep your workspace tidy
- ⚡ **Smart tab completion** for lightning-fast navigation

## 🎯 Quick Start

### 1. Prerequisites
- zsh shell
- [GitHub CLI](https://cli.github.com/) (for `--cleanup` feature)

### 2. Installation

Copy the entire `w.zsh` file content to your `~/.zshrc`:

```bash
# Add these lines to your ~/.zshrc BEFORE the w function
fpath=(~/.zsh/completions $fpath)
autoload -U compinit && compinit

# Then paste the entire w.zsh content below those lines
```

### 3. Restart your terminal
```bash
source ~/.zshrc
```

### 4. Test it works
```bash
w <TAB>  # Should show your projects
```

## 🎪 Usage Examples

### Basic Navigation
```bash
# Switch to (or create) a feature branch worktree
w myapp feature-login

# Run a command in a worktree without switching
w myapp feature-login git status
w myapp feature-login claude  # Start Claude Code session
```

### Project Management
```bash
# List all worktrees across all projects
w --list

# Remove a specific worktree
w --rm myapp feature-login

# Clean up merged PR worktrees automatically
w --cleanup
```

### Real-world Workflow
```bash
# Start working on a new feature
w myapp user-auth              # Creates and switches to worktree

# Run tests in the background
w myapp user-auth npm test

# Start Claude Code session
w myapp user-auth claude

# When done, clean up merged branches
w --cleanup
```

## 📂 Directory Structure

Worktree Wrangler organizes your projects like this:

```
~/projects/
├── my-app/              # Main git repo
├── another-project/     # Main git repo
└── worktrees/
    ├── my-app/
    │   ├── feature-auth/    # Worktree for feature-auth branch
    │   └── bugfix-login/    # Worktree for bugfix-login branch
    └── another-project/
        └── new-feature/     # Worktree for new-feature branch
```

## 🚀 Features

### 🎯 Smart Branch Creation
- New branches automatically prefixed with your username: `username/feature-name`
- Seamless worktree creation and management

### 🧹 Automatic Cleanup
The `--cleanup` flag intelligently removes worktrees by:
- ✅ Checking if the PR is merged on GitHub
- ✅ Ensuring no uncommitted changes
- ✅ Verifying no unpushed commits
- ✅ Safely removing the worktree

### ⚡ Tab Completion
- Complete project names
- Complete existing worktree names
- Complete common commands (git, npm, yarn, etc.)

### 🔧 Claude Code Integration
Perfect for AI-assisted development:
```bash
w myapp feature-x claude    # Start Claude session in worktree
```

## 🎨 Command Reference

| Command | Description |
|---------|-------------|
| `w <project> <worktree>` | Switch to worktree (creates if needed) |
| `w <project> <worktree> <command>` | Run command in worktree |
| `w --list` | List all worktrees |
| `w --rm <project> <worktree>` | Remove specific worktree |
| `w --cleanup` | Remove worktrees for merged PRs |

## 🔧 Configuration

### Custom Directories
To use different directories, modify these lines in the `w()` function:
```bash
local projects_dir="$HOME/projects"      # Your git repos
local worktrees_dir="$HOME/projects/worktrees"  # Worktrees location
```

### GitHub CLI Setup
For the `--cleanup` feature:
```bash
# Install GitHub CLI
brew install gh

# Authenticate
gh auth login
```

## 🐛 Troubleshooting

### Tab completion not working?
1. Ensure the `fpath` line comes BEFORE the `w` function in your `.zshrc`
2. Restart your terminal completely
3. Try: `autoload -U compinit && compinit`

### "Command not found: w"?
- Make sure you've pasted the entire script into your `.zshrc`
- Run `source ~/.zshrc` to reload

### Cleanup not working?
- Install GitHub CLI: `brew install gh`
- Authenticate: `gh auth login`
- Ensure you're in a git repository with GitHub remote

## 💡 Pro Tips

1. **Use descriptive worktree names** - they become your branch names
2. **Run `w --cleanup` regularly** to keep your workspace tidy
3. **Combine with aliases** for common commands:
   ```bash
   alias wc='w --cleanup'
   alias wl='w --list'
   ```

## 🙏 Credits

Originally inspired by [rorydbain's gist](https://gist.github.com/rorydbain/e20e6ab0c7cc027fc1599bd2e430117d) and enhanced with additional features for modern development workflows.

---

**Happy coding! 🚀**