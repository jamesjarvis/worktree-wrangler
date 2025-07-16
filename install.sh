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

# Set up installation directories
INSTALL_DIR="$HOME/.local/share/worktree-wrangler"
COMPLETION_DIR="$HOME/.local/share/zsh/site-functions"

# Create directories if they don't exist
mkdir -p "$INSTALL_DIR"
mkdir -p "$COMPLETION_DIR"

# Download the latest script and completion files
print_status "Downloading latest version..."
TEMP_SCRIPT=$(mktemp)
TEMP_COMPLETION=$(mktemp)
TEMP_INTEGRATION=$(mktemp)

if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/worktree-wrangler.zsh" -o "$TEMP_SCRIPT"; then
    print_error "Failed to download worktree-wrangler.zsh from GitHub"
    rm -f "$TEMP_SCRIPT" "$TEMP_COMPLETION" "$TEMP_INTEGRATION"
    exit 1
fi

if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/_w" -o "$TEMP_COMPLETION"; then
    print_error "Failed to download completion file from GitHub"
    rm -f "$TEMP_SCRIPT" "$TEMP_COMPLETION" "$TEMP_INTEGRATION"
    exit 1
fi

if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/zshrc-integration.zsh" -o "$TEMP_INTEGRATION"; then
    print_error "Failed to download zshrc integration from GitHub"
    rm -f "$TEMP_SCRIPT" "$TEMP_COMPLETION" "$TEMP_INTEGRATION"
    exit 1
fi

# Extract version from downloaded file
VERSION=$(grep "^# Version:" "$TEMP_SCRIPT" | sed 's/# Version: //')
if [[ -z "$VERSION" ]]; then
    print_error "Could not determine version from downloaded file"
    rm -f "$TEMP_SCRIPT" "$TEMP_COMPLETION" "$TEMP_INTEGRATION"
    exit 1
fi

print_status "Downloaded version: $VERSION"

# Install the files
print_status "Installing files..."
mv "$TEMP_SCRIPT" "$INSTALL_DIR/worktree-wrangler.zsh"
mv "$TEMP_COMPLETION" "$COMPLETION_DIR/_w"
chmod +x "$INSTALL_DIR/worktree-wrangler.zsh"

# Check if already integrated in .zshrc
if grep -q "Worktree Wrangler - Zsh Integration" ~/.zshrc 2>/dev/null; then
    print_warning "Worktree Wrangler appears to already be integrated in .zshrc"
    print_status "Skipping .zshrc integration (already present)"
else
    # Add integration to .zshrc
    print_status "Adding integration to .zshrc..."
    echo "" >> ~/.zshrc
    cat "$TEMP_INTEGRATION" >> ~/.zshrc
    print_success "Added Worktree Wrangler integration to .zshrc"
fi

# Clean up
rm -f "$TEMP_INTEGRATION"

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
print_status "📁 Installation locations:"
print_status "  Script: ~/.local/share/worktree-wrangler/worktree-wrangler.zsh"
print_status "  Completion: ~/.local/share/zsh/site-functions/_w"
print_status ""
print_status "🔗 For more info: https://github.com/jamesjarvis/worktree-wrangler"
print_status ""
print_success "Happy coding! 🚀"