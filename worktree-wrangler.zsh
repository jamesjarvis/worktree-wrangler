#!/usr/bin/env zsh
# Worktree Wrangler - Multi-project Git worktree manager
# Version: 1.1.0

# Main worktree wrangler function
w() {
    local VERSION="1.1.0"
    local config_file="$HOME/.local/share/worktree-wrangler/config"
    
    # Load configuration
    local projects_dir="$HOME/development"  # Default
    if [[ -f "$config_file" ]]; then
        while IFS='=' read -r key value; do
            case "$key" in
                projects_dir) projects_dir="$value" ;;
            esac
        done < "$config_file"
    fi
    local worktrees_dir="$projects_dir/worktrees"
    
    # Handle special flags
    if [[ "$1" == "--list" ]]; then
        echo "=== All Worktrees ==="
        echo "Configuration:"
        echo "  Projects: $projects_dir"
        echo "  Worktrees: $worktrees_dir"
        echo ""
        
        # Check if projects directory exists
        if [[ ! -d "$projects_dir" ]]; then
            echo "❌ Projects directory not found: $projects_dir"
            echo ""
            echo "💡 To fix this, set your projects directory:"
            echo "   w --config projects ~/your/projects/directory"
            return 1
        fi
        
        local found_any=false
        
        # Check new location
        if [[ -d "$worktrees_dir" ]]; then
            for project in $worktrees_dir/*(/N); do
                project_name=$(basename "$project")
                echo "\\n[$project_name]"
                local found_worktrees=false
                for wt in $project/*(/N); do
                    echo "  • $(basename "$wt")"
                    found_worktrees=true
                    found_any=true
                done
                if [[ "$found_worktrees" == "false" ]]; then
                    echo "  (no worktrees)"
                fi
            done
        fi
        
        # Also check old core-wts location
        if [[ -d "$projects_dir/core-wts" ]]; then
            echo "\\n[core] (legacy location)"
            for wt in $projects_dir/core-wts/*(/N); do
                echo "  • $(basename "$wt")"
                found_any=true
            done
        fi
        
        if [[ "$found_any" == "false" ]]; then
            echo "\\nNo worktrees found."
            echo ""
            echo "💡 To create your first worktree:"
            echo "   w <project> <worktree-name>"
            echo ""
            echo "💡 Available projects in $projects_dir:"
            for dir in "$projects_dir"/*(/N); do
                if [[ -d "$dir/.git" ]]; then
                    echo "   • $(basename "$dir")"
                fi
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
        
        # Determine installation location
        local install_dir="$HOME/.local/share/worktree-wrangler"
        local script_file="$install_dir/worktree-wrangler.zsh"
        
        # Download latest version
        echo "Downloading latest version..."
        local temp_file=$(mktemp)
        if ! curl -sSL "https://raw.githubusercontent.com/jamesjarvis/worktree-wrangler/master/worktree-wrangler.zsh" -o "$temp_file"; then
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
        
        # Create backup of current script
        if [[ -f "$script_file" ]]; then
            echo "Creating backup of current script..."
            cp "$script_file" "$script_file.backup.$(date +%Y%m%d_%H%M%S)"
        fi
        
        # Replace script file
        mkdir -p "$install_dir"
        mv "$temp_file" "$script_file"
        
        echo "✅ Successfully updated to version $latest_version"
        echo "Please restart your terminal or run: source ~/.zshrc"
        return 0
    elif [[ "$1" == "--config" ]]; then
        shift
        local action="$1"
        
        if [[ -z "$action" ]]; then
            echo "Usage: w --config <action>"
            echo "Actions:"
            echo "  projects <path>    Set projects directory"
            echo "  list              Show current configuration"
            echo "  reset             Reset to defaults"
            return 1
        fi
        
        case "$action" in
            projects)
                local new_path="$2"
                if [[ -z "$new_path" ]]; then
                    echo "Usage: w --config projects <path>"
                    return 1
                fi
                
                # Expand tilde and resolve path
                new_path="${new_path/#\~/$HOME}"
                new_path=$(realpath "$new_path" 2>/dev/null || echo "$new_path")
                
                if [[ ! -d "$new_path" ]]; then
                    echo "Error: Directory does not exist: $new_path"
                    return 1
                fi
                
                # Create config directory if it doesn't exist
                mkdir -p "$(dirname "$config_file")"
                
                # Write configuration
                echo "projects_dir=$new_path" > "$config_file"
                echo "✅ Set projects directory to: $new_path"
                echo "Worktrees will be created in: $new_path/worktrees"
                ;;
            list)
                echo "=== Configuration ==="
                echo "Projects directory: $projects_dir"
                echo "Worktrees directory: $worktrees_dir"
                echo "Config file: $config_file"
                if [[ -f "$config_file" ]]; then
                    echo "✅ Config file exists"
                else
                    echo "⚠️  Using default configuration (no config file)"
                fi
                ;;
            reset)
                if [[ -f "$config_file" ]]; then
                    rm "$config_file"
                    echo "✅ Configuration reset to defaults"
                    echo "Projects directory: $HOME/development"
                else
                    echo "⚠️  No configuration file to reset"
                fi
                ;;
            *)
                echo "Unknown action: $action"
                echo "Available actions: projects, list, reset"
                return 1
                ;;
        esac
        return 0
    fi
    
    # Normal usage: w <project> <worktree> [command...]
    local project="$1"
    local worktree="$2"
    shift 2
    local command=("$@")
    
    if [[ -z "$project" || -z "$worktree" ]]; then
        echo "Usage: w <project> <worktree> [command...]"
        echo "       w --list"
        echo "       w --rm <project> <worktree>"
        echo "       w --cleanup"
        echo "       w --version"
        echo "       w --update"
        echo "       w --config <action>"
        return 1
    fi
    
    # Check if projects directory exists
    if [[ ! -d "$projects_dir" ]]; then
        echo "❌ Projects directory not found: $projects_dir"
        echo ""
        echo "💡 To fix this, set your projects directory:"
        echo "   w --config projects ~/your/projects/directory"
        echo ""
        echo "💡 Or check current configuration:"
        echo "   w --config list"
        return 1
    fi
    
    # Check if project exists
    if [[ ! -d "$projects_dir/$project" ]]; then
        echo "Project not found: $projects_dir/$project"
        echo ""
        echo "Available projects in $projects_dir:"
        for dir in "$projects_dir"/*(/N); do
            if [[ -d "$dir/.git" ]]; then
                echo "  • $(basename "$dir")"
            fi
        done
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