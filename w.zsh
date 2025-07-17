#!/usr/bin/env zsh
# Multi-project worktree manager with Claude support
# Version: 1.3.2
# NOTE: The version is also defined in the VERSION variable inside the w() function
# 
# ASSUMPTIONS & SETUP:
# - Your git projects live in: ~/projects/
# - Worktrees will be created in: ~/projects/worktrees/<project>/<branch>
# - New branches will be named: <your-username>/<feature-name>
#
# DIRECTORY STRUCTURE EXAMPLE:
# ~/projects/
# ├── my-app/              (main git repo)
# ├── another-project/     (main git repo)
# └── worktrees/
#     ├── my-app/
#     │   ├── feature-x/   (worktree)
#     │   └── bugfix-y/    (worktree)
#     └── another-project/
#         └── new-feature/ (worktree)
#
# CUSTOMIZATION:
# To use different directories, modify these lines in the w() function:
#   local projects_dir="$HOME/projects"
#   local worktrees_dir="$HOME/projects/worktrees"
#
# INSTALLATION:
# 1. Add to your .zshrc (in this order):
#    fpath=(~/.zsh/completions $fpath)
#    autoload -U compinit && compinit
#
# 2. Copy this entire script to your .zshrc (after the lines above)
#
# 3. Restart your terminal or run: source ~/.zshrc
#
# 4. Test it works: w <TAB> should show your projects
#
# If tab completion doesn't work:
# - Make sure the fpath line comes BEFORE the w function in your .zshrc
# - Restart your terminal completely
#
# USAGE:
#   w <project> <worktree>              # cd to worktree (creates if needed)
#   w <project> <worktree> <command>    # run command in worktree
#   w --list                            # list all worktrees
#   w --rm <project> <worktree>         # remove worktree
#   w --cleanup                         # remove worktrees for merged PRs
#   w --version                         # show version
#   w --update                          # update to latest version
#
# EXAMPLES:
#   w myapp feature-x                   # cd to feature-x worktree
#   w myapp feature-x claude            # run claude in worktree
#   w myapp feature-x gst               # git status in worktree
#   w myapp feature-x gcmsg "fix: bug"  # git commit in worktree

