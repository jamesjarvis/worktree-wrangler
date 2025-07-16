# Worktree Wrangler - Zsh Integration
# This file should be sourced from your ~/.zshrc

# Set up completion path
if [[ ! -d ~/.local/share/zsh/site-functions ]]; then
    mkdir -p ~/.local/share/zsh/site-functions
fi

# Add completion path to fpath if not already there
if [[ -d ~/.local/share/zsh/site-functions ]]; then
    fpath=(~/.local/share/zsh/site-functions $fpath)
fi

# Initialize completions
autoload -U compinit && compinit

# Source the main worktree wrangler script
if [[ -f ~/.local/share/worktree-wrangler/worktree-wrangler.zsh ]]; then
    source ~/.local/share/worktree-wrangler/worktree-wrangler.zsh
else
    echo "Warning: Worktree Wrangler script not found at ~/.local/share/worktree-wrangler/worktree-wrangler.zsh"
    echo "Please run the installation script to set up Worktree Wrangler properly."
fi