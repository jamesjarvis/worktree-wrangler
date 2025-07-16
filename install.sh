#!/bin/bash
# Worktree Wrangler Installation Script
# 
# This script installs Worktree Wrangler to your ~/.zshrc
# Usage: curl -sSL https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're running in zsh
if [[ "$SHELL" != *"zsh"* ]]; then
    print_warning "Your default shell is not zsh. This tool is designed for zsh."
    print_warning "Consider switching to zsh with: chsh -s $(which zsh)"
fi

# Check for required tools
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed. Please install curl first."
    exit 1
fi

print_status "🌳 Installing Worktree Wrangler..."

# Create backup of .zshrc if it exists
if [[ -f ~/.zshrc ]]; then
    BACKUP_FILE=~/.zshrc.backup.worktree-wrangler.$(date +%Y%m%d_%H%M%S)
    cp ~/.zshrc "$BACKUP_FILE"
    print_status "Created backup: $BACKUP_FILE"
fi

# Download the latest w.zsh script
print_status "Downloading latest version..."
TEMP_FILE=$(mktemp)
if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/w.zsh" -o "$TEMP_FILE"; then
    print_error "Failed to download w.zsh from GitHub"
    rm -f "$TEMP_FILE"
    exit 1
fi

# Extract version from downloaded file
VERSION=$(grep "^# Version:" "$TEMP_FILE" | sed 's/# Version: //')
if [[ -z "$VERSION" ]]; then
    print_error "Could not determine version from downloaded file"
    rm -f "$TEMP_FILE"
    exit 1
fi

print_status "Downloaded version: $VERSION"

# Check if already installed
if grep -q "Multi-project worktree manager" ~/.zshrc 2>/dev/null; then
    print_warning "Worktree Wrangler appears to already be installed"
    print_status "Updating existing installation..."
    
    # Find and replace the existing installation
    START_LINE=$(grep -n "^# Multi-project worktree manager" ~/.zshrc | head -1 | cut -d: -f1)
    END_LINE=$(grep -n "^autoload -U compinit && compinit" ~/.zshrc | tail -1 | cut -d: -f1)
    
    if [[ -n "$START_LINE" && -n "$END_LINE" ]]; then
        # Create temporary .zshrc with updated function
        TEMP_ZSHRC=$(mktemp)
        head -n $((START_LINE - 1)) ~/.zshrc > "$TEMP_ZSHRC"
        cat "$TEMP_FILE" >> "$TEMP_ZSHRC"
        tail -n +$((END_LINE + 1)) ~/.zshrc >> "$TEMP_ZSHRC"
        
        # Replace .zshrc
        mv "$TEMP_ZSHRC" ~/.zshrc
        print_success "Updated existing installation"
    else
        print_error "Could not find existing installation markers"
        print_error "Please manually remove the old installation and run this script again"
        rm -f "$TEMP_FILE"
        exit 1
    fi
else
    # Fresh installation
    print_status "Installing Worktree Wrangler..."
    
    # Check if fpath and compinit are already set up
    if ! grep -q "fpath=(~/.zsh/completions \$fpath)" ~/.zshrc 2>/dev/null; then
        print_status "Adding zsh completion setup..."
        echo "" >> ~/.zshrc
        echo "# Worktree Wrangler completion setup" >> ~/.zshrc
        echo "fpath=(~/.zsh/completions \$fpath)" >> ~/.zshrc
        echo "autoload -U compinit && compinit" >> ~/.zshrc
        echo "" >> ~/.zshrc
    fi
    
    # Add the w function
    cat "$TEMP_FILE" >> ~/.zshrc
    print_success "Installed Worktree Wrangler"
fi

# Clean up
rm -f "$TEMP_FILE"

print_success "🎉 Installation complete!"
print_status ""
print_status "📋 Next steps:"
print_status "1. Restart your terminal or run: source ~/.zshrc"
print_status "2. Test it works: w <TAB>"
print_status "3. Create your first worktree: w myproject feature-branch"
print_status ""
print_status "📚 Quick reference:"
print_status "  w --list                    # List all worktrees"
print_status "  w --cleanup                 # Clean up merged PR worktrees"
print_status "  w --version                 # Show version"
print_status "  w --update                  # Update to latest version"
print_status ""
print_status "🔗 For more info: https://github.com/jamesjarvis/worktree-wrangler"
print_status ""
print_success "Happy coding! 🚀"