# Multi-project worktree manager
w() {
    local VERSION="1.3.2"
    local projects_dir="$HOME/projects"
    local worktrees_dir="$HOME/projects/worktrees"
    
    # Handle special flags
    if [[ "$1" == "--list" ]]; then
        echo "=== All Worktrees ==="
        # Check new location
        if [[ -d "$worktrees_dir" ]]; then
            for project in $worktrees_dir/*(/N); do
                project_name=$(basename "$project")
                echo "\n[$project_name]"
                for wt in $project/*(/N); do
                    echo "  • $(basename "$wt")"
                done
            done
        fi
        # Also check old core-wts location
        if [[ -d "$projects_dir/core-wts" ]]; then
            echo "\n[core] (legacy location)"
            for wt in $projects_dir/core-wts/*(/N); do
                echo "  • $(basename "$wt")"
            done
        fi
        return 0
    elif [[ "$1" == "--rm" ]]; then
        shift
        local project="$1"
        local worktree="$2"
        if [[ -z "$project" || -z "$worktree" ]]; then
            echo "Usage: w --rm <project> <worktree>"
            return 1
        fi
        # Check both locations for core
        if [[ "$project" == "core" && -d "$projects_dir/core-wts/$worktree" ]]; then
            (cd "$projects_dir/$project" && git worktree remove "$projects_dir/core-wts/$worktree")
        else
            local wt_path="$worktrees_dir/$project/$worktree"
            if [[ ! -d "$wt_path" ]]; then
                echo "Worktree not found: $wt_path"
                return 1
            fi
            (cd "$projects_dir/$project" && git worktree remove "$wt_path")
        fi
        return $?
    elif [[ "$1" == "--cleanup" ]]; then
        # Check if gh CLI is available
        if ! command -v gh &> /dev/null; then
            echo "Error: GitHub CLI (gh) is not installed or not in PATH"
            echo "Please install it from: https://cli.github.com/"
            return 1
        fi
        
        # Check if gh is authenticated
        if ! gh auth status &> /dev/null; then
            echo "Error: GitHub CLI is not authenticated"
            echo "Please run: gh auth login"
            return 1
        fi
        
        echo "=== Cleaning up merged PR worktrees ==="
        local cleaned_count=0
        local total_checked=0
        
        # Function to clean up a single worktree
        cleanup_worktree() {
            local project="$1"
            local worktree_name="$2"
            local worktree_path="$3"
            
            echo "Checking worktree: $project/$worktree_name"
            total_checked=$((total_checked + 1))
            
            # Get the branch name for this worktree
            local branch_name
            branch_name=$(cd "$worktree_path" && git branch --show-current 2>/dev/null)
            if [[ -z "$branch_name" ]]; then
                echo "  ⚠️  Skipping: Could not determine branch name"
                return 1
            fi
            
            # Check for uncommitted changes
            if [[ -n "$(cd "$worktree_path" && git status --porcelain 2>/dev/null)" ]]; then
                echo "  ⚠️  Skipping: Has uncommitted changes"
                return 1
            fi
            
            # Check if there's an associated PR
            local pr_info
            pr_info=$(cd "$projects_dir/$project" && gh pr list --head "$branch_name" --json number,state,headRefName 2>/dev/null)
            if [[ -z "$pr_info" || "$pr_info" == "[]" ]]; then
                echo "  ⚠️  Skipping: No associated PR found"
                return 1
            fi
            
            # Check if PR is merged
            local pr_state
            pr_state=$(echo "$pr_info" | jq -r '.[0].state' 2>/dev/null)
            if [[ "$pr_state" != "MERGED" ]]; then
                echo "  ⚠️  Skipping: PR is not merged (state: $pr_state)"
                return 1
            fi
            
            # Check for unpushed commits
            local unpushed_commits
            unpushed_commits=$(cd "$worktree_path" && git log @{upstream}..HEAD --oneline 2>/dev/null)
            if [[ -n "$unpushed_commits" ]]; then
                echo "  ⚠️  Skipping: Has unpushed commits"
                return 1
            fi
            
            # All checks passed - remove the worktree
            echo "  ✅ Removing worktree (PR merged, no unpushed commits)"
            if (cd "$projects_dir/$project" && git worktree remove "$worktree_path" 2>/dev/null); then
                cleaned_count=$((cleaned_count + 1))
                echo "  ✅ Successfully removed"
            else
                echo "  ❌ Failed to remove worktree"
            fi
        }
        
        # Check all projects
        for project_dir in "$projects_dir"/*(/N); do
            if [[ ! -d "$project_dir/.git" ]]; then
                continue
            fi
            
            local project_name=$(basename "$project_dir")
            echo "\\nChecking project: $project_name"
            
            # Check new worktrees location
            if [[ -d "$worktrees_dir/$project_name" ]]; then
                for wt_dir in "$worktrees_dir/$project_name"/*(/N); do
                    local wt_name=$(basename "$wt_dir")
                    cleanup_worktree "$project_name" "$wt_name" "$wt_dir"
                done
            fi
            
            # Check legacy location for core project
            if [[ "$project_name" == "core" && -d "$projects_dir/core-wts" ]]; then
                for wt_dir in "$projects_dir/core-wts"/*(/N); do
                    local wt_name=$(basename "$wt_dir")
                    cleanup_worktree "$project_name" "$wt_name" "$wt_dir"
                done
            fi
        done
        
        echo "\\n=== Cleanup Summary ==="
        echo "Worktrees checked: $total_checked"
        echo "Worktrees cleaned: $cleaned_count"
        return 0
    elif [[ "$1" == "--version" ]]; then
        echo "Worktree Wrangler v$VERSION"
        return 0
    elif [[ "$1" == "--update" ]]; then
        echo "=== Updating Worktree Wrangler ==="
        
        # Check for required tools
        if ! command -v curl &> /dev/null; then
            echo "Error: curl is required for updates"
            return 1
        fi
        
        # Get current version
        echo "Current version: $VERSION"
        
        # Download latest version
        echo "Downloading latest version..."
        local temp_file=$(mktemp)
        if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/w.zsh" -o "$temp_file"; then
            echo "Error: Failed to download latest version"
            rm -f "$temp_file"
            return 1
        fi
        
        # Extract version from downloaded file
        local latest_version
        latest_version=$(grep "^# Version:" "$temp_file" | sed 's/# Version: //')
        if [[ -z "$latest_version" ]]; then
            echo "Error: Could not determine latest version"
            rm -f "$temp_file"
            return 1
        fi
        
        echo "Latest version: $latest_version"
        
        # Compare versions
        if [[ "$VERSION" == "$latest_version" ]]; then
            echo "✅ Already up to date!"
            rm -f "$temp_file"
            return 0
        fi
        
        # Backup current .zshrc
        echo "Creating backup of ~/.zshrc..."
        cp ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d_%H%M%S)
        
        # Find and replace the w function in .zshrc
        local start_line end_line
        start_line=$(grep -n "^# Multi-project worktree manager" ~/.zshrc | head -1 | cut -d: -f1)
        end_line=$(grep -n "^autoload -U compinit && compinit" ~/.zshrc | tail -1 | cut -d: -f1)
        
        if [[ -z "$start_line" || -z "$end_line" ]]; then
            echo "Error: Could not find existing installation in ~/.zshrc"
            echo "Please reinstall using the install script"
            rm -f "$temp_file"
            return 1
        fi
        
        # Create temporary .zshrc with updated function
        local temp_zshrc=$(mktemp)
        head -n $((start_line - 1)) ~/.zshrc > "$temp_zshrc"
        cat "$temp_file" >> "$temp_zshrc"
        tail -n +$((end_line + 1)) ~/.zshrc >> "$temp_zshrc"
        
        # Replace .zshrc
        mv "$temp_zshrc" ~/.zshrc
        rm -f "$temp_file"
        
        echo "✅ Successfully updated to version $latest_version"
        echo "Please restart your terminal or run: source ~/.zshrc"
        return 0
    fi
    
    # Normal usage: w <project> <worktree> [command...]
    local project="$1"
    local worktree="$2"
    
    if [[ -z "$project" || -z "$worktree" ]]; then
        echo "Usage: w <project> <worktree> [command...]"
        echo "       w --list"
        echo "       w --rm <project> <worktree>"
        echo "       w --cleanup"
        echo "       w --version"
        echo "       w --update"
        return 1
    fi
    
    shift 2
    local command=("$@")
    
    # Check if project exists
    if [[ ! -d "$projects_dir/$project" ]]; then
        echo "Project not found: $projects_dir/$project"
        return 1
    fi
    
    # Determine worktree path - check multiple locations
    local wt_path=""
    if [[ "$project" == "core" ]]; then
        # For core, check old location first
        if [[ -d "$projects_dir/core-wts/$worktree" ]]; then
            wt_path="$projects_dir/core-wts/$worktree"
        elif [[ -d "$worktrees_dir/$project/$worktree" ]]; then
            wt_path="$worktrees_dir/$project/$worktree"
        fi
    else
        # For other projects, check new location
        if [[ -d "$worktrees_dir/$project/$worktree" ]]; then
            wt_path="$worktrees_dir/$project/$worktree"
        fi
    fi
    
    # If worktree doesn't exist, create it
    if [[ -z "$wt_path" || ! -d "$wt_path" ]]; then
        echo "Creating new worktree: $worktree"
        
        # Ensure worktrees directory exists
        mkdir -p "$worktrees_dir/$project"
        
        # Determine branch name (use current username prefix)
        local branch_name="$USER/$worktree"
        
        # Create the worktree in new location
        wt_path="$worktrees_dir/$project/$worktree"
        (cd "$projects_dir/$project" && git worktree add "$wt_path" -b "$branch_name") || {
            echo "Failed to create worktree"
            return 1
        }
    fi
    
    # Execute based on number of arguments
    if [[ ${#command[@]} -eq 0 ]]; then
        # No command specified - just cd to the worktree
        cd "$wt_path"
    else
        # Command specified - run it in the worktree without cd'ing
        local old_pwd="$PWD"
        cd "$wt_path"
        eval "${command[@]}"
        local exit_code=$?
        cd "$old_pwd"
        return $exit_code
    fi
}

# Setup completion if not already done
if [[ ! -f ~/.zsh/completions/_w ]]; then
    mkdir -p ~/.zsh/completions
    cat > ~/.zsh/completions/_w << 'EOF'
#compdef w

_w() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
    
    local projects_dir="$HOME/projects"
    local worktrees_dir="$HOME/projects/worktrees"
    
    # Define the main arguments
    _arguments -C \
        '(--rm --cleanup --version --update)--list[List all worktrees]' \
        '(--list --cleanup --version --update)--rm[Remove a worktree]' \
        '(--list --rm --version --update)--cleanup[Clean up merged PR worktrees]' \
        '(--list --rm --cleanup --update)--version[Show version]' \
        '(--list --rm --cleanup --version)--update[Update to latest version]' \
        '1: :->project' \
        '2: :->worktree' \
        '3: :->command' \
        '*:: :->command_args' \
        && return 0
    
    case $state in
        project)
            if [[ "${words[1]}" == "--list" || "${words[1]}" == "--cleanup" || "${words[1]}" == "--version" || "${words[1]}" == "--update" ]]; then
                # No completion needed for these flags
                return 0
            fi
            
            # Get list of projects (directories in ~/projects that are git repos)
            local -a projects
            for dir in $projects_dir/*(N/); do
                if [[ -d "$dir/.git" ]]; then
                    projects+=(${dir:t})
                fi
            done
            
            _describe -t projects 'project' projects && return 0
            ;;
            
        worktree)
            local project="${words[2]}"
            
            if [[ -z "$project" ]]; then
                return 0
            fi
            
            local -a worktrees
            
            # For core project, check both old and new locations
            if [[ "$project" == "core" ]]; then
                # Check old location
                if [[ -d "$projects_dir/core-wts" ]]; then
                    for wt in $projects_dir/core-wts/*(N/); do
                        worktrees+=(${wt:t})
                    done
                fi
                # Check new location
                if [[ -d "$worktrees_dir/core" ]]; then
                    for wt in $worktrees_dir/core/*(N/); do
                        # Avoid duplicates
                        if [[ ! " ${worktrees[@]} " =~ " ${wt:t} " ]]; then
                            worktrees+=(${wt:t})
                        fi
                    done
                fi
            else
                # For other projects, check new location only
                if [[ -d "$worktrees_dir/$project" ]]; then
                    for wt in $worktrees_dir/$project/*(N/); do
                        worktrees+=(${wt:t})
                    done
                fi
            fi
            
            if (( ${#worktrees} > 0 )); then
                _describe -t worktrees 'existing worktree' worktrees
            else
                _message 'new worktree name'
            fi
            ;;
            
        command)
            # Suggest common commands when user has typed project and worktree
            local -a common_commands
            common_commands=(
                'claude:Start Claude Code session'
                'gst:Git status'
                'gaa:Git add all'
                'gcmsg:Git commit with message'
                'gp:Git push'
                'gco:Git checkout'
                'gd:Git diff'
                'gl:Git log'
                'npm:Run npm commands'
                'yarn:Run yarn commands'
                'make:Run make commands'
            )
            
            _describe -t commands 'command' common_commands
            
            # Also complete regular commands
            _command_names -e
            ;;
            
        command_args)
            # Let zsh handle completion for the specific command
            words=(${words[4,-1]})
            CURRENT=$((CURRENT - 3))
            _normal
            ;;
    esac
}

_w "$@"
EOF
    # Add completions to fpath if not already there
    fpath=(~/.zsh/completions $fpath)
fi

# Initialize completions
autoload -U compinit && compinit